import { addDays, dueDateOf } from "./dates";

export type When = "today_and_overdue" | "next_7_days" | "no_date" | "all";

export interface GoogleTask {
	id: string;
	title?: string;
	notes?: string;
	status?: "needsAction" | "completed";
	due?: string;
	completed?: string;
	parent?: string;
	position?: string;
	webViewLink?: string;
	deleted?: boolean;
	hidden?: boolean;
}

export interface GoogleTaskList {
	id: string;
	title?: string;
	updated?: string;
}

export interface Todo {
	id: string;
	list_id: string;
	title: string;
	notes?: string;
	due?: string;
	status: "needsAction" | "completed";
	overdue: boolean;
	completed_at?: string;
	parent_id?: string;
	webViewLink?: string;
	subtasks?: Todo[];
}

export interface TodoGroup {
	list_id: string;
	list_title: string;
	tasks: Todo[];
}

export function dueBounds(when: When, today: string): { dueMin?: string; dueMax?: string } {
	switch (when) {
		case "today_and_overdue":
			return { dueMax: `${addDays(today, 1)}T00:00:00.000Z` };
		case "next_7_days":
			return { dueMax: `${addDays(today, 8)}T00:00:00.000Z` };
		default:
			return {};
	}
}

export function matchesWhen(task: GoogleTask, when: When, today: string): boolean {
	const due = dueDateOf(task.due);
	switch (when) {
		case "today_and_overdue":
			return due !== null && due <= today;
		case "next_7_days":
			return due !== null && due <= addDays(today, 7);
		case "no_date":
			return due === null;
		case "all":
			return true;
	}
}

export function toTodo(task: GoogleTask, listId: string, today: string): Todo {
	const due = dueDateOf(task.due);
	const status = task.status === "completed" ? "completed" : "needsAction";
	const todo: Todo = {
		id: task.id,
		list_id: listId,
		title: task.title?.trim() || "(untitled)",
		status,
		overdue: status === "needsAction" && due !== null && due < today,
	};
	if (task.notes) todo.notes = task.notes;
	if (due) todo.due = due;
	if (task.completed) todo.completed_at = task.completed;
	if (task.parent) todo.parent_id = task.parent;
	if (task.webViewLink) todo.webViewLink = task.webViewLink;
	return todo;
}

function byPosition(a: GoogleTask, b: GoogleTask): number {
	return (a.position ?? "").localeCompare(b.position ?? "");
}

function byDueThenPosition(a: GoogleTask, b: GoogleTask): number {
	const da = dueDateOf(a.due) ?? "9999-99-99";
	const db = dueDateOf(b.due) ?? "9999-99-99";
	return da === db ? byPosition(a, b) : da.localeCompare(db);
}

export function buildTodos(
	tasks: GoogleTask[],
	listId: string,
	when: When,
	today: string,
	includeCompleted: boolean,
	query?: string,
): Todo[] {
	const needle = query?.trim().toLowerCase();
	const kept = tasks
		.filter((t) => !t.deleted)
		.filter((t) => includeCompleted || t.status !== "completed")
		.filter((t) => matchesWhen(t, when, today))
		.filter(
			(t) =>
				!needle ||
				(t.title ?? "").toLowerCase().includes(needle) ||
				(t.notes ?? "").toLowerCase().includes(needle),
		)
		.sort(when === "today_and_overdue" || when === "next_7_days" ? byDueThenPosition : byPosition);

	const nodes = new Map<string, Todo>();
	for (const task of kept) nodes.set(task.id, toTodo(task, listId, today));

	const roots: Todo[] = [];
	for (const task of kept) {
		const node = nodes.get(task.id)!;
		const parent = task.parent ? nodes.get(task.parent) : undefined;
		if (parent) {
			(parent.subtasks ??= []).push(node);
			delete node.parent_id;
		} else {
			roots.push(node);
		}
	}
	return roots;
}

export function countTodos(todos: Todo[]): number {
	return todos.reduce((n, t) => n + 1 + countTodos(t.subtasks ?? []), 0);
}
