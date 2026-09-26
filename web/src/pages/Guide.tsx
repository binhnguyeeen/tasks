import { ArrowUpRight } from "lucide-react";
import { PageIntro } from "@/components/page-intro";
import { macDownloadURL } from "@/lib/download";

const base = import.meta.env.BASE_URL;

const everyday = [
  {
    title: "Quick add with dates",
    body: "Type “pay rent friday” in the menu bar. Tasks highlights the date, sets it as the due date, and keeps the rest as the title.",
  },
  {
    title: "Smart lists",
    body: "Today holds what’s overdue and due now. Scheduled holds everything with a date. All and Completed hold the rest, grouped by list.",
  },
  {
    title: "Subtasks",
    body: "Right-click a task and choose Add Subtask. Subtasks sit under their parent and can be folded away.",
  },
  {
    title: "Search",
    body: "Press ⌘F to search every list at once. Results are grouped under the list they came from.",
  },
  {
    title: "Details",
    body: "Press ⌘I for the inspector: title, notes, due date and which list a task belongs to. Changes save as you go.",
  },
  {
    title: "Ask Claude",
    body: "With the connector added, Claude can tell you what’s due, add tasks and tick them off. It can’t delete anything.",
  },
];

export default function Guide() {
  return (
    <>
      <PageIntro eyebrow="Guide" title="Everything, step by step.">
        Set up the Mac app and the Claude connector, then get the most out of both.
      </PageIntro>

      <section className="px-5 pb-20">
        <div className="mx-auto grid max-w-4xl gap-4 sm:grid-cols-2">
          <article className="flex flex-col rounded-3xl bg-zinc-50 p-8 dark:bg-zinc-950">
            <p className="text-sm font-medium text-zinc-400">Step one</p>
            <h2 className="font-display mt-2 text-3xl leading-tight">Install the Mac app.</h2>
            <p className="mt-3 flex-1 text-zinc-500 dark:text-zinc-400">
              Download it, take it past the one-time macOS security prompt, and sign in with Google. Nothing to install
              beyond dragging it to Applications.
            </p>
            <div className="mt-8 flex flex-wrap gap-3">
              <a href={macDownloadURL} className="rounded-full bg-zinc-900 px-4 py-2 text-sm text-white transition hover:bg-zinc-700 dark:bg-white dark:text-zinc-900 dark:hover:bg-zinc-200">
                Download for Mac
              </a>
              <a href={`${base}mac.html`} className="rounded-full border border-black/10 px-4 py-2 text-sm transition hover:bg-zinc-100 dark:border-white/15 dark:hover:bg-zinc-900">
                Install guide
              </a>
            </div>
          </article>

          <article className="flex flex-col rounded-3xl bg-zinc-50 p-8 dark:bg-zinc-950">
            <p className="text-sm font-medium text-zinc-400">Step two</p>
            <h2 className="font-display mt-2 text-3xl leading-tight">Connect Claude.</h2>
            <p className="mt-3 flex-1 text-zinc-500 dark:text-zinc-400">
              Add the connector in Claude’s settings, sign in with the Google account you were given access for, and ask
              it what’s due today.
            </p>
            <a
              href={`${base}claude.html`}
              className="mt-8 inline-flex w-fit items-center gap-1.5 rounded-full bg-zinc-900 px-4 py-2 text-sm text-white transition hover:bg-zinc-700 dark:bg-white dark:text-zinc-900 dark:hover:bg-zinc-200"
            >
              Read the guide <ArrowUpRight size={15} />
            </a>
          </article>
        </div>
      </section>

      <section className="bg-zinc-50 px-5 py-20 dark:bg-zinc-950">
        <div className="mx-auto max-w-5xl">
          <h2 className="font-display text-center text-4xl leading-tight">Everyday use.</h2>
          <div className="mt-12 grid gap-x-10 gap-y-8 sm:grid-cols-2 lg:grid-cols-3">
            {everyday.map(item => (
              <article key={item.title}>
                <h3 className="text-base font-semibold">{item.title}</h3>
                <p className="mt-2 text-pretty text-zinc-500 dark:text-zinc-400">{item.body}</p>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section className="px-5 py-20 text-center">
        <p className="text-zinc-500 dark:text-zinc-400">
          Something not covered here?{" "}
          <a href={`${base}help.html`} className="text-sky-700 underline decoration-sky-700/40 underline-offset-4 hover:decoration-current dark:text-sky-400 dark:decoration-sky-400/40">
            Check the Help page
          </a>
          .
        </p>
      </section>
    </>
  );
}
