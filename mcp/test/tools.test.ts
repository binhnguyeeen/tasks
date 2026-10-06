import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import type { CallToolResult } from "@modelcontextprotocol/sdk/types.js";
import { describe, expect, it } from "vitest";
import type { GoogleTasksClient } from "../src/google-tasks";
import type { GoogleTask } from "../src/todos";
import { registerTools } from "../src/tools";

type Handler = (args: Record<string, unknown>) => Promise<CallToolResult>;

function setUp(client: Partial<GoogleTasksClient>) {
	const handlers = new Map<string, Handler>();
	const server = {
		registerTool: (name: string, _config: unknown, handler: Handler) => handlers.set(name, handler),
	} as unknown as McpServer;
	registerTools(server, {
		client: client as GoogleTasksClient,
		defaultTimeZone: "UTC",
		assertAllowed: () => {},
	});
	return async (name: string, args: Record<string, unknown>) => {
		const result = await handlers.get(name)!(args);
		const text = (result.content[0] as { text: string }).text;
		return { isError: result.isError ?? false, body: result.isError ? text : JSON.parse(text) };
	};
}

describe("move_task", () => {
	const moved: GoogleTask = { id: "t1", title: "Book hotel", status: "needsAction", parent: "p1" };

	it("moves to another list under a parent and reports the new list", async () => {
		const calls: unknown[] = [];
		const call = setUp({
			moveTask: async (...args) => {
				calls.push(args);
				return moved;
			},
		});
		const out = await call("move_task", { list_id: "a", task_id: "t1", destination_list_id: "b", parent: "p1" });
		expect(calls).toEqual([["a", "t1", { destinationList: "b", parent: "p1", previous: undefined }]]);
		expect(out.body.moved).toMatchObject({ id: "t1", list_id: "b", parent_id: "p1" });
	});

	it("stays in the same list when the destination is the current list, and treats blanks as omitted", async () => {
		const calls: unknown[] = [];
		const call = setUp({
			moveTask: async (...args) => {
				calls.push(args);
				return { ...moved, parent: undefined };
			},
		});
		const out = await call("move_task", { list_id: "a", task_id: "t1", destination_list_id: "a", parent: " ", previous: "" });
		expect(calls).toEqual([["a", "t1", { destinationList: undefined, parent: undefined, previous: undefined }]]);
		expect(out.body.moved.list_id).toBe("a");
	});

	it("refuses to nest a task under itself", async () => {
		const call = setUp({ moveTask: async () => moved });
		const out = await call("move_task", { list_id: "a", task_id: "t1", parent: "t1" });
		expect(out).toEqual({ isError: true, body: "A task can't be its own parent." });
	});
});

describe("search_tasks", () => {
	it("searches every list with completed tasks only when asked", async () => {
		const seen: unknown[] = [];
		const call = setUp({
			listTaskLists: async () => [
				{ id: "a", title: "My Tasks" },
				{ id: "b", title: "Work" },
			],
			listTasks: async (listId, opts) => {
				seen.push([listId, opts]);
				return listId === "b" ? [{ id: "x", title: "Dentist appointment", status: "needsAction" }] : [];
			},
		});
		const out = await call("search_tasks", { query: "dentist", include_completed: false, limit: 25 });
		expect(seen).toEqual([
			["a", { showCompleted: false }],
			["b", { showCompleted: false }],
		]);
		expect(out.body).toMatchObject({ query: "dentist", count: 1, tasks: [{ id: "x", list_title: "Work" }] });
	});
});
