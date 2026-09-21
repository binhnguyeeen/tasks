import type { ReactNode } from "react";

export function Legal({ title, updated, children }: { title: string; updated: string; children: ReactNode }) {
  return (
    <section className="px-5 py-16">
      <article className="legal mx-auto max-w-[38rem] text-[14px] leading-[1.5] text-black dark:text-zinc-100">
        <h1 className="mb-1 text-[22px] font-semibold leading-tight">{title}</h1>
        <p className="mb-5 text-[13px] text-zinc-500">Last updated {updated}</p>
        {children}
      </article>
    </section>
  );
}
