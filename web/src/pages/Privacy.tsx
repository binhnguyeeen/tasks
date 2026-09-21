import { Legal } from "@/components/legal";
import { address } from "@/lib/contact";

export default function Privacy() {
  return (
    <Legal title="Privacy Policy" updated="19 September 2026">
      <p>
        Tasks has two parts: a Mac menu bar app, and a connector that lets Claude (by Anthropic) work with your Google
        Tasks. This policy explains what data each part touches and what happens to it.
      </p>

      <h2>What we access</h2>
      <ul>
        <li>
          <strong>Your Google Tasks:</strong> task lists and tasks (titles, notes, due dates, completion status,
          subtasks), through the <code>https://www.googleapis.com/auth/tasks</code> permission.
        </li>
        <li>
          <strong>Your Google account email and ID</strong> (connector only), so it can check that you’re allowed to use
          it.
        </li>
      </ul>
      <p>Tasks doesn’t access your Gmail, Calendar, contacts, files or any other Google data.</p>

      <h2>How we use it</h2>
      <ul>
        <li>
          The Mac app shows your tasks and makes the changes you ask for: adding, editing, completing and deleting tasks
          and lists.
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
          <strong>Mac app:</strong> your Google sign-in token is stored in the macOS Keychain on your Mac. Tasks are
          held in memory while the app runs and aren’t saved to disk.
        </li>
        <li>
          <strong>Connector:</strong> your Google sign-in tokens, Google account ID and email are stored in Cloudflare’s
          encrypted key-value storage, so the connector can reach Google Tasks on your behalf. Task content passes
          through the connector but isn’t stored.
        </li>
      </ul>
      <p>There are no analytics, tracking or advertising SDKs in either part.</p>

      <h2>Who else sees it</h2>
      <ul>
        <li>
          <strong>Google</strong>, which hosts your tasks.
        </li>
        <li>
          <strong>Cloudflare</strong>, which runs the connector.
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

      <h2>Removing access and deleting data</h2>
      <ul>
        <li>
          Remove Tasks’ access at any time at{" "}
          <a href="https://myaccount.google.com/permissions">myaccount.google.com/permissions</a>. Once you do, the
          stored tokens stop working.
        </li>
        <li>
          In the Mac app, signing out deletes the token from your Keychain. Deleting the app has the same effect.
        </li>
        <li>
          Disconnecting the connector in Claude’s settings stops Claude from using it. To have the connector’s stored
          tokens deleted, open an issue on <a href="https://github.com/binhnguyeeen/tasks/issues">GitHub</a>.
        </li>
      </ul>

      <h2>Self-hosted copies</h2>
      <p>
        The code is open source. If someone else runs their own copy, they’re responsible for how their copy handles
        data, and this policy doesn’t apply to it.
      </p>

      <h2>Children</h2>
      <p>Tasks isn’t meant for children under 13 and doesn’t knowingly collect their data.</p>

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
