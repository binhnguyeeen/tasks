import { ArrowUpRight, Check, X } from "lucide-react";
import { PageIntro } from "@/components/page-intro";
import { Step, Steps } from "@/components/steps";
import { requestAccess } from "@/lib/request-access";

const base = import.meta.env.BASE_URL;

const prompts = [
  "What’s due today?",
  "What do I have this week?",
  "Add “call the dentist” to my Work list for Monday.",
  "Mark “pay rent” as done.",
];

const can = [
  "See your lists and tasks, including notes and due dates",
  "Tick tasks off, or un-tick them",
  "Add tasks, with a due date, notes or a parent task",
  "Edit titles, notes and due dates",
];

const cannot = [
  "Delete tasks or lists",
  "See anything else in your Google account (the connector only checks your email address to let you in)",
  "Set due times, because Google Tasks only stores dates",
];

export default function Claude() {
  return (
    <>
      <PageIntro eyebrow="Claude connector" title="Use Google Tasks in Claude">
        Let Claude see what’s due, tick tasks off, and add new ones.
      </PageIntro>

      <section className="px-5 pb-16">
        <div className="mx-auto grid max-w-3xl gap-4 sm:grid-cols-2">
          <article className="rounded-3xl border border-black/5 p-7 dark:border-white/10">
            <h2 className="text-base font-semibold">Invite-only</h2>
            <p className="mt-2 text-sm text-zinc-500 dark:text-zinc-400">
              The hosted connector works for Google accounts that have been added by hand. Ask for access first.
            </p>
            <button
              onClick={requestAccess}
              className="mt-5 rounded-full bg-zinc-900 px-4 py-2 text-sm text-white transition hover:bg-zinc-700 dark:bg-white dark:text-zinc-900 dark:hover:bg-zinc-200"
            >
              Request Access…
            </button>
          </article>
          <article className="rounded-3xl border border-black/5 p-7 dark:border-white/10">
            <h2 className="text-base font-semibold">A Claude plan with connectors</h2>
            <p className="mt-2 text-sm text-zinc-500 dark:text-zinc-400">
              You need a Claude plan that lets you add custom connectors. Without one, the Add custom connector button
              won’t be there.
            </p>
          </article>
        </div>
      </section>

      <section className="px-5 pb-20">
        <Steps>
          <Step n={1} title="Add the connector">
            <p>
              In Claude, open <strong className="font-medium text-zinc-700 dark:text-zinc-200">Settings → Connectors</strong>{" "}
              and choose <strong className="font-medium text-zinc-700 dark:text-zinc-200">Add custom connector</strong>.
              Name it <em>Google Tasks</em> and paste this address:
            </p>
            <p className="overflow-x-auto rounded-2xl border border-black/5 bg-white px-4 py-3 font-mono text-sm text-zinc-700 dark:border-white/10 dark:bg-black dark:text-zinc-300">
              https://tasks-mcp.trinhquocbinhnguyen.workers.dev/mcp
            </p>
          </Step>
          <Step n={2} title="Connect">
            <p>
              Click <strong className="font-medium text-zinc-700 dark:text-zinc-200">Connect</strong> and sign in with
              the Google account you asked access for. Google warns that it hasn’t verified the app: click{" "}
              <strong className="font-medium text-zinc-700 dark:text-zinc-200">Advanced</strong>, then{" "}
              <strong className="font-medium text-zinc-700 dark:text-zinc-200">Go to Tasks</strong>, then{" "}
              <strong className="font-medium text-zinc-700 dark:text-zinc-200">Allow</strong>.
            </p>
          </Step>
          <Step n={3} title="Try it">
            <p>Ask Claude:</p>
            <ul className="flex flex-wrap gap-2">
              {prompts.map(p => (
                <li
                  key={p}
                  className="rounded-full border border-black/5 bg-white px-4 py-2 text-sm text-zinc-600 dark:border-white/10 dark:bg-black dark:text-zinc-300"
                >
                  {p}
                </li>
              ))}
            </ul>
          </Step>
        </Steps>
      </section>

      <section className="bg-zinc-50 px-5 py-20 dark:bg-zinc-950">
        <div className="mx-auto max-w-3xl">
          <h2 className="font-display text-center text-4xl leading-tight">What Claude can do.</h2>
          <div className="mt-10 grid gap-4 sm:grid-cols-2">
            <div className="rounded-3xl bg-white p-7 dark:bg-black">
              <h3 className="text-sm font-semibold text-emerald-600 dark:text-emerald-400">Can</h3>
              <ul className="mt-4 space-y-3">
                {can.map(item => (
                  <li key={item} className="flex gap-3 text-sm text-zinc-600 dark:text-zinc-300">
                    <Check size={16} className="mt-0.5 shrink-0 text-emerald-600 dark:text-emerald-400" />
                    {item}
                  </li>
                ))}
              </ul>
            </div>
            <div className="rounded-3xl bg-white p-7 dark:bg-black">
              <h3 className="text-sm font-semibold text-zinc-400">Can’t</h3>
              <ul className="mt-4 space-y-3">
                {cannot.map(item => (
                  <li key={item} className="flex gap-3 text-sm text-zinc-600 dark:text-zinc-300">
                    <X size={16} className="mt-0.5 shrink-0 text-zinc-400" />
                    {item}
                  </li>
                ))}
              </ul>
            </div>
          </div>
        </div>
      </section>

      <section className="px-5 py-20">
        <div className="mx-auto max-w-3xl">
          <h2 className="font-display text-3xl leading-tight">Disconnect</h2>
          <p className="mt-3 text-zinc-500 dark:text-zinc-400">
            In Claude, open <strong className="font-medium text-zinc-700 dark:text-zinc-200">Settings → Connectors</strong>{" "}
            and disconnect Google Tasks. To remove Google access too, visit{" "}
            <a
              href="https://myaccount.google.com/permissions"
              className="text-sky-700 underline decoration-sky-700/40 underline-offset-4 hover:decoration-current dark:text-sky-400 dark:decoration-sky-400/40"
            >
              myaccount.google.com/permissions
            </a>
            .
          </p>
          <p className="mt-8">
            <a
              href={`${base}help.html`}
              className="inline-flex items-center gap-1.5 text-sky-600 hover:underline dark:text-sky-400"
            >
              Common questions <ArrowUpRight size={15} />
            </a>
          </p>
        </div>
      </section>
    </>
  );
}
