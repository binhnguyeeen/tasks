export interface ChangelogEntry {
  product: "Mac app" | "Claude connector";
  version?: string;
  date: string;
  title: string;
  changes: string[];
}

export const changelog: ChangelogEntry[] = [
  {
    product: "Mac app",
    version: "1.0.1",
    date: "2026-09-26",
    title: "Tasks 1.0.1",
    changes: [
      "Runs on macOS 26 (Tahoe) or later, not only macOS 27.",
      "Still needs a Mac with Apple silicon. Nothing else changed.",
    ],
  },
  {
    product: "Mac app",
    version: "1.0",
    date: "2026-09-26",
    title: "Tasks 1.0",
    changes: [
      "A checkmark in the menu bar with the number of tasks due today or overdue.",
      "Its dropdown shows Overdue and Today, and adds tasks as you type: “pay rent friday” sets Friday as the due date.",
      "A full window with Today, Scheduled, All and Completed, your lists in colors you pick, subtasks, search, drag to reorder, and moving tasks between lists.",
      "Changes go straight to Google Tasks, so your phone stays in step.",
    ],
  },
  {
    product: "Claude connector",
    date: "2026-09-25",
    title: "Smoother sign-in",
    changes: [
      "The connector remembers that you approved Claude for 30 days, so reconnecting skips the approval screen.",
      "Sign-in error pages explain the problem instead of showing technical messages.",
    ],
  },
  {
    product: "Claude connector",
    date: "2026-09-23",
    title: "The Claude connector",
    changes: [
      "Claude can see what’s due, add tasks, edit them and tick them off in Google Tasks.",
      "Invite-only for now.",
    ],
  },
];

export const latestMacVersion = changelog.find(entry => entry.product === "Mac app")?.version ?? "1.0";

const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

export function formatDate(date: string): string {
  const [year, month, day] = date.split("-").map(Number);
  return `${day} ${months[month - 1]} ${year}`;
}

export function releaseURL(version: string): string {
  return `https://github.com/binhnguyeeen/tasks/releases/tag/v${version}`;
}
