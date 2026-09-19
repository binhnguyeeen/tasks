import { describe, expect, it } from "vitest";
import { buildTodos, countTodos, dueBounds, type GoogleTask, matchesWhen } from "../src/todos";

const TODAY = "2026-09-19";
const due = (d: string) => `${d}T00:00:00.000Z`;

const task = (over: Partial<GoogleTask> & { id: string }): GoogleTask => ({
	title: over.id,
	status: "needsAction",
	position: "00000000000000000000",
	...over,
});

describe("matchesWhen", () => {
	const overdue = task({ id: "o", due: due("2026-09-10") });
	const today = task({ id: "t", due: due(TODAY) });
	const in7 = task({ id: "w", due: due("2026-09-26") });
	const in8 = task({ id: "x", due: due("2026-09-27") });
	const none = task({ id: "n" });

	it("today_and_overdue = due today or earlier", () => {
		expect([overdue, today, in7, none].map((t) => matchesWhen(t, "today_and_overdue", TODAY))).toEqual([
			true,
			true,
			false,
			false,
		]);
	});
	it("next_7_days = overdue plus the next 7 days", () => {
		expect([overdue, today, in7, in8, none].map((t) => matchesWhen(t, "next_7_days", TODAY))).toEqual([
			true,
			true,
			true,
			false,
			false,
		]);
	});
	it("no_date and all", () => {
		expect(matchesWhen(none, "no_date", TODAY)).toBe(true);
		expect(matchesWhen(today, "no_date", TODAY)).toBe(false);
		expect(matchesWhen(none, "all", TODAY)).toBe(true);
	});
});

describe("dueBounds", () => {
	it("pre-filters on Google's side with an exclusive-enough upper bound", () => {
		expect(dueBounds("today_and_overdue", TODAY)).toEqual({ dueMax: "2026-09-20T00:00:00.000Z" });
		expect(dueBounds("next_7_days", TODAY)).toEqual({ dueMax: "2026-09-27T00:00:00.000Z" });
		expect(dueBounds("all", TODAY)).toEqual({});
	});
});

describe("buildTodos", () => {
	it("nests subtasks under their parent in position order", () => {
		const tasks = [
			task({ id: "sub2", parent: "p", position: "00000000000000000002", due: due(TODAY) }),
			task({ id: "p", position: "00000000000000000001", due: due(TODAY) }),
			task({ id: "sub1", parent: "p", position: "00000000000000000001", due: due(TODAY) }),
		];
		const out = buildTodos(tasks, "L", "today_and_overdue", TODAY, false);
		expect(out.map((t) => t.id)).toEqual(["p"]);
		expect(out[0]?.subtasks?.map((t) => t.id)).toEqual(["sub1", "sub2"]);
		expect(out[0]?.subtasks?.[0]?.parent_id).toBeUndefined();
		expect(countTodos(out)).toBe(3);
	});

	it("keeps a subtask top-level with parent_id when its parent is filtered out", () => {
		const tasks = [task({ id: "p" }), task({ id: "sub", parent: "p", due: due(TODAY) })];
		const out = buildTodos(tasks, "L", "today_and_overdue", TODAY, false);
		expect(out).toHaveLength(1);
		expect(out[0]).toMatchObject({ id: "sub", parent_id: "p" });
	});

	it("puts overdue before today and flags it", () => {
		const tasks = [
			task({ id: "today", due: due(TODAY), position: "00000000000000000001" }),
			task({ id: "old", due: due("2026-09-01"), position: "00000000000000000009" }),
		];
		const out = buildTodos(tasks, "L", "today_and_overdue", TODAY, false);
		expect(out.map((t) => [t.id, t.overdue])).toEqual([
			["old", true],
			["today", false],
		]);
	});

	it("hides completed and deleted tasks unless asked", () => {
		const tasks = [
			task({ id: "done", status: "completed", completed: "2026-09-18T10:00:00.000Z" }),
			task({ id: "gone", deleted: true }),
			task({ id: "open" }),
		];
		expect(buildTodos(tasks, "L", "all", TODAY, false).map((t) => t.id)).toEqual(["open"]);
		const withDone = buildTodos(tasks, "L", "all", TODAY, true);
		expect(withDone.map((t) => t.id).sort()).toEqual(["done", "open"]);
		expect(withDone.find((t) => t.id === "done")).toMatchObject({ status: "completed", overdue: false });
	});

	it("never marks a completed task overdue", () => {
		const tasks = [task({ id: "late-but-done", status: "completed", due: due("2026-09-01") })];
		expect(buildTodos(tasks, "L", "all", TODAY, true)[0]?.overdue).toBe(false);
	});

	it("finds tasks by text in title or notes", () => {
		const tasks = [
			task({ id: "a", title: "Pay rent" }),
			task({ id: "b", title: "Call mom", notes: "about RENT deposit" }),
			task({ id: "c", title: "Groceries" }),
		];
		expect(buildTodos(tasks, "L", "all", TODAY, false, "rent").map((t) => t.id)).toEqual(["a", "b"]);
	});

	it("fills in list_id, due and a title for untitled tasks", () => {
		const out = buildTodos([task({ id: "u", title: "  ", due: due(TODAY) })], "LIST", "all", TODAY, false);
		expect(out[0]).toMatchObject({ id: "u", list_id: "LIST", title: "(untitled)", due: TODAY });
	});
});
