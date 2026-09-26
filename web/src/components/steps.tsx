import type { ReactNode } from "react";

export function Steps({ children }: { children: ReactNode }) {
  return <ol className="mx-auto grid max-w-3xl gap-4">{children}</ol>;
}

export function Step({
  n,
  title,
  level = 2,
  children,
}: {
  n: number;
  title: string;
  level?: 2 | 3;
  children: ReactNode;
}) {
  const Heading = level === 2 ? "h2" : "h3";
  return (
    <li className="rounded-3xl bg-zinc-50 p-7 dark:bg-zinc-950 sm:p-8">
      <div className="flex items-baseline gap-4">
        <span aria-hidden="true" className="font-display shrink-0 text-2xl text-zinc-500 tabular-nums">
          {String(n).padStart(2, "0")}
        </span>
        <div className="min-w-0 flex-1">
          <Heading className="font-display text-2xl leading-tight sm:text-3xl">{title}</Heading>
          <div className="mt-3 space-y-3 text-zinc-500 dark:text-zinc-400">{children}</div>
        </div>
      </div>
    </li>
  );
}
