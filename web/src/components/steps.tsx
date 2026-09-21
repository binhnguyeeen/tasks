import type { ReactNode } from "react";

export function Steps({ children }: { children: ReactNode }) {
  return <ol className="mx-auto grid max-w-3xl gap-4">{children}</ol>;
}

export function Step({ n, title, children }: { n: number; title: string; children: ReactNode }) {
  return (
    <li className="rounded-3xl bg-zinc-50 p-7 dark:bg-zinc-950 sm:p-8">
      <div className="flex items-baseline gap-4">
        <span className="font-display shrink-0 text-2xl text-zinc-300 tabular-nums dark:text-zinc-700">
          {String(n).padStart(2, "0")}
        </span>
        <div className="min-w-0 flex-1">
          <h2 className="font-display text-2xl leading-tight sm:text-3xl">{title}</h2>
          <div className="mt-3 space-y-3 text-zinc-500 dark:text-zinc-400">{children}</div>
        </div>
      </div>
    </li>
  );
}
