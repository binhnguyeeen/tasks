import { describe, expect, it } from "vitest";
import { foldText, type GoogleTask, matchesQuery, searchTasks } from "../src/todos";

const TODAY = "2026-10-06";
const due = (d: string) => `${d}T00:00:00.000Z`;

const task = (over: Partial<GoogleTask> & { id: string }): GoogleTask => ({
	title: over.id,
	status: "needsAction",
	position: "00000000000000000000",
	...over,
});

describe("foldText", () => {
	it("drops case and accents, including Vietnamese đ", () => {
		expect(foldText("Học tiếng Đức")).toBe("hoc tieng duc");
		expect(foldText("Café CRÈME")).toBe("cafe creme");
	});
});

describe("matchesQuery", () => {
	it("needs every word, in any order, across title and notes", () => {
		const rent = task({ id: "r", title: "Pay rent", notes: "March, to landlord" });
		expect(matchesQuery(rent, "rent march")).toBe(true);
		expect(matchesQuery(rent, "landlord pay")).toBe(true);
		expect(matchesQuery(rent, "rent april")).toBe(false);
	});

	it("matches without accents", () => {
		expect(matchesQuery(task({ id: "v", title: "Đi chợ mua rau" }), "di cho")).toBe(true);
	});
});

describe("searchTasks", () => {
	const lists = [
		{
			id: "home",
			title: "Home",
			tasks: [
				task({ id: "trip", title: "Plan trip" }),
				task({ id: "flights", title: "Book flights for trip", parent: "trip", due: due("2026-10-10") }),
				task({ id: "old", title: "Trip photos", status: "completed" }),
				task({ id: "gone", title: "Trip refund", deleted: true }),
			],
		},
		{
			id: "work",
			title: "Work",
			tasks: [task({ id: "expenses", title: "Trip expenses", due: due("2026-10-01") })],
		},
	];

	it("searches every list, open tasks first, earliest due first, undated last", () => {
		const out = searchTasks(lists, "trip", TODAY, false, 25);
		expect(out.tasks.map((t) => t.id)).toEqual(["expenses", "flights", "trip"]);
		expect(out).toMatchObject({ count: 3, truncated: false });
	});

	it("names the list and the parent", () => {
		const flights = searchTasks(lists, "flights", TODAY, false, 25).tasks[0];
		expect(flights).toMatchObject({
			list_id: "home",
			list_title: "Home",
			parent_id: "trip",
			parent_title: "Plan trip",
			due: "2026-10-10",
		});
		expect(searchTasks(lists, "expenses", TODAY, false, 25).tasks[0]).toMatchObject({ overdue: true, list_title: "Work" });
	});

	it("skips deleted tasks, and completed ones unless asked, putting them last", () => {
		expect(searchTasks(lists, "trip", TODAY, true, 25).tasks.map((t) => t.id)).toEqual([
			"expenses",
			"flights",
			"trip",
			"old",
		]);
	});

	it("stops at the limit and says so", () => {
		const out = searchTasks(lists, "trip", TODAY, false, 2);
		expect(out.tasks.map((t) => t.id)).toEqual(["expenses", "flights"]);
		expect(out).toMatchObject({ count: 3, truncated: true });
	});
});
