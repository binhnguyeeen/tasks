import { Step, Steps } from "@/components/steps";
import { macDownloadURL } from "@/lib/download";

const base = import.meta.env.BASE_URL;

const strong = "font-medium text-zinc-700 dark:text-zinc-200";
const link = "text-sky-700 underline decoration-sky-700/40 underline-offset-4 hover:decoration-current dark:text-sky-400 dark:decoration-sky-400/40";

export function MacInstall() {
  return (
    <>
      <div className="flex flex-col items-center gap-4 pb-12 text-center">
        <img src={`${base}icon.png`} alt="Tasks app icon" className="size-24 drop-shadow-2xl" />
        <a
          href={macDownloadURL}
          className="mt-4 inline-flex rounded-full bg-zinc-900 px-6 py-3 text-white transition hover:bg-zinc-700 dark:bg-white dark:text-zinc-900 dark:hover:bg-zinc-200"
        >
          Download Tasks.zip
        </a>
        <p className="text-xs text-zinc-500 dark:text-zinc-400">
          Free · macOS 27 or later · Apple silicon ·{" "}
          <a
            href="https://github.com/binhnguyeeen/tasks/releases"
            className="underline underline-offset-2 hover:text-zinc-900 dark:hover:text-zinc-100"
          >
            All releases
          </a>
        </p>
      </div>

      <Steps>
        <Step level={3} n={1} title="Download and unzip">
          <p>
            Download <em>Tasks.zip</em> with the button above and open it. Drag{" "}
            <strong className={strong}>Tasks</strong> into your <strong className={strong}>Applications</strong>{" "}
            folder.
          </p>
        </Step>
        <Step level={3} n={2} title="Open it once">
          <p>
            Open Tasks. macOS says it can’t check the app for malicious software. Click{" "}
            <strong className={strong}>Done</strong>.
          </p>
        </Step>
        <Step level={3} n={3} title="Allow it">
          <p>
            Open <strong className={strong}>System Settings → Privacy &amp; Security</strong>, scroll down, and click{" "}
            <strong className={strong}>Open Anyway</strong> next to the message about Tasks. Confirm with{" "}
            <strong className={strong}>Open Anyway</strong> and your password. You only do this once.
          </p>
        </Step>
        <Step level={3} n={4} title="Sign in">
          <p>
            The Tasks window opens. Click <strong className={strong}>Sign In with Google…</strong>, then{" "}
            <strong className={strong}>Continue</strong> when macOS asks to use accounts.google.com, and pick your
            account. Google warns that it hasn’t verified the app: click <strong className={strong}>Advanced</strong>,
            then <strong className={strong}>Go to Tasks (unsafe)</strong>. Leave the Google Tasks permission ticked and
            continue. Tasks only asks for your Google Tasks and your email address.
          </p>
        </Step>
        <Step level={3} n={5} title="Done">
          <p>
            Your tasks due today and overdue now show in the menu bar, and the full window has everything else. Tasks
            opens at login; turn that off in <strong className={strong}>Settings</strong>. Closing the window (⌘Q or
            ⌘W) keeps Tasks in the menu bar; <strong className={strong}>Quit Tasks</strong> in its dropdown really
            quits.
          </p>
        </Step>
      </Steps>

      <div className="mx-auto mt-4 grid max-w-3xl gap-8 rounded-3xl bg-zinc-50 p-8 dark:bg-zinc-950 sm:grid-cols-2 sm:p-10">
        <div>
          <h3 className="font-display text-3xl leading-tight">Why the extra steps?</h3>
          <p className="mt-3 text-zinc-500 dark:text-zinc-400">
            Tasks is a free personal project. It isn’t notarized by Apple or verified by Google, because both cost
            money and paperwork that don’t make sense yet. The source code is public, so anyone can check what it
            does.
          </p>
        </div>
        <div>
          <h3 className="font-display text-3xl leading-tight">Updating and removing</h3>
          <ul className="mt-3 space-y-3 text-zinc-500 dark:text-zinc-400">
            <li>
              <strong className={strong}>Update:</strong> download the new release and replace the old app in
              Applications.
            </li>
            <li>
              <strong className={strong}>Remove:</strong> turn off <strong className={strong}>Open at Login</strong> in
              Settings, choose <strong className={strong}>Quit Tasks</strong> in the menu bar dropdown, drag Tasks to the
              Trash, delete the folder <em>~/Library/Containers/com.binhnguyen.tasks</em>, and remove its access at{" "}
              <a href="https://myaccount.google.com/permissions" className={link}>
                myaccount.google.com/permissions
              </a>
              .
            </li>
          </ul>
        </div>
      </div>
    </>
  );
}
