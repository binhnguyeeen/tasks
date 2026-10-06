import { ArrowUpRight } from "lucide-react";
import { PageIntro } from "@/components/page-intro";
import { changelog, formatDate, latestMacVersion, releaseURL } from "@/lib/changelog";
import { macDownloadURL } from "@/lib/download";

const link = "text-sky-700 underline decoration-sky-700/40 underline-offset-4 hover:decoration-current dark:text-sky-400 dark:decoration-sky-400/40";

export default function Changelog() {
  return (
    <>
      <PageIntro eyebrow="Changelog" title="What’s new.">
        Every update to the Mac app and the Claude connector, newest first.
      </PageIntro>

      <section className="px-5 pb-12">
        <div className="mx-auto flex max-w-3xl flex-wrap items-center justify-center gap-3">
          <a
            href={macDownloadURL}
            className="rounded-full bg-zinc-900 px-5 py-2.5 text-sm text-white transition hover:bg-zinc-700 dark:bg-white dark:text-zinc-900 dark:hover:bg-zinc-200"
          >
            Download Tasks {latestMacVersion}
          </a>
          <a
            href="https://github.com/binhnguyeeen/tasks/releases"
            className="inline-flex items-center gap-1.5 rounded-full border border-black/10 px-5 py-2.5 text-sm transition hover:bg-zinc-100 dark:border-white/15 dark:hover:bg-zinc-900"
          >
            All releases on GitHub <ArrowUpRight size={15} />
          </a>
        </div>
      </section>

      <section className="px-5 pb-28">
        <ol className="mx-auto grid max-w-3xl gap-4">
          {changelog.map(entry => (
            <li
              key={`${entry.product}-${entry.date}-${entry.title}`}
              className="rounded-3xl bg-zinc-50 p-7 sm:grid sm:grid-cols-[8.5rem_1fr] sm:gap-8 sm:p-8 dark:bg-zinc-950"
            >
              <div className="text-sm">
                <time dateTime={entry.date} className="font-medium text-zinc-600 tabular-nums dark:text-zinc-400">
                  {formatDate(entry.date)}
                </time>
                <p className="mt-1 text-amber-700 dark:text-amber-400">{entry.product}</p>
              </div>
              <div className="mt-4 min-w-0 sm:mt-0">
                <h2 className="font-display text-3xl leading-tight">{entry.title}</h2>
                <ul className="mt-4 list-disc space-y-2 pl-5 text-pretty text-zinc-600 marker:text-zinc-400 dark:text-zinc-400 dark:marker:text-zinc-600">
                  {entry.changes.map(change => (
                    <li key={change}>{change}</li>
                  ))}
                </ul>
                {entry.version && (
                  <p className="mt-5 text-sm">
                    <a href={releaseURL(entry.version)} className={link}>
                      Release notes on GitHub
                    </a>
                  </p>
                )}
              </div>
            </li>
          ))}
        </ol>
      </section>
    </>
  );
}
