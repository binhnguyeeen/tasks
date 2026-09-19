/**
 * Thin client for the Google Tasks REST API.
 * https://developers.google.com/workspace/tasks/reference/rest
 */
import type { GoogleTask, GoogleTaskList } from "./todos";

const BASE = "https://tasks.googleapis.com/tasks/v1";

export class GoogleApiError extends Error {
	constructor(
		readonly status: number,
		message: string,
	) {
		super(message);
	}
}

/** Supplies a valid access token; `forceRefresh` is set after Google answers 401. */
export type TokenSource = (forceRefresh: boolean) => Promise<string>;

type Query = Record<string, string | number | boolean | undefined>;

export class GoogleTasksClient {
	constructor(private readonly getToken: TokenSource) {}

	private async request<T>(method: string, path: string, query: Query = {}, body?: unknown): Promise<T> {
		const url = new URL(BASE + path);
		for (const [k, v] of Object.entries(query)) {
			if (v !== undefined) url.searchParams.set(k, String(v));
		}

		const send = async (forceRefresh: boolean) =>
			fetch(url, {
				method,
				headers: {
					Authorization: `Bearer ${await this.getToken(forceRefresh)}`,
					...(body === undefined ? {} : { "Content-Type": "application/json" }),
				},
				body: body === undefined ? undefined : JSON.stringify(body),
			});

		let resp = await send(false);
		if (resp.status === 401) resp = await send(true);

		if (!resp.ok) {
			let message = `Google Tasks returned ${resp.status}`;
			try {
				const err = (await resp.json()) as { error?: { message?: string } };
				if (err.error?.message) message += `: ${err.error.message}`;
			} catch {
				// keep the status-only message
			}
			throw new GoogleApiError(resp.status, message);
		}
		if (resp.status === 204) return undefined as T;
		return (await resp.json()) as T;
	}

	async listTaskLists(): Promise<GoogleTaskList[]> {
		const lists: GoogleTaskList[] = [];
		let pageToken: string | undefined;
		do {
			const page = await this.request<{ items?: GoogleTaskList[]; nextPageToken?: string }>(
				"GET",
				"/users/@me/lists",
				{ maxResults: 100, pageToken },
			);
			lists.push(...(page.items ?? []));
			pageToken = page.nextPageToken;
		} while (pageToken);
		return lists;
	}

	async listTasks(
		listId: string,
		opts: { showCompleted: boolean; dueMin?: string; dueMax?: string },
	): Promise<GoogleTask[]> {
		const tasks: GoogleTask[] = [];
		let pageToken: string | undefined;
		do {
			const page = await this.request<{ items?: GoogleTask[]; nextPageToken?: string }>(
				"GET",
				`/lists/${encodeURIComponent(listId)}/tasks`,
				{
					maxResults: 100,
					pageToken,
					showCompleted: opts.showCompleted,
					// Completed tasks move to "hidden" once cleared in the Tasks app
					showHidden: opts.showCompleted,
					dueMin: opts.dueMin,
					dueMax: opts.dueMax,
				},
			);
			tasks.push(...(page.items ?? []));
			pageToken = page.nextPageToken;
		} while (pageToken);
		return tasks;
	}

	insertTask(listId: string, task: Partial<GoogleTask>, parent?: string): Promise<GoogleTask> {
		return this.request("POST", `/lists/${encodeURIComponent(listId)}/tasks`, { parent }, task);
	}

	patchTask(listId: string, taskId: string, patch: Record<string, unknown>): Promise<GoogleTask> {
		return this.request(
			"PATCH",
			`/lists/${encodeURIComponent(listId)}/tasks/${encodeURIComponent(taskId)}`,
			{},
			patch,
		);
	}
}
