import type { ReactNode } from "react";

export function PageIntro({
  eyebrow,
  title,
  children,
}: {
  eyebrow: string;
  title: ReactNode;
  children?: ReactNode;
}) {
  return (
    <section className="relative overflow-hidden px-5 pb-14 pt-20">
      <div
        aria-hidden="true"
        className="pointer-events-none absolute inset-x-0 -top-48 mx-auto h-[360px] max-w-3xl rounded-full bg-gradient-to-b from-sky-200/60 via-violet-200/30 to-transparent blur-3xl dark:from-sky-500/15 dark:via-violet-500/10"
      />
      <div className="relative mx-auto max-w-3xl text-center">
        <p className="text-sm font-medium text-amber-600 dark:text-amber-400">{eyebrow}</p>
        <h1 className="font-display mt-2 text-balance text-5xl leading-[1.05] sm:text-6xl">{title}</h1>
        {children && (
          <p className="mx-auto mt-5 max-w-xl text-pretty text-lg text-zinc-500 dark:text-zinc-400">{children}</p>
        )}
      </div>
    </section>
  );
}
