import type { ReactNode } from "react";
import { ThemeProvider } from "next-themes";
import { SiteNav } from "@/components/site-nav";
import { SiteFooter } from "@/components/site-footer";
import { CursorFollower } from "@/components/cursor";
import { FloatingNav } from "@/components/floating-nav";

export function PageShell({ current, children }: { current: string; children: ReactNode }) {
  return (
    <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
      <div className="min-h-screen bg-white text-zinc-900 dark:bg-black dark:text-zinc-100">
        <CursorFollower />
        <SiteNav current={current} />
        <main>{children}</main>
        <FloatingNav current={current} />
        <SiteFooter />
      </div>
    </ThemeProvider>
  );
}
