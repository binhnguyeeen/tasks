import { useEffect, useRef, useState } from "react";
import { AnimatePresence, MotionConfig, motion } from "motion/react";
import { useTheme } from "next-themes";
import { BookOpen, CircleCheck, HelpCircle, Menu, Moon, Sparkles, Sun, X } from "lucide-react";

const base = import.meta.env.BASE_URL;

const links = [
  { id: "index", label: "Tasks", href: base, icon: CircleCheck },
  { id: "guide", label: "Guide", href: `${base}guide.html`, icon: BookOpen },
  { id: "claude", label: "Claude", href: `${base}claude.html`, icon: Sparkles },
  { id: "help", label: "Help", href: `${base}help.html`, icon: HelpCircle },
];

export function FloatingNav({ current }: { current: string }) {
  const [open, setOpen] = useState(false);
  const wrap = useRef<HTMLDivElement>(null);
  const { resolvedTheme, setTheme } = useTheme();

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && setOpen(false);
    const onDown = (e: PointerEvent) => {
      if (!wrap.current?.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener("keydown", onKey);
    document.addEventListener("pointerdown", onDown);
    return () => {
      document.removeEventListener("keydown", onKey);
      document.removeEventListener("pointerdown", onDown);
    };
  }, [open]);

  return (
    <div ref={wrap} className="fixed bottom-5 right-5 z-50 flex flex-col items-end gap-3 md:hidden">
      <MotionConfig transition={{ type: "spring", stiffness: 300, damping: 26 }}>
        <AnimatePresence>
          {open && (
            <motion.nav
              initial={{ opacity: 0, scale: 0.9, y: 12 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.9, y: 12 }}
              style={{ transformOrigin: "bottom right" }}
              className="w-56 overflow-hidden rounded-3xl border border-black/5 bg-white/90 p-2 shadow-xl backdrop-blur-xl dark:border-white/10 dark:bg-zinc-900/90"
            >
              {links.map(link => {
                const Icon = link.icon;
                const active = link.id === current;
                return (
                  <a
                    key={link.id}
                    href={link.href}
                    aria-current={active ? "page" : undefined}
                    className={`flex items-center gap-3 rounded-2xl px-3 py-2.5 text-sm ${
                      active
                        ? "bg-zinc-900 text-white dark:bg-white dark:text-zinc-900"
                        : "text-zinc-700 hover:bg-zinc-100 dark:text-zinc-200 dark:hover:bg-zinc-800"
                    }`}
                  >
                    <Icon size={16} />
                    {link.label}
                  </a>
                );
              })}
              <button
                onClick={() => setTheme(resolvedTheme === "dark" ? "light" : "dark")}
                className="mt-1 flex w-full items-center gap-3 border-t border-black/5 px-3 pb-1 pt-3 text-sm text-zinc-700 dark:border-white/10 dark:text-zinc-200"
              >
                {resolvedTheme === "dark" ? <Sun size={16} /> : <Moon size={16} />}
                {resolvedTheme === "dark" ? "Light mode" : "Dark mode"}
              </button>
            </motion.nav>
          )}
        </AnimatePresence>

        <motion.button
          onClick={() => setOpen(v => !v)}
          whileTap={{ scale: 0.94 }}
          aria-expanded={open}
          aria-label={open ? "Close menu" : "Open menu"}
          className="squircle flex size-14 items-center justify-center bg-zinc-900 text-white shadow-xl ring-1 ring-black/10 dark:bg-white dark:text-zinc-900 dark:ring-white/20"
        >
          <AnimatePresence mode="wait" initial={false}>
            <motion.span
              key={open ? "close" : "open"}
              initial={{ rotate: -90, opacity: 0 }}
              animate={{ rotate: 0, opacity: 1 }}
              exit={{ rotate: 90, opacity: 0 }}
            >
              {open ? <X size={22} /> : <Menu size={22} />}
            </motion.span>
          </AnimatePresence>
        </motion.button>
      </MotionConfig>
    </div>
  );
}
