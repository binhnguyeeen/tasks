import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import type { CallToolResult } from "@modelcontextprotocol/sdk/types.js";
import { z } from "zod";
import { assertTimeZone, isValidDate, todayIn, toGoogleDue } from "./dates";
import type { GoogleTasksClient } from "./google-tasks";
import { buildTodos, countTodos, dueBounds, type TodoGroup, toTodo, type When } from "./todos";

export interface ToolDeps {
	client: GoogleTasksClient;
	defaultTimeZone: string;
	assertAllowed: () => void;
}

const dateField = z
	.string()
	.refine(isValidDate, "Use a real date as YYYY-MM-DD")
	.describe("Due date as YYYY-MM-DD. Google Tasks has due dates only, no times.");

const timeZoneField = z
	.string()
	.optional()
	.describe(
		"The user's IANA time zone, e.g. \"Asia/Ho_Chi_Minh\" or \"America/New_York\". Decides what counts as today. Pass it when you know it.",
	);

function json(data: unknown): CallToolResult {
	return { content: [{ type: "text", text: JSON.stringify(data) }] };
}

function fail(error: unknown): CallToolResult {
	const message = error instanceof Error ? error.message : String(error);
	return { isError: true, content: [{ type: "text", text: message }] };
}

export function registerTools(server: McpServer, deps: ToolDeps) {
	const { client } = deps;

	const run =
		<A>(body: (args: A) => Promise<CallToolResult>) =>
		async (args: A): Promise<CallToolResult> => {
			try {
				deps.assertAllowed();
				return await body(args);
			} catch (error) {
				return fail(error);
			}
		};

	const today = (timeZone?: string) => {
		const tz = timeZone || deps.defaultTimeZone;
		assertTimeZone(tz);
		return todayIn(tz);
	};

	server.registerTool(
		"list_task_lists",
		{
			title: "List Google Tasks lists",
			description: "Lists the user's Google Tasks lists (id and title). Use the id as list_id in other tools.",
			inputSchema: {},
			annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: false },
		},
		run(async () => {
			const lists = await client.listTaskLists();
			return json(lists.map((l) => ({ id: l.id, title: l.title ?? "(untitled)" })));
		}),
	);

	server.registerTool(
		"get_todos",
		{
			title: "Get Google Tasks todos",
			description: [
				"Gets the user's Google Tasks, grouped by list, with subtasks nested under their parent.",
				"when: today_and_overdue (default) = due today or earlier; next_7_days = overdue plus due within the next 7 days;",
				"no_date = tasks without a due date; all = everything.",
				"Each task has id, list_id, title, notes, due (YYYY-MM-DD), status, overdue and webViewLink.",
				"Use query to find a task by text before ticking it off or editing it.",
			].join(" "),
			inputSchema: {
				when: z.enum(["today_and_overdue", "next_7_days", "no_date", "all"]).default("today_and_overdue"),
				list_id: z.string().optional().describe("Only this list. Omit for all lists."),
				include_completed: z.boolean().default(false).describe("Also return completed tasks."),
				query: z.string().optional().describe("Only tasks whose title or notes contain this text (case-insensitive)."),
				timezone: timeZoneField,
			},
			annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: false },
		},
		run(async ({ when, list_id, include_completed, query, timezone }) => {
			const day = today(timezone);
			const allLists = await client.listTaskLists();
			const lists = list_id ? allLists.filter((l) => l.id === list_id) : allLists;
			if (list_id && lists.length === 0) throw new Error(`No task list with id "${list_id}". Call list_task_lists.`);

			const bounds = dueBounds(when as When, day);
			const groups: TodoGroup[] = await Promise.all(
				lists.map(async (list) => {
					const tasks = await client.listTasks(list.id, { showCompleted: include_completed, ...bounds });
					return {
						list_id: list.id,
						list_title: list.title ?? "(untitled)",
						tasks: buildTodos(tasks, list.id, when as When, day, include_completed, query),
					};
				}),
			);
			const nonEmpty = groups.filter((g) => g.tasks.length > 0);
			const count = nonEmpty.reduce((n, g) => n + countTodos(g.tasks), 0);
			return json({ today: day, when, count, lists: nonEmpty });
		}),
	);

	server.registerTool(
		"add_task",
		{
			title: "Add a Google Tasks task",
			description:
				"Adds a task to Google Tasks. Defaults to the user's default list (My Tasks). Pass parent to add it as a subtask.",
			inputSchema: {
				title: z.string().trim().min(1),
				due: dateField.optional(),
				notes: z.string().optional(),
				list_id: z.string().default("@default").describe('List id from list_task_lists. Defaults to "@default".'),
				parent: z.string().optional().describe("Task id of the parent, to create a subtask in the same list."),
				timezone: timeZoneField,
			},
			annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: false, openWorldHint: false },
		},
		run(async ({ title, due, notes, list_id, parent, timezone }) => {
			const task = await client.insertTask(
				list_id,
				{ title, notes, due: due ? toGoogleDue(due) : undefined },
				parent,
			);
			return json({ created: toTodo(task, list_id, today(timezone)) });
		}),
	);

	server.registerTool(
		"set_task_done",
		{
			title: "Tick off or reopen a task",
			description: "Marks a Google Tasks task as done (done=true) or not done (done=false).",
			inputSchema: {
				list_id: z.string(),
				task_id: z.string(),
				done: z.boolean(),
				timezone: timeZoneField,
			},
			annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false },
		},
		run(async ({ list_id, task_id, done, timezone }) => {
			const patch = done ? { status: "completed" } : { status: "needsAction", completed: null };
			const task = await client.patchTask(list_id, task_id, patch);
			return json({ updated: toTodo(task, list_id, today(timezone)) });
		}),
	);

	server.registerTool(
		"update_task",
		{
			title: "Edit a task",
			description:
				"Changes a Google Tasks task's title, notes or due date. Only the fields you pass change. Use clear_due to remove the due date, or notes=\"\" to clear the notes.",
			inputSchema: {
				list_id: z.string(),
				task_id: z.string(),
				title: z.string().trim().min(1).optional(),
				notes: z.string().optional(),
				due: dateField.optional(),
				clear_due: z.boolean().optional().describe("Remove the due date."),
				timezone: timeZoneField,
			},
			annotations: { readOnlyHint: false, destructiveHint: true, idempotentHint: true, openWorldHint: false },
		},
		run(async ({ list_id, task_id, title, notes, due, clear_due, timezone }) => {
			if (due && clear_due) throw new Error("Pass either due or clear_due, not both.");
			const patch: Record<string, unknown> = {};
			if (title !== undefined) patch.title = title;
			if (notes !== undefined) patch.notes = notes;
			if (due) patch.due = toGoogleDue(due);
			if (clear_due) patch.due = null;
			if (Object.keys(patch).length === 0) throw new Error("Nothing to change: pass title, notes, due or clear_due.");
			const task = await client.patchTask(list_id, task_id, patch);
			return json({ updated: toTodo(task, list_id, today(timezone)) });
		}),
	);
}
