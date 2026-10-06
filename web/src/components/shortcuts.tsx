const keyNames: Record<string, string> = {
  "⌘": "Command",
  "⇧": "Shift",
  "⌃": "Control",
  "⌥": "Option",
  "⌫": "Delete",
  "↩": "Return",
};

interface Shortcut {
  keys: string[];
  action: string;
}

const groups: { title: string; shortcuts: Shortcut[] }[] = [
  {
    title: "In the window",
    shortcuts: [
      { keys: ["⌘", "N"], action: "New task" },
      { keys: ["⇧", "⌘", "N"], action: "New list" },
      { keys: ["⌘", "F"], action: "Search every list" },
      { keys: ["Space"], action: "Tick off the selected task" },
      { keys: ["⌘", "⌫"], action: "Delete the selected task, after asking" },
      { keys: ["⌘", "I"], action: "Show or hide the inspector" },
      { keys: ["⌃", "⌘", "S"], action: "Show or hide the sidebar" },
      { keys: ["⌘", "R"], action: "Refresh from Google" },
      { keys: ["⌘", ","], action: "Settings" },
      { keys: ["⌘", "W"], action: "Close the window (⌘Q does the same)" },
    ],
  },
  {
    title: "In the menu bar",
    shortcuts: [
      { keys: ["↩"], action: "Add the task you typed" },
      { keys: ["⌘", "O"], action: "Open the Tasks window" },
      { keys: ["⌘", "R"], action: "Refresh from Google" },
    ],
  },
];

function Keys({ keys }: { keys: string[] }) {
  return (
    <kbd className="flex shrink-0 gap-1 font-sans">
      <span className="sr-only">{keys.map(key => keyNames[key] ?? key).join(" ")}</span>
      {keys.map(key => (
        <span
          key={key}
          aria-hidden="true"
          className="flex h-7 min-w-7 items-center justify-center rounded-lg border border-black/10 bg-white px-2 text-sm text-zinc-700 shadow-[0_1px_0_rgb(0_0_0/0.06)] dark:border-white/15 dark:bg-zinc-900 dark:text-zinc-200"
        >
          {key}
        </span>
      ))}
    </kbd>
  );
}

export function Shortcuts() {
  return (
    <div className="mx-auto grid max-w-4xl items-start gap-4 md:grid-cols-[3fr_2fr]">
      {groups.map(group => (
        <section key={group.title} className="rounded-3xl bg-zinc-50 p-7 sm:p-8 dark:bg-zinc-950">
          <h3 className="text-base font-semibold">{group.title}</h3>
          <dl className="mt-4 divide-y divide-black/5 dark:divide-white/10">
            {group.shortcuts.map(shortcut => (
              <div key={shortcut.action} className="flex items-center justify-between gap-6 py-3">
                <dt className="text-pretty text-zinc-600 dark:text-zinc-400">{shortcut.action}</dt>
                <dd>
                  <Keys keys={shortcut.keys} />
                </dd>
              </div>
            ))}
          </dl>
        </section>
      ))}
    </div>
  );
}
