import type { ReactNode, RefObject } from "react";
import { ThemeProvider } from "next-themes";
import { SiteNav } from "@/components/site-nav";
import { SiteFooter } from "@/components/site-footer";
import { CursorFollower } from "@/components/cursor";
import { FloatingNav } from "@/components/floating-nav";
import { MailPanel } from "@/components/mail-panel";

export function PageShell({
  current,
  mainRef,
  children,
}: {
  current: string;
  mainRef?: RefObject<HTMLElement | null>;
  children: ReactNode;
}) {
  return (
    <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
      <div className="min-h-screen bg-white text-zinc-900 dark:bg-black dark:text-zinc-100">
        <CursorFollower />
        <SiteNav current={current} />
        <main ref={mainRef} tabIndex={-1} className="outline-none">
          {children}
        </main>
        <FloatingNav current={current} />
        <SiteFooter />
        <MailPanel />
      </div>
    </ThemeProvider>
  );
}
