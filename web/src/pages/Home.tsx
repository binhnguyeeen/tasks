import { ArrowUpRight, Check } from "lucide-react";
import { InlineAction } from "@/components/watermelon/inline-action";

const base = import.meta.env.BASE_URL;

function requestAccess() {
  const address = ["trinhquocbinhnguyen", "gmail.com"].join("@");
  const subject = encodeURIComponent("Tasks connector access");
  const body = encodeURIComponent("Hi, could you add me to the Tasks connector? My Google account is: ");
  window.location.href = `mailto:${address}?subject=${subject}&body=${body}`;
}

export default function Home() {
  return (
    <>
        <section className="relative overflow-hidden px-5 pb-24 pt-20 text-center">
          <div
            aria-hidden="true"
            className="pointer-events-none absolute inset-x-0 -top-40 mx-auto h-[420px] max-w-4xl rounded-full bg-gradient-to-b from-sky-200/70 via-violet-200/40 to-transparent blur-3xl dark:from-sky-500/20 dark:via-violet-500/10"
          />
          <div className="relative mx-auto max-w-3xl">
            <a
              href={`${base}claude.html`}
              className="inline-flex items-center gap-2 rounded-full border border-black/5 bg-white/80 py-1.5 pl-2 pr-3.5 text-sm font-medium shadow-sm backdrop-blur transition hover:shadow dark:border-white/10 dark:bg-zinc-900/80"
            >
              <span className="flex size-6 items-center justify-center rounded-full bg-zinc-900 text-white dark:bg-white dark:text-zinc-900">
                <ArrowUpRight size={13} />
              </span>
              Now works with Claude
            </a>
            <img src={`${base}icon.png`} alt="Tasks app icon" className="mx-auto mt-10 size-28 drop-shadow-2xl" />
            <h1 className="font-display mt-8 text-balance text-6xl leading-[1.02] sm:text-7xl">
              Google Tasks.
              <br />
              Right on your Mac.
            </h1>
            <p className="mx-auto mt-5 max-w-lg text-pretty text-lg text-zinc-500 dark:text-zinc-400">
              A menu bar app for your tasks, and a connector that lets Claude keep track of them too.
            </p>
            <div className="mt-8 flex flex-wrap items-center justify-center gap-3">
              <span className="cursor-default rounded-full border border-black/10 bg-zinc-100 px-6 py-3 text-zinc-400 dark:border-white/10 dark:bg-zinc-900 dark:text-zinc-500">
                Coming Soon
              </span>
              <a
                href={`${base}claude.html`}
                className="rounded-full bg-zinc-900 px-6 py-3 text-white transition hover:bg-zinc-700 dark:bg-white dark:text-zinc-900 dark:hover:bg-zinc-200"
              >
                Connect Claude
              </a>
            </div>
            <p className="mt-3 text-xs text-zinc-400">Mac app · macOS 27 or later</p>
          </div>
        </section>

        <section className="px-5 py-8">
          <div className="mx-auto max-w-2xl rounded-3xl border border-black/5 bg-zinc-50 p-8 text-center dark:border-white/10 dark:bg-zinc-950">
            <p className="text-sm font-medium text-zinc-500">Connected to your Google account</p>
            <div className="mt-5 flex justify-center">
              <InlineAction
                label="Google Tasks"
                icon={<Check size={15} />}
                actionText="Sync now"
                onAction={() => new Promise(resolve => setTimeout(resolve, 1400))}
              />
            </div>
            <p className="mt-5 text-sm text-zinc-500">
              Changes land in Google Tasks straight away, so your phone stays in step.
            </p>
          </div>
        </section>

        <section className="px-5 py-20">
          <div className="mx-auto grid max-w-6xl gap-4 sm:grid-cols-2 lg:grid-cols-3">
            <article className="rounded-3xl bg-zinc-50 p-8 dark:bg-zinc-950 lg:col-span-2">
              <p className="text-sm font-medium text-amber-600">Menu bar</p>
              <h3 className="font-display mt-2 text-3xl leading-tight">Everything due, one click away.</h3>
              <p className="mt-3 text-zinc-500 dark:text-zinc-400">
                A checkmark in your menu bar shows how many tasks are due today or overdue. Click it to tick things off
                or add a new one, without opening a window.
              </p>
              <div className="mt-10 inline-flex items-center gap-3 rounded-full bg-zinc-900 px-6 py-3 text-3xl font-semibold text-white tabular-nums dark:bg-zinc-100 dark:text-zinc-900">
                <Check size={30} />3
              </div>
            </article>

            <article className="rounded-3xl bg-zinc-50 p-8 dark:bg-zinc-950">
              <p className="text-sm font-medium text-amber-600">Quick add</p>
              <h3 className="font-display mt-2 text-3xl leading-tight">Type “pay rent friday”. That’s it.</h3>
              <p className="mt-3 text-zinc-500 dark:text-zinc-400">
                Tasks spots the date as you type and sets it as the due date.
              </p>
              <div className="mt-8 rounded-2xl border border-black/5 bg-white px-4 py-3 text-lg dark:border-white/10 dark:bg-black">
                pay rent <span className="rounded-md bg-sky-500/15 px-1.5 text-sky-600 dark:text-sky-400">friday</span>
              </div>
            </article>

            <article className="rounded-3xl bg-zinc-50 p-8 dark:bg-zinc-950">
              <p className="text-sm font-medium text-amber-600">Smart lists</p>
              <h3 className="font-display mt-2 text-3xl leading-tight">Today, Scheduled, All and Completed.</h3>
              <div className="mt-6 flex flex-wrap gap-2 text-sm font-semibold text-white">
                <span className="rounded-xl bg-[#007aff] px-3 py-2">Today</span>
                <span className="rounded-xl bg-[#ff3b30] px-3 py-2">Scheduled</span>
                <span className="rounded-xl bg-[#3a3a3c] px-3 py-2">All</span>
                <span className="rounded-xl bg-[#8e8e93] px-3 py-2">Completed</span>
              </div>
            </article>

            <article className="rounded-3xl bg-zinc-50 p-8 dark:bg-zinc-950">
              <p className="text-sm font-medium text-amber-600">Lists and subtasks</p>
              <h3 className="font-display mt-2 text-3xl leading-tight">Every list. Every subtask.</h3>
              <p className="mt-3 text-zinc-500 dark:text-zinc-400">
                Create, rename and delete lists, keep subtasks under their task, and search across all of them.
              </p>
            </article>

            <article className="rounded-3xl bg-zinc-50 p-8 dark:bg-zinc-950">
              <p className="text-sm font-medium text-amber-600">Light and dark</p>
              <h3 className="font-display mt-2 text-3xl leading-tight">Looks right, day or night.</h3>
              <p className="mt-3 text-zinc-500 dark:text-zinc-400">Follows your Mac’s appearance and accent color.</p>
            </article>
          </div>
        </section>

        <section className="bg-zinc-950 px-5 py-24 text-zinc-100">
          <div className="mx-auto max-w-2xl text-center">
            <p className="text-sm font-medium text-amber-400">Claude connector</p>
            <h2 className="font-display mt-2 text-5xl leading-tight">Claude, meet your tasks.</h2>
            <p className="mt-4 text-pretty text-zinc-400">
              Add the connector to Claude and it can see what’s due, tick tasks off, add new ones and edit them. It
              can’t delete anything.
            </p>
          </div>
          <div className="mx-auto mt-10 flex max-w-xl flex-col gap-3">
            <p className="max-w-[80%] self-end rounded-3xl rounded-br-lg bg-sky-600 px-5 py-3">What’s due today?</p>
            <p className="max-w-[85%] rounded-3xl rounded-bl-lg bg-zinc-800 px-5 py-3">
              Two things: <strong>Send September invoice</strong> (Work) and <strong>Call mom</strong> (Home).{" "}
              <span className="text-red-400">Pay rent</span> has been overdue since yesterday.
            </p>
            <p className="max-w-[80%] self-end rounded-3xl rounded-br-lg bg-sky-600 px-5 py-3">
              I paid the rent. Tick it off.
            </p>
            <p className="max-w-[85%] rounded-3xl rounded-bl-lg bg-zinc-800 px-5 py-3">
              Done. “Pay rent” is marked as complete.
            </p>
          </div>
          <p className="mt-10 text-center">
            <a href={`${base}claude.html`} className="text-sky-400 hover:underline">
              How to connect Claude ›
            </a>
          </p>
        </section>

        <section className="px-5 py-24">
          <div className="mx-auto max-w-3xl rounded-[2rem] bg-zinc-50 px-8 py-16 text-center dark:bg-zinc-950">
            <h2 className="font-display text-5xl leading-tight">Invite-only, for now.</h2>
            <p className="mx-auto mt-4 max-w-md text-pretty text-zinc-500 dark:text-zinc-400">
              The hosted connector works for Google accounts that have been added by hand. Ask for access, or run your
              own copy from the source code.
            </p>
            <div className="mt-8 flex flex-wrap justify-center gap-3">
              <button
                onClick={requestAccess}
                className="rounded-full bg-zinc-900 px-6 py-3 text-white transition hover:bg-zinc-700 dark:bg-white dark:text-zinc-900 dark:hover:bg-zinc-200"
              >
                Request Access…
              </button>
              <a
                href="https://github.com/binhnguyeeen/tasks"
                className="rounded-full border border-black/10 px-6 py-3 transition hover:bg-zinc-100 dark:border-white/15 dark:hover:bg-zinc-900"
              >
                View Source on GitHub
              </a>
            </div>
          </div>
        </section>
    </>
  );
}
