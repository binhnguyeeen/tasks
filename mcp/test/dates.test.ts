import { describe, expect, it } from "vitest";
import { addDays, assertTimeZone, dueDateOf, isValidDate, todayIn, toGoogleDue } from "../src/dates";

describe("isValidDate", () => {
	it("accepts real YYYY-MM-DD dates", () => {
		expect(isValidDate("2026-09-19")).toBe(true);
		expect(isValidDate("2028-02-29")).toBe(true);
	});
	it("rejects impossible or badly formatted dates", () => {
		expect(isValidDate("2026-02-30")).toBe(false);
		expect(isValidDate("2027-02-29")).toBe(false);
		expect(isValidDate("2026-9-19")).toBe(false);
		expect(isValidDate("19/09/2026")).toBe(false);
		expect(isValidDate("")).toBe(false);
	});
});

describe("due date round trip", () => {
	it("writes UTC midnight and reads the same day back, never shifting it", () => {
		const written = toGoogleDue("2026-09-19");
		expect(written).toBe("2026-09-19T00:00:00.000Z");
		expect(dueDateOf(written)).toBe("2026-09-19");
	});
	it("reads the date part of whatever Google returns", () => {
		expect(dueDateOf("2026-01-01T00:00:00.000Z")).toBe("2026-01-01");
		expect(dueDateOf(undefined)).toBeNull();
		expect(dueDateOf(null)).toBeNull();
		expect(dueDateOf("garbage")).toBeNull();
	});
	it("refuses to write invalid dates", () => {
		expect(() => toGoogleDue("2026-02-30")).toThrow(/Invalid date/);
	});
});

describe("todayIn", () => {
	const evening = new Date("2026-09-19T18:30:00Z");
	const earlyMorning = new Date("2026-09-19T02:00:00Z");

	it("uses the user's time zone ahead of UTC", () => {
		expect(todayIn("Asia/Ho_Chi_Minh", evening)).toBe("2026-09-20");
		expect(todayIn("Pacific/Kiritimati", evening)).toBe("2026-09-20");
	});
	it("uses the user's time zone behind UTC", () => {
		expect(todayIn("America/Los_Angeles", earlyMorning)).toBe("2026-09-18");
		expect(todayIn("Pacific/Pago_Pago", evening)).toBe("2026-09-19");
	});
	it("matches UTC for UTC", () => {
		expect(todayIn("UTC", earlyMorning)).toBe("2026-09-19");
	});
	it("rejects unknown time zones", () => {
		expect(() => assertTimeZone("Mars/Olympus_Mons")).toThrow(/Unknown time zone/);
		expect(() => todayIn("Nowhere/Nope")).toThrow(/Unknown time zone/);
	});
});

describe("addDays", () => {
	it("crosses months, years and leap days", () => {
		expect(addDays("2026-12-31", 1)).toBe("2027-01-01");
		expect(addDays("2026-03-01", -1)).toBe("2026-02-28");
		expect(addDays("2028-02-28", 1)).toBe("2028-02-29");
		expect(addDays("2026-09-19", 7)).toBe("2026-09-26");
	});
});
