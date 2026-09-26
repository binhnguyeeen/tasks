import { Legal } from "@/components/legal";
import { address } from "@/lib/contact";

export default function Privacy() {
  return (
    <Legal title="Privacy Policy" updated="26 September 2026">
      <p>
        Tasks has two parts: a Mac menu bar app, and a connector that lets Claude (by Anthropic) work with your Google
        Tasks. This policy explains what data each part and this website touch, and what happens to it.
      </p>

      <h2>Who runs Tasks</h2>
      <p>
        Tasks is made by Binh Nguyen, an individual developer. It isn’t a company. You can reach me through{" "}
        <a href="https://github.com/binhnguyeeen/tasks/issues">GitHub issues</a> or by email at{" "}
        <a href={`mailto:${address()}`}>{address()}</a>.
      </p>

      <h2>What we access</h2>
      <ul>
        <li>
          <strong>Your Google Tasks:</strong> task lists and tasks (titles, notes, due dates, completion status,
          subtasks), through the <code>https://www.googleapis.com/auth/tasks</code> permission.
        </li>
        <li>
          <strong>Your Google account email address and ID.</strong> The Mac app shows the email in Settings so you can
          see which account is signed in. The connector uses it to check that you’re allowed to use it.
        </li>
      </ul>
      <p>
        That’s all. Tasks doesn’t access your Gmail, Calendar, contacts, files, name, photo or any other Google data.
      </p>

      <h2>How we use it</h2>
      <ul>
        <li>
          The Mac app shows your tasks and makes the changes you ask for: adding, editing, completing, moving and
          deleting tasks and lists.
        </li>
        <li>
          The connector gives Claude your tasks when you or a Claude routine you set up asks for them. It also makes the
          changes Claude is asked to make: adding, editing and completing tasks. The connector can’t delete anything.
        </li>
      </ul>
      <p>
        Your data is used only to provide these features. It’s never sold, never used for advertising, and never used to
        train AI models by Tasks.
      </p>

      <h2>What we store</h2>
      <ul>
        <li>
          <strong>Mac app:</strong> your Google sign-in token and email address are stored in the macOS Keychain on your
          Mac. Your tasks are held in memory while the app runs and aren’t saved to disk. The app also saves a few
          preferences on your Mac: which list you last opened, sort order, whether completed tasks are shown, the list
          colors you picked and the inspector width. These refer to lists by Google’s random ID, not by name, and
          contain no task content.
        </li>
        <li>
          <strong>Connector:</strong> your Google sign-in tokens, Google account ID and email are stored in Cloudflare’s
          encrypted key-value storage, so the connector can reach Google Tasks on your behalf. Task content passes
          through the connector but isn’t stored.
        </li>
        <li>
          <strong>This website:</strong> nothing about you. See the next section for the one setting it remembers.
        </li>
      </ul>
      <p>There are no analytics, tracking or advertising tools in the app, the connector or this website.</p>

      <h2>Cookies and local storage</h2>
      <ul>
        <li>
          <strong>This website</strong> sets no cookies. It saves your light or dark choice in your browser’s local
          storage (under the key <code>theme</code>) so the site looks the same next time. It never leaves your browser.
        </li>
        <li>
          <strong>The connector</strong> sets cookies on its own address only while you connect it to Claude: two
          security cookies that expire after 10 minutes, and one that remembers for 30 days that you approved Claude, so
          you aren’t asked again. They’re needed for signing in and aren’t used for anything else.
        </li>
        <li>The Mac app doesn’t use cookies.</li>
      </ul>
      <p>Because all of these are needed for the site or sign-in to work, there’s no cookie banner.</p>

      <h2>Who else sees it</h2>
      <ul>
        <li>
          <strong>Google</strong>, which hosts your tasks.
        </li>
        <li>
          <strong>Cloudflare</strong>, which runs the connector.
        </li>
        <li>
          <strong>GitHub</strong>, which hosts this website. Like any web host, it may log your IP address when you visit.{" "}
          <a href="https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement">
            GitHub’s privacy statement
          </a>{" "}
          covers that.
        </li>
        <li>
          <strong>Anthropic</strong>, when you use the connector: the tasks Claude reads become part of your Claude
          conversation, and <a href="https://www.anthropic.com/legal/privacy">Anthropic’s privacy policy</a> covers
          them.
        </li>
      </ul>
      <p>We don’t share your data with anyone else, unless the law requires it.</p>

      <h2>Google API Services User Data Policy</h2>
      <p>
        Tasks’ use and transfer to any other app of information received from Google APIs will adhere to the{" "}
        <a href="https://developers.google.com/terms/api-services-user-data-policy">
          Google API Services User Data Policy
        </a>
        , including the Limited Use requirements.
      </p>

      <h2>Removing access and deleting your data</h2>
      <ul>
        <li>
          Remove Tasks’ access at any time at{" "}
          <a href="https://myaccount.google.com/permissions">myaccount.google.com/permissions</a>. Once you do, any
          stored tokens stop working.
        </li>
        <li>
          <strong>Mac app:</strong> Sign Out in Settings deletes the token and email from your Keychain. To also remove
          the saved preferences, delete the app and the folder <code>~/Library/Containers/com.binhnguyen.tasks</code>.
        </li>
        <li>
          <strong>Connector:</strong> disconnecting it in Claude’s settings stops Claude from using it. To have the
          connector’s stored tokens, ID and email deleted, open an issue on{" "}
          <a href="https://github.com/binhnguyeeen/tasks/issues">GitHub</a> or email{" "}
          <a href={`mailto:${address()}`}>{address()}</a>. I’ll delete them within 30 days and tell you when it’s done.
        </li>
        <li>
          Your tasks themselves live in Google Tasks. Deleting them there is up to you and Google, not Tasks.
        </li>
      </ul>

      <h2>Self-hosted copies</h2>
      <p>
        The code is open source. If someone else runs their own copy, they’re responsible for how their copy handles
        data, and this policy doesn’t apply to it.
      </p>

      <h2>Children</h2>
      <p>
        Tasks isn’t meant for children. You need to be at least 13, or older if your country requires it for a Google
        account, to use it. Tasks doesn’t knowingly collect children’s data; if you think a child has used it, get in
        touch and their data will be deleted.
      </p>

      <h2>Changes</h2>
      <p>If this policy changes, the new version will be posted here with a new date.</p>

      <h2>Contact</h2>
      <p>
        Questions or requests: <a href="https://github.com/binhnguyeeen/tasks/issues">open an issue on GitHub</a> or
        email <a href={`mailto:${address()}`}>{address()}</a>.
      </p>
    </Legal>
  );
}
