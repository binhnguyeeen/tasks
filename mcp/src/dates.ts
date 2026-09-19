/**
 * Due-date rules for Google Tasks.
 *
 * Google stores "due on day D" as `D T00:00:00.000Z` and has no due times.
 * Read the date as the first 10 characters and never convert it to local time.
 * Write it back as `${D}T00:00:00.000Z`. "Today" is today in the user's time zone.
 */

const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;

/** True for a real calendar date written as YYYY-MM-DD. */
export function isValidDate(date: string): boolean {
	if (!DATE_RE.test(date)) return false;
	const parsed = new Date(`${date}T00:00:00.000Z`);
	return !Number.isNaN(parsed.getTime()) && parsed.toISOString().slice(0, 10) === date;
}

/** The due day of a Google task, or null when it has none. */
export function dueDateOf(due: string | null | undefined): string | null {
	if (!due) return null;
	const day = due.slice(0, 10);
	return isValidDate(day) ? day : null;
}

/** The value Google expects in a task's `due` field. */
export function toGoogleDue(date: string): string {
	if (!isValidDate(date)) throw new Error(`Invalid date "${date}". Use YYYY-MM-DD.`);
	return `${date}T00:00:00.000Z`;
}

/** Throws a readable error when `timeZone` isn't an IANA time zone. */
export function assertTimeZone(timeZone: string): void {
	try {
		new Intl.DateTimeFormat("en-US", { timeZone });
	} catch {
		throw new Error(`Unknown time zone "${timeZone}". Use an IANA name like "Asia/Ho_Chi_Minh".`);
	}
}

/** Today's date (YYYY-MM-DD) in `timeZone`. */
export function todayIn(timeZone: string, now: Date = new Date()): string {
	assertTimeZone(timeZone);
	const parts = new Intl.DateTimeFormat("en-US", {
		timeZone,
		year: "numeric",
		month: "2-digit",
		day: "2-digit",
	}).formatToParts(now);
	const get = (type: string) => parts.find((p) => p.type === type)?.value ?? "";
	return `${get("year")}-${get("month")}-${get("day")}`;
}

/** `date` plus `days` (can be negative), as YYYY-MM-DD. */
export function addDays(date: string, days: number): string {
	const d = new Date(`${date}T00:00:00.000Z`);
	d.setUTCDate(d.getUTCDate() + days);
	return d.toISOString().slice(0, 10);
}
