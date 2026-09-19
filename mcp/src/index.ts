import OAuthProvider, { OAuthError } from "@cloudflare/workers-oauth-provider";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { McpAgent } from "agents/mcp";
import { env } from "cloudflare:workers";
import { GoogleHandler } from "./google-handler";
import { GoogleTasksClient } from "./google-tasks";
import { registerTools } from "./tools";
import { GoogleAuthRevokedError, isEmailAllowed, type Props, refreshGoogleToken } from "./utils";

const REFRESH_MARGIN_MS = 2 * 60 * 1000;

export class TasksMCP extends McpAgent<Env, Record<string, never>, Props> {
	server = new McpServer({ name: "Tasks", version: "0.1.0" });

	#token?: { accessToken: string; expiresAt: number };
	#refreshing?: Promise<string>;

	async init() {
		registerTools(this.server, {
			client: new GoogleTasksClient((forceRefresh) => this.googleAccessToken(forceRefresh)),
			defaultTimeZone: this.env.TIMEZONE,
			assertAllowed: () => {
				if (!isEmailAllowed(this.env.ALLOWED_EMAILS, this.props?.email)) {
					throw new Error("This Google account isn't allowed to use this Tasks connector.");
				}
			},
		});
	}

	private async googleAccessToken(forceRefresh: boolean): Promise<string> {
		const props = this.props;
		if (!props?.googleRefreshToken) throw new Error("Not signed in to Google. Reconnect the Tasks connector.");

		const current = this.#token ?? { accessToken: props.googleAccessToken, expiresAt: props.googleExpiresAt };
		if (!forceRefresh && current.expiresAt - Date.now() > REFRESH_MARGIN_MS) return current.accessToken;

		this.#refreshing ??= (async () => {
			try {
				const fresh = await refreshGoogleToken({
					clientId: this.env.GOOGLE_CLIENT_ID,
					clientSecret: this.env.GOOGLE_CLIENT_SECRET,
					refreshToken: props.googleRefreshToken,
				});
				this.#token = { accessToken: fresh.access_token, expiresAt: Date.now() + fresh.expires_in * 1000 };
				return fresh.access_token;
			} catch (error) {
				if (error instanceof GoogleAuthRevokedError) {
					throw new Error("Google access was removed. Disconnect and reconnect the Tasks connector.");
				}
				throw error;
			} finally {
				this.#refreshing = undefined;
			}
		})();
		return this.#refreshing;
	}
}

export default new OAuthProvider({
	apiHandler: TasksMCP.serve("/mcp"),
	apiRoute: "/mcp",
	authorizeEndpoint: "/authorize",
	clientRegistrationEndpoint: "/register",
	defaultHandler: GoogleHandler as any,
	tokenEndpoint: "/token",
	refreshTokenTTL: undefined,
	clientRegistrationTTL: undefined,
	tokenExchangeCallback: async ({ grantType, props }) => {
		if (grantType !== "refresh_token") return;
		const current = props as Props;
		if (!isEmailAllowed(env.ALLOWED_EMAILS, current.email)) {
			throw new OAuthError("invalid_grant", { description: "This Google account isn't allowed to use this connector" });
		}
		try {
			const fresh = await refreshGoogleToken({
				clientId: env.GOOGLE_CLIENT_ID,
				clientSecret: env.GOOGLE_CLIENT_SECRET,
				refreshToken: current.googleRefreshToken,
			});
			const newProps: Props = {
				...current,
				googleAccessToken: fresh.access_token,
				googleExpiresAt: Date.now() + fresh.expires_in * 1000,
			};
			return { newProps };
		} catch (error) {
			if (error instanceof GoogleAuthRevokedError) {
				throw new OAuthError("invalid_grant", { description: "Google access was revoked" });
			}
			console.error("Google token refresh failed:", error);
			throw new OAuthError("temporarily_unavailable", {
				description: "Couldn't reach Google. Try again shortly.",
				statusCode: 503,
				headers: { "Retry-After": "30" },
			});
		}
	},
});
