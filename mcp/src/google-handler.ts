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

// The Worker URL is only an API; people who open it in a browser land on the website.
app.get("/", (c) => c.redirect(c.env.HOMEPAGE_URL, 302));
app.get("/privacy", (c) => c.redirect(new URL("privacy.html", c.env.HOMEPAGE_URL).href, 302));

app.get("/authorize", async (c) => {
	const oauthReqInfo = await c.env.OAUTH_PROVIDER.parseAuthRequest(c.req.raw);
	const { clientId } = oauthReqInfo;
	if (!clientId) {
		return c.text("Invalid request", 400);
	}

	// Check if client is already approved
	if (await isClientApproved(c.req.raw, clientId, c.env.COOKIE_ENCRYPTION_KEY)) {
		// Skip approval dialog but still create secure state and bind to session
		const { stateToken } = await createOAuthState(oauthReqInfo, c.env.OAUTH_KV);
		const { setCookie: sessionBindingCookie } = await bindStateToSession(stateToken);
		return redirectToGoogle(c.req.raw, c.env, stateToken, {
			"Set-Cookie": sessionBindingCookie,
		});
	}

	// Generate CSRF protection for the approval form
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
		// Read form data once
		const formData = await c.req.raw.formData();

		// Validate CSRF token
		validateCSRFToken(formData, c.req.raw);

		// Extract state from form data
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

		// Add client to approved list
		const approvedClientCookie = await addApprovedClient(
			c.req.raw,
			state.oauthReqInfo.clientId,
			c.env.COOKIE_ENCRYPTION_KEY,
		);

		// Create OAuth state and bind it to this user's session
		const { stateToken } = await createOAuthState(state.oauthReqInfo, c.env.OAUTH_KV);
		const { setCookie: sessionBindingCookie } = await bindStateToSession(stateToken);

		// Set both cookies: approved client list + session binding
		const headers = new Headers();
		headers.append("Set-Cookie", approvedClientCookie);
		headers.append("Set-Cookie", sessionBindingCookie);

		return redirectToGoogle(c.req.raw, c.env, stateToken, Object.fromEntries(headers));
	} catch (error: any) {
		console.error("POST /authorize error:", error);
		if (error instanceof OAuthError) {
			return error.toResponse();
		}
		// Unexpected non-OAuth error
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

/**
 * OAuth Callback Endpoint
 *
 * Handles the callback from Google after the user signs in. It exchanges the
 * code for Google tokens, checks the account is on ALLOWED_EMAILS, stores the
 * tokens in the grant's encrypted props, and redirects back to the MCP client.
 *
 * SECURITY: This endpoint validates that the state parameter from Google
 * matches both:
 * 1. A valid state token in KV (proves it was created by our server)
 * 2. The __Host-CONSENTED_STATE cookie (proves THIS browser consented to it)
 *
 * This prevents CSRF attacks where an attacker's state token is injected
 * into a victim's OAuth flow.
 */
app.get("/callback", async (c) => {
	// Validate OAuth state with session binding
	// This checks both KV storage AND the session cookie
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
		// Unexpected non-OAuth error
		return c.text("Internal server error", 500);
	}

	if (!oauthReqInfo.clientId) {
		return c.text("Invalid OAuth request data", 400);
	}

	if (c.req.query("error")) {
		return htmlPage("Sign-in cancelled", "Google sign-in didn't finish. Close this tab and try connecting again.");
	}

	// Exchange the code for Google tokens
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

	// Fetch the user info from Google
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

	// Invite-only: the Worker URL is public, so reject anyone not on the list,
	// store nothing for them, and remove the app from their Google account.
	if (!email || !email_verified || !isEmailAllowed(c.env.ALLOWED_EMAILS, email)) {
		c.executionCtx.waitUntil(revokeGoogleToken(tokens.refresh_token ?? tokens.access_token));
		return htmlPage(
			"Invite only",
			`This Tasks connector is invite-only, and ${email ?? "this Google account"} isn't on the list. Nothing was saved.`,
			403,
		);
	}

	// Google lets people untick permissions on the consent screen
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

	// Return back to the MCP client a new token
	const { redirectTo } = await c.env.OAUTH_PROVIDER.completeAuthorization({
		metadata: {
			label: email,
		},
		props,
		request: oauthReqInfo,
		scope: oauthReqInfo.scope,
		userId: sub,
	});

	// Clear the session binding cookie (one-time use) by creating response with headers
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
