import { describe, expect, it } from "vitest";
import { decodeBase64, encodeBase64 } from "../src/workers-oauth-utils";

describe("encodeBase64 and decodeBase64", () => {
	it("encodes and decodes ASCII strings correctly", () => {
		const original = '{"client_id":"app_123","scope":"openid email"}';
		const encoded = encodeBase64(original);
		const decoded = decodeBase64(encoded);
		expect(decoded).toBe(original);
	});

	it("handles unicode characters safely without throwing InvalidCharacterError", () => {
		const unicodeString = '{"clientName":"Mëp Task-App 🚀","redirectUri":"https://example.com/oauth?user=Bình"}';
		const encoded = encodeBase64(unicodeString);
		expect(typeof encoded).toBe("string");
		const decoded = decodeBase64(encoded);
		expect(decoded).toBe(unicodeString);
	});
});
