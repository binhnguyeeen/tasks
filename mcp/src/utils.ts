export const GOOGLE_AUTHORIZE_URL = "https://accounts.google.com/o/oauth2/v2/auth";
export const GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token";
export const GOOGLE_USERINFO_URL = "https://openidconnect.googleapis.com/v1/userinfo";
export const GOOGLE_REVOKE_URL = "https://oauth2.googleapis.com/revoke";
export const TASKS_SCOPE = "https://www.googleapis.com/auth/tasks";

/**
 * Context from the auth process, encrypted & stored with the grant by the
 * OAuth provider and handed to TasksMCP as this.props.
 */
export type Props = {
	/** Google account ID (`sub`) */
	userId: string;
	email: string;
	googleRefreshToken: string;
	googleAccessToken: string;
	/** Epoch milliseconds when googleAccessToken expires */
	googleExpiresAt: number;
};

export function getUpstreamAuthorizeUrl({
	clientId,
	redirectUri,
	state,
}: {
	clientId: string;
	redirectUri: string;
	state: string;
}) {
	const upstream = new URL(GOOGLE_AUTHORIZE_URL);
	upstream.searchParams.set("client_id", clientId);
	upstream.searchParams.set("redirect_uri", redirectUri);
	upstream.searchParams.set("scope", `openid email ${TASKS_SCOPE}`);
	upstream.searchParams.set("response_type", "code");
	upstream.searchParams.set("state", state);
	// Google only returns a refresh token for offline access, and only on the
	// consent screen. Without it we'd lose access after an hour.
	upstream.searchParams.set("access_type", "offline");
	upstream.searchParams.set("prompt", "consent");
	return upstream.href;
}

export interface GoogleTokenResponse {
	access_token: string;
	expires_in: number;
	refresh_token?: string;
	scope?: string;
	token_type: string;
	id_token?: string;
}

/** Thrown when Google says the refresh token is no longer valid (revoked or expired). */
export class GoogleAuthRevokedError extends Error {}

async function postToken(params: Record<string, string>): Promise<GoogleTokenResponse> {
	const resp = await fetch(GOOGLE_TOKEN_URL, {
		body: new URLSearchParams(params).toString(),
		headers: { "Content-Type": "application/x-www-form-urlencoded" },
		method: "POST",
	});
	if (!resp.ok) {
		const text = await resp.text();
		if (resp.status === 400 && text.includes("invalid_grant")) {
			throw new GoogleAuthRevokedError("Google access was revoked or expired");
		}
		throw new Error(`Google token endpoint returned ${resp.status}: ${text.slice(0, 300)}`);
	}
	return (await resp.json()) as GoogleTokenResponse;
}

export function exchangeCodeForTokens(opts: {
	clientId: string;
	clientSecret: string;
	code: string;
	redirectUri: string;
}): Promise<GoogleTokenResponse> {
	return postToken({
		client_id: opts.clientId,
		client_secret: opts.clientSecret,
		code: opts.code,
		grant_type: "authorization_code",
		redirect_uri: opts.redirectUri,
	});
}

export function refreshGoogleToken(opts: {
	clientId: string;
	clientSecret: string;
	refreshToken: string;
}): Promise<GoogleTokenResponse> {
	return postToken({
		client_id: opts.clientId,
		client_secret: opts.clientSecret,
		grant_type: "refresh_token",
		refresh_token: opts.refreshToken,
	});
}

/** Best effort: removes this app from the user's Google account permissions. */
export async function revokeGoogleToken(token: string): Promise<void> {
	await fetch(GOOGLE_REVOKE_URL, {
		body: new URLSearchParams({ token }).toString(),
		headers: { "Content-Type": "application/x-www-form-urlencoded" },
		method: "POST",
	}).catch(() => undefined);
}

/** Case-insensitive check against the comma-separated ALLOWED_EMAILS secret. Fails closed. */
export function isEmailAllowed(allowedEmails: string | undefined, email: string | undefined): boolean {
	if (!allowedEmails || !email) return false;
	const wanted = email.trim().toLowerCase();
	return allowedEmails
		.split(",")
		.map((e) => e.trim().toLowerCase())
		.filter(Boolean)
		.includes(wanted);
}

/** A small branded HTML page for errors shown in the browser during sign-in. */
export function htmlPage(title: string, message: string, status = 400): Response {
	const esc = (s: string) =>
		s.replace(/[&<>"']/g, (ch) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[ch]!);
	const body = `<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(title)} · Tasks</title>
<style>
:root{--bg:#fbfbfd;--card:#fff;--text:#1d1d1f;--muted:#6e6e73;--border:#e5e5ea}
@media (prefers-color-scheme:dark){:root{--bg:#111113;--card:#1c1c1e;--text:#f5f5f7;--muted:#a1a1a6;--border:#2c2c2e}}
body{margin:0;min-height:100vh;display:grid;place-items:center;background:var(--bg);color:var(--text);font:17px/1.55 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;padding:16px;box-sizing:border-box}
main{max-width:440px;background:var(--card);border:1px solid var(--border);border-radius:18px;padding:32px;text-align:center}
img{width:64px;height:64px}h1{font-size:22px;margin:16px 0 8px}p{color:var(--muted);margin:0}
</style></head>
<body><main><img src="https://binhnguyeeen.github.io/tasks/icon.png" alt=""><h1>${esc(title)}</h1><p>${esc(message)}</p></main></body></html>`;
	return new Response(body, { status, headers: { "Content-Type": "text/html; charset=utf-8" } });
}
