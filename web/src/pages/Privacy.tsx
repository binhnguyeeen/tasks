import { Clause, Item, Legal } from "@/components/legal";
import { address } from "@/lib/contact";

export default function Privacy() {
  return (
    <Legal
      title="Tasks Privacy Policy"
      scope="For the Tasks Mac app, the Tasks connector for Claude, and this website"
      updated="26 September 2026"
      notice={
        <p>
          Please read this policy carefully. It explains what data the Tasks Mac app, the Tasks connector and this
          website touch, what happens to that data, and how to have it deleted.
        </p>
      }
    >
      <Clause n={1} title="Who Runs Tasks">
        <p>
          Tasks has two parts: a Mac menu bar app, and a connector that lets Claude (by Anthropic) work with your Google
          Tasks. Tasks is made by Binh Nguyen, an individual developer. It isn’t a company. You can reach me through{" "}
          <a href="https://github.com/binhnguyeeen/tasks/issues">GitHub issues</a> or by email at{" "}
          <a href={`mailto:${address()}`}>{address()}</a>.
        </p>
      </Clause>

      <Clause n={2} title="What We Access">
        <Item letter="A">
          Your Google Tasks: task lists and tasks (titles, notes, due dates, completion status, subtasks), through the{" "}
          <code>https://www.googleapis.com/auth/tasks</code> permission.
        </Item>
        <Item letter="B">
          Your Google account email address and ID. The Mac app shows the email in Settings so you can see which account
          is signed in. The connector uses it to check that you’re allowed to use it.
        </Item>
        <Item letter="C">
          That’s all. Tasks doesn’t access your Gmail, Calendar, contacts, files, name, photo or any other Google data.
        </Item>
      </Clause>

      <Clause n={3} title="How We Use It">
        <Item letter="A">
          The Mac app shows your tasks and makes the changes you ask for: adding, editing, completing, moving and
          deleting tasks and lists.
        </Item>
        <Item letter="B">
          The connector gives Claude your tasks when you or a Claude routine you set up asks for them. It also makes the
          changes Claude is asked to make: adding, editing and completing tasks. The connector can’t delete anything.
        </Item>
        <Item letter="C">
          Your data is used only to provide these features. It’s never sold, never used for advertising, and never used
          to train AI models by Tasks.
        </Item>
      </Clause>

      <Clause n={4} title="What We Store">
        <Item letter="A">
          Mac app. Your Google sign-in token and email address are stored in the macOS Keychain on your Mac. Your tasks
          are held in memory while the app runs and aren’t saved to disk. The app also saves a few preferences on your
          Mac: which list you last opened, sort order, whether completed tasks are shown, the list colors you picked and
          the inspector width. These refer to lists by Google’s random ID, not by name, and contain no task content.
        </Item>
        <Item letter="B">
          Connector. Your Google sign-in tokens, Google account ID and email are stored in Cloudflare’s encrypted
          key-value storage, so the connector can reach Google Tasks on your behalf. Task content passes through the
          connector but isn’t stored.
        </Item>
        <Item letter="C">This website. Nothing about you. Section 5 describes the one setting it remembers.</Item>
        <Item letter="D">
          There are no analytics, tracking or advertising tools in the app, the connector or this website.
        </Item>
      </Clause>

      <Clause n={5} title="Cookies and Local Storage">
        <Item letter="A">
          This website sets no cookies. It saves your light or dark choice in your browser’s local storage (under the
          key <code>theme</code>) so the site looks the same next time. It never leaves your browser.
        </Item>
        <Item letter="B">
          The connector sets cookies on its own address only while you connect it to Claude: two security cookies that
          expire after 10 minutes, and one that remembers for 30 days that you approved Claude, so you aren’t asked
          again. They’re needed for signing in and aren’t used for anything else.
        </Item>
        <Item letter="C">The Mac app doesn’t use cookies.</Item>
        <Item letter="D">
          Because all of these are needed for the site or sign-in to work, there’s no cookie banner.
        </Item>
      </Clause>

      <Clause n={6} title="Who Else Sees It">
        <Item letter="A">Google, which hosts your tasks.</Item>
        <Item letter="B">Cloudflare, which runs the connector.</Item>
        <Item letter="C">
          GitHub, which hosts this website. Like any web host, it may log your IP address when you visit.{" "}
          <a href="https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement">
            GitHub’s privacy statement
          </a>{" "}
          covers that.
        </Item>
        <Item letter="D">
          Anthropic, when you use the connector: the tasks Claude reads become part of your Claude conversation, and{" "}
          <a href="https://www.anthropic.com/legal/privacy">Anthropic’s privacy policy</a> covers them.
        </Item>
        <Item letter="E">We don’t share your data with anyone else, unless the law requires it.</Item>
      </Clause>

      <Clause n={7} title="Google API Services User Data Policy">
        <p>
          Tasks’ use and transfer to any other app of information received from Google APIs will adhere to the{" "}
          <a href="https://developers.google.com/terms/api-services-user-data-policy">
            Google API Services User Data Policy
          </a>
          , including the Limited Use requirements.
        </p>
      </Clause>

      <Clause n={8} title="Removing Access and Deleting Your Data">
        <Item letter="A">
          Remove Tasks’ access at any time at{" "}
          <a href="https://myaccount.google.com/permissions">myaccount.google.com/permissions</a>. Once you do, any
          stored tokens stop working.
        </Item>
        <Item letter="B">
          Mac app. Sign Out in Settings deletes the token and email from your Keychain. To also remove the saved
          preferences, delete the app and the folder <code>~/Library/Containers/com.binhnguyen.tasks</code>.
        </Item>
        <Item letter="C">
          Connector. Disconnecting it in Claude’s settings stops Claude from using it. To have the connector’s stored
          tokens, ID and email deleted, open an issue on <a href="https://github.com/binhnguyeeen/tasks/issues">GitHub</a>{" "}
          or email <a href={`mailto:${address()}`}>{address()}</a>. I’ll delete them within 30 days and tell you when
          it’s done.
        </Item>
        <Item letter="D">
          Your tasks themselves live in Google Tasks. Deleting them there is up to you and Google, not Tasks.
        </Item>
      </Clause>

      <Clause n={9} title="Self-Hosted Copies">
        <p>
          The code is open source. If someone else runs their own copy, they’re responsible for how their copy handles
          data, and this policy doesn’t apply to it.
        </p>
      </Clause>

      <Clause n={10} title="Children">
        <p>
          Tasks isn’t meant for children. You need to be at least 13, or older if your country requires it for a Google
          account, to use it. Tasks doesn’t knowingly collect children’s data; if you think a child has used it, get in
          touch and their data will be deleted.
        </p>
      </Clause>

      <Clause n={11} title="Changes">
        <p>If this policy changes, the new version will be posted here with a new date.</p>
      </Clause>

      <Clause n={12} title="Contact">
        <p>
          Questions or requests: <a href="https://github.com/binhnguyeeen/tasks/issues">open an issue on GitHub</a> or
          email <a href={`mailto:${address()}`}>{address()}</a>.
        </p>
      </Clause>
    </Legal>
  );
}
