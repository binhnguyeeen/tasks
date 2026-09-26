import type { ReactNode } from "react";

export function Legal({
  title,
  scope,
  updated,
  notice,
  children,
}: {
  title: string;
  scope: string;
  updated: string;
  notice: ReactNode;
  children: ReactNode;
}) {
  return (
    <section className="bg-white px-5 py-16 text-black">
      <article className="legal mx-auto max-w-[44rem]">
        <h1>
          BINH NGUYEN
          <br />
          {title.toUpperCase()}
        </h1>
        <p className="legal-strong">{scope}</p>
        <p>Last updated {updated}</p>
        <div className="legal-notice">{notice}</div>
        {children}
      </article>
    </section>
  );
}

export function Clause({ n, title, children }: { n: number; title: string; children: ReactNode }) {
  return (
    <section>
      <h2>
        {n}. {title}.
      </h2>
      {children}
    </section>
  );
}

export function Item({ letter, children }: { letter: string; children: ReactNode }) {
  return (
    <p>
      {letter}. {children}
    </p>
  );
}
