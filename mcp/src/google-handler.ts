import type { AuthRequest, OAuthHelpers } from "@cloudflare/workers-oauth-provider";
import { Hono } from "hono";
import {
	exchangeCodeForTokens,
	getUpstreamAuthorizeUrl,
	GOOGLE_USERINFO_URL,
	htmlPage,
	isEmailAllowed,
	type Props,
	revokeGoogleToken,
	TASKS_SCOPE,
} from "./utils";
import {
	addApprovedClient,
	bindStateToSession,
	createOAuthState,
	generateCSRFProtection,
	isClientApproved,
	OAuthError,
	renderApprovalDialog,
	validateCSRFToken,
	validateOAuthState,
} from "./workers-oauth-utils";

const app = new Hono<{ Bindings: Env & { OAUTH_PROVIDER: OAuthHelpers } }>();

app.get("/", (c) => c.redirect(c.env.HOMEPAGE_URL, 302));
app.get("/privacy", (c) => c.redirect(new URL("privacy.html", c.env.HOMEPAGE_URL).href, 302));

app.get("/authorize", async (c) => {
	const oauthReqInfo = await c.env.OAUTH_PROVIDER.parseAuthRequest(c.req.raw);
	const { clientId } = oauthReqInfo;
	if (!clientId) {
		return c.text("Invalid request", 400);
	}

	if (await isClientApproved(c.req.raw, clientId, c.env.COOKIE_ENCRYPTION_KEY)) {
		const { stateToken } = await createOAuthState(oauthReqInfo, c.env.OAUTH_KV);
		const { setCookie: sessionBindingCookie } = await bindStateToSession(stateToken);
		return redirectToGoogle(c.req.raw, c.env, stateToken, {
			"Set-Cookie": sessionBindingCookie,
		});
	}

	const { token: csrfToken, setCookie } = generateCSRFProtection();

	return renderApprovalDialog(c.req.raw, {
		client: await c.env.OAUTH_PROVIDER.lookupClient(clientId),
		csrfToken,
		server: {
			description:
				"Tasks lets this app read your Google Tasks, add tasks, edit them and tick them off. It can't delete anything. Access is invite-only.",
			logo: new URL("icon.png", c.env.HOMEPAGE_URL).href,
			name: "Tasks",
		},
		setCookie,
		state: { oauthReqInfo },
	});
});

app.post("/authorize", async (c) => {
	try {
		const formData = await c.req.raw.formData();

		validateCSRFToken(formData, c.req.raw);

		const encodedState = formData.get("state");
		if (!encodedState || typeof encodedState !== "string") {
			return c.text("Missing state in form data", 400);
		}

		let state: { oauthReqInfo?: AuthRequest };
		try {
			state = JSON.parse(atob(encodedState));
		} catch (_e) {
			return c.text("Invalid state data", 400);
		}

		if (!state.oauthReqInfo || !state.oauthReqInfo.clientId) {
			return c.text("Invalid request", 400);
		}

		const approvedClientCookie = await addApprovedClient(
			c.req.raw,
			state.oauthReqInfo.clientId,
			c.env.COOKIE_ENCRYPTION_KEY,
		);

		const { stateToken } = await createOAuthState(state.oauthReqInfo, c.env.OAUTH_KV);
		const { setCookie: sessionBindingCookie } = await bindStateToSession(stateToken);

		const headers = new Headers();
		headers.append("Set-Cookie", approvedClientCookie);
		headers.append("Set-Cookie", sessionBindingCookie);

		return redirectToGoogle(c.req.raw, c.env, stateToken, Object.fromEntries(headers));
	} catch (error: any) {
		console.error("POST /authorize error:", error);
		if (error instanceof OAuthError) {
			return error.toResponse();
		}
		return c.text(`Internal server error: ${error.message}`, 500);
	}
});

