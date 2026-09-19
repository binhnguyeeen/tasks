const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;

export function isValidDate(date: string): boolean {
	if (!DATE_RE.test(date)) return false;
	const parsed = new Date(`${date}T00:00:00.000Z`);
	return !Number.isNaN(parsed.getTime()) && parsed.toISOString().slice(0, 10) === date;
}

export function dueDateOf(due: string | null | undefined): string | null {
	if (!due) return null;
	const day = due.slice(0, 10);
	return isValidDate(day) ? day : null;
}

export function toGoogleDue(date: string): string {
	if (!isValidDate(date)) throw new Error(`Invalid date "${date}". Use YYYY-MM-DD.`);
	return `${date}T00:00:00.000Z`;
}

export function assertTimeZone(timeZone: string): void {
	try {
		new Intl.DateTimeFormat("en-US", { timeZone });
	} catch {
		throw new Error(`Unknown time zone "${timeZone}". Use an IANA name like "Asia/Ho_Chi_Minh".`);
	}
}

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

export function addDays(date: string, days: number): string {
	const d = new Date(`${date}T00:00:00.000Z`);
	d.setUTCDate(d.getUTCDate() + days);
	return d.toISOString().slice(0, 10);
}
