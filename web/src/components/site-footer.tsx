const base = import.meta.env.BASE_URL;

export function SiteFooter() {
  return (
    <footer className="border-t border-black/5 bg-zinc-50 px-5 py-8 text-xs text-zinc-600 dark:border-white/10 dark:text-zinc-400 dark:bg-zinc-950">
      <div className="mx-auto flex max-w-6xl flex-col gap-3">
        <div className="flex flex-wrap gap-x-6 gap-y-2">
          <a href={`${base}guide.html#install-mac`} className="hover:underline">Install on Mac</a>
          <a href={`${base}help.html`} className="hover:underline">Help</a>
          <a href={`${base}privacy.html`} className="hover:underline">Privacy Policy</a>
          <a href={`${base}terms.html`} className="hover:underline">Terms of Service</a>
          <a href="https://github.com/binhnguyeeen/tasks" className="hover:underline">Source on GitHub</a>
        </div>
        <p>
          © 2026 Binh Nguyen. Tasks is an independent project and isn’t made, endorsed or reviewed by Google, Apple or Anthropic. Google Tasks is a
          trademark of Google LLC.
        </p>
      </div>
    </footer>
  );
}