async function redirectToGoogle(
	request: Request,
	env: Env,
	stateToken: string,
	headers: Record<string, string> = {},
) {
	return new Response(null, {
		headers: {
			...headers,
			location: getUpstreamAuthorizeUrl({
				clientId: env.GOOGLE_CLIENT_ID,
				redirectUri: new URL("/callback", request.url).href,
				state: stateToken,
			}),
		},
		status: 302,
	});
}

app.get("/callback", async (c) => {
	let oauthReqInfo: AuthRequest;
	let clearSessionCookie: string;

	try {
		const result = await validateOAuthState(c.req.raw, c.env.OAUTH_KV);
		oauthReqInfo = result.oauthReqInfo;
		clearSessionCookie = result.clearCookie;
	} catch (error: any) {
		if (error instanceof OAuthError) {
			return error.toResponse();
		}
		return c.text("Internal server error", 500);
	}

	if (!oauthReqInfo.clientId) {
		return c.text("Invalid OAuth request data", 400);
	}

	if (c.req.query("error")) {
		return htmlPage("Sign-in cancelled", "Google sign-in didn't finish. Close this tab and try connecting again.");
	}

	const code = c.req.query("code");
	if (!code) {
		return c.text("Missing code", 400);
	}

	let tokens;
	try {
		tokens = await exchangeCodeForTokens({
			clientId: c.env.GOOGLE_CLIENT_ID,
			clientSecret: c.env.GOOGLE_CLIENT_SECRET,
			code,
			redirectUri: new URL("/callback", c.req.url).href,
		});
	} catch (error) {
		console.error("Google code exchange failed:", error);
		return htmlPage("Couldn't sign in", "Google didn't accept the sign-in. Close this tab and try again.", 502);
	}

	const userResponse = await fetch(GOOGLE_USERINFO_URL, {
		headers: { Authorization: `Bearer ${tokens.access_token}` },
	});
	if (!userResponse.ok) {
		console.error("Google userinfo failed:", userResponse.status, await userResponse.text());
		return htmlPage("Couldn't sign in", "Couldn't read your Google account. Close this tab and try again.", 502);
	}
	const { sub, email, email_verified } = (await userResponse.json()) as {
		sub: string;
		email?: string;
		email_verified?: boolean;
	};

	if (!email || !email_verified || !isEmailAllowed(c.env.ALLOWED_EMAILS, email)) {
		c.executionCtx.waitUntil(revokeGoogleToken(tokens.refresh_token ?? tokens.access_token));
		return htmlPage(
			"Invite only",
			`This Tasks connector is invite-only, and ${email ?? "this Google account"} isn't on the list. Nothing was saved.`,
			403,
		);
	}

	const grantedScopes = (tokens.scope ?? "").split(" ");
	if (!grantedScopes.includes(TASKS_SCOPE)) {
		c.executionCtx.waitUntil(revokeGoogleToken(tokens.refresh_token ?? tokens.access_token));
		return htmlPage(
			"Google Tasks access needed",
			"Tasks needs permission to see and edit your Google Tasks. Try connecting again and leave that box ticked.",
		);
	}

	if (!tokens.refresh_token) {
		return htmlPage("Couldn't sign in", "Google didn't grant lasting access. Close this tab and try connecting again.", 502);
	}

	const props: Props = {
		email,
		googleAccessToken: tokens.access_token,
		googleExpiresAt: Date.now() + tokens.expires_in * 1000,
		googleRefreshToken: tokens.refresh_token,
		userId: sub,
	};

	const { redirectTo } = await c.env.OAUTH_PROVIDER.completeAuthorization({
		metadata: {
			label: email,
		},
		props,
		request: oauthReqInfo,
		scope: oauthReqInfo.scope,
		userId: sub,
	});

	const headers = new Headers({ Location: redirectTo });
	if (clearSessionCookie) {
		headers.set("Set-Cookie", clearSessionCookie);
	}

	return new Response(null, {
		status: 302,
		headers,
	});
});

export { app as GoogleHandler };
