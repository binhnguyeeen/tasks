import { afterEach, describe, expect, it, vi } from "vitest";
import { GoogleTasksClient } from "../src/google-tasks";

afterEach(() => vi.unstubAllGlobals());

describe("GoogleTasksClient.moveTask", () => {
	it("posts to tasks.move with only the options given", async () => {
		const requests: { url: string; method?: string }[] = [];
		vi.stubGlobal("fetch", async (url: URL, init: RequestInit) => {
			requests.push({ url: url.toString(), method: init.method });
			return Response.json({ id: "t 1" });
		});
		const client = new GoogleTasksClient(async () => "token");
		await client.moveTask("list/a", "t 1", { destinationList: "b", parent: "p" });
		expect(requests).toEqual([
			{
				url: "https://tasks.googleapis.com/tasks/v1/lists/list%2Fa/tasks/t%201/move?destinationTasklist=b&parent=p",
				method: "POST",
			},
		]);
	});
});
