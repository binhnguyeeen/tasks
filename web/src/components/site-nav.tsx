import { BookOpen, CircleCheck, HelpCircle, Sparkles } from "lucide-react";
import { DiscreteTabs } from "@/components/watermelon/discrete-tabs";
import { SwitchMode } from "@/components/watermelon/switch-mode";

const base = import.meta.env.BASE_URL;

const tabs = [
  { id: "index", href: base, icon: <CircleCheck size={16} />, label: "Tasks", activeColor: "text-sky-600 dark:text-sky-400" },
  { id: "guide", href: `${base}guide.html`, icon: <BookOpen size={16} />, label: "Guide", activeColor: "text-amber-600 dark:text-amber-400" },
  { id: "claude", href: `${base}claude.html`, icon: <Sparkles size={16} />, label: "Claude", activeColor: "text-orange-600 dark:text-orange-400" },
  { id: "help", href: `${base}help.html`, icon: <HelpCircle size={16} />, label: "Help", activeColor: "text-zinc-600 dark:text-zinc-300" },
];

export function SiteNav({ current }: { current: string }) {
  return (
    <header className="sticky top-0 z-40 border-b border-black/5 bg-white/70 backdrop-blur-xl dark:border-white/10 dark:bg-black/60">
      <div className="mx-auto flex h-16 max-w-6xl items-center justify-between gap-4 px-5">
        <a href={base} className="flex shrink-0 items-center gap-2.5 font-semibold tracking-tight">
          <img src={`${base}icon.png`} alt="" className="size-8" />
          <span className="text-lg">Tasks</span>
        </a>
        <div className="hidden sm:block">
          <DiscreteTabs tabs={tabs} activeTab={current} />
        </div>
        <div className="scale-[0.42] origin-right">
          <SwitchMode />
        </div>
      </div>
    </header>
  );
}
