import { describe, expect, it } from "vitest";
import { redirectWithCookies } from "../src/utils";

describe("redirectWithCookies", () => {
	it("keeps every cookie instead of only the last one", () => {
		const response = redirectWithCookies("https://accounts.google.com/o/oauth2/v2/auth", [
			"__Host-APPROVED_CLIENTS=abc; Path=/",
			"__Host-CONSENTED_STATE=def; Path=/",
		]);
		expect(response.status).toBe(302);
		expect(response.headers.get("location")).toBe("https://accounts.google.com/o/oauth2/v2/auth");
		expect(response.headers.getSetCookie()).toEqual([
			"__Host-APPROVED_CLIENTS=abc; Path=/",
			"__Host-CONSENTED_STATE=def; Path=/",
		]);
	});

	it("sends no cookies when there are none", () => {
		expect(redirectWithCookies("https://example.com").headers.getSetCookie()).toEqual([]);
	});
});
