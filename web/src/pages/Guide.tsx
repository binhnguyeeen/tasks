const sections = [
  { title: "Install the Mac app", body: "Download, the one-time Open Anyway step, and signing in with Google." },
  { title: "Connect Claude", body: "Add the connector in Claude, sign in, and check that it went through." },
  { title: "Everyday use", body: "Quick add with dates, smart lists, subtasks, search, and what Claude can do." },
];

export default function Guide() {
  return (
    <>
      <section className="px-5 pb-16 pt-20">
        <div className="mx-auto max-w-3xl text-center">
          <p className="text-sm font-medium text-amber-600">Guide</p>
          <h1 className="font-display mt-2 text-6xl leading-[1.02]">Everything, step by step.</h1>
          <p className="mx-auto mt-5 max-w-lg text-pretty text-lg text-zinc-500 dark:text-zinc-400">
            Being written while the Mac app is built. Here's what it will cover.
          </p>
        </div>
      </section>

      <section className="px-5 pb-28">
        <div className="mx-auto grid max-w-4xl gap-4">
          {sections.map(s => (
            <article key={s.title} className="rounded-3xl bg-zinc-50 p-8 dark:bg-zinc-950">
              <h2 className="font-display text-3xl leading-tight">{s.title}</h2>
              <p className="mt-3 text-zinc-500 dark:text-zinc-400">{s.body}</p>
              <p className="mt-6 inline-flex rounded-full border border-black/10 px-3 py-1 text-xs text-zinc-400 dark:border-white/15">
                Coming soon
              </p>
            </article>
          ))}
        </div>
      </section>
    </>
  );
}
