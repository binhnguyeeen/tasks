import type { ReactNode } from "react";
import { Plus } from "lucide-react";
import { PageIntro } from "@/components/page-intro";
import { mailto, requestAccess } from "@/lib/contact";

const base = import.meta.env.BASE_URL;

const link = "text-sky-700 underline decoration-sky-700/40 underline-offset-4 hover:decoration-current dark:text-sky-400 dark:decoration-sky-400/40";

const questions: { q: string; a: ReactNode }[] = [
  {
    q: "Why does Google say the app isn’t verified?",
    a: (
      <>
        Google reviews apps before removing that warning, and Tasks hasn’t been through that review yet. The warning
        doesn’t mean anything is wrong. Tasks only asks for access to Google Tasks.
      </>
    ),
  },
  {
    q: "Can I set a time for a task?",
    a: (
      <>
        No. Google Tasks only stores a due date, not a time, so neither the app nor Claude can set one.
      </>
    ),
  },
  {
    q: "Does Tasks keep a copy of my tasks?",
    a: (
      <>
        No. The Mac app holds them in memory while it’s open, and the connector only passes them between Google and
        Claude. See the{" "}
        <a href={`${base}privacy.html`} className={link}>
          Privacy Policy
        </a>
        .
      </>
    ),
  },
  {
    q: "Does the Mac app work offline?",
    a: (
      <>
        It shows a notice and waits. Tasks can’t be changed until you’re back online, so nothing gets out of sync.
      </>
    ),
  },
  {
    q: "Why can’t Claude delete tasks?",
    a: (
      <>
        On purpose. Claude can add, edit and tick off tasks, but deleting stays with you, in the Mac app or in Google
        Tasks.
      </>
    ),
  },
  {
    q: "Who can use the connector?",
    a: (
      <>
        Only Google accounts that have been added by hand.{" "}
        <button onClick={requestAccess} className={link}>
          Request access
        </button>
        , or run your own copy from the{" "}
        <a href="https://github.com/binhnguyeeen/tasks" className={link}>
          source code
        </a>
        .
      </>
    ),
  },
  {
    q: "How do I remove Tasks’ access to my Google account?",
    a: (
      <>
        Visit{" "}
        <a href="https://myaccount.google.com/permissions" className={link}>
          myaccount.google.com/permissions
        </a>
        , choose Tasks, and remove access.
      </>
    ),
  },
  {
    q: "Is Tasks made by Google, Apple or Anthropic?",
    a: <>No. It’s an independent project that works with Google Tasks and Claude.</>,
  },
  {
    q: "Something’s wrong.",
    a: (
      <>
        <a href="https://github.com/binhnguyeeen/tasks/issues" className={link}>
          Open an issue on GitHub
        </a>{" "}
        or{" "}
        <a href={mailto("Tasks: something isn’t working")} className={link}>
          send an email
        </a>
        .
      </>
    ),
  },
];

export default function Help() {
  return (
    <>
      <PageIntro eyebrow="Help" title="Questions, answered.">
        The things people ask most about the Mac app and the Claude connector.
      </PageIntro>

      <section className="px-5 pb-28">
        <div className="mx-auto max-w-3xl divide-y divide-black/5 overflow-hidden rounded-3xl bg-zinc-50 dark:divide-white/10 dark:bg-zinc-950">
          {questions.map(item => (
            <details key={item.q} className="group px-7 py-1 sm:px-8">
              <summary className="flex list-none items-center justify-between gap-6 py-5 text-left text-lg font-medium marker:hidden [&::-webkit-details-marker]:hidden">
                {item.q}
                <Plus
                  size={18}
                  className="shrink-0 text-zinc-400 transition-transform duration-200 group-open:rotate-45 motion-reduce:transition-none"
                />
              </summary>
              <p className="pb-6 pr-10 text-pretty text-zinc-500 dark:text-zinc-400">{item.a}</p>
            </details>
          ))}
        </div>

        <p className="mx-auto mt-10 max-w-3xl text-center text-sm text-zinc-500 dark:text-zinc-400">
          Still stuck? Read the{" "}
          <a href={`${base}claude.html`} className={link}>
            Claude connector guide
          </a>{" "}
          or{" "}
          <a href="https://github.com/binhnguyeeen/tasks/issues" className={link}>
            open an issue
          </a>
          .
        </p>
      </section>
    </>
  );
}
