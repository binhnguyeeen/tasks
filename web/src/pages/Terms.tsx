import { Legal } from "@/components/legal";
import { address } from "@/lib/contact";

export default function Terms() {
  return (
    <Legal title="Terms of Service" updated="26 September 2026">
      <p>By using Tasks (the Mac app or the Claude connector), you agree to these terms.</p>

      <h2>A personal project</h2>
      <p>
        Tasks is a personal, open-source project made by Binh Nguyen, an individual developer (“the developer”). The
        hosted connector is only open to Google accounts the developer has allowed. Anyone may run their own copy under
        the <a href="https://github.com/binhnguyeeen/tasks/blob/main/LICENSE">MIT license</a>.
      </p>

      <h2>Free, with no payments</h2>
      <p>
        Tasks is free. There are no fees, subscriptions, in-app purchases or ads, so there’s nothing to refund. If that
        ever changes, the price will be shown clearly before you pay anything, and these terms will be updated first.
      </p>

      <h2>Who can use it</h2>
      <p>
        You need to be at least 13, or older if your country requires it for a Google account. Use Tasks only with a
        Google account you’re allowed to use.
      </p>

      <h2>No warranty</h2>
      <p>
        Tasks is provided “as is”, without warranty of any kind. It may have bugs, stop working, or change at any time.
        Don’t rely on it as your only reminder for anything important.
      </p>

      <h2>Limitation of liability</h2>
      <p>
        To the fullest extent the law allows, the developer isn’t liable for any damages from using or being unable to
        use Tasks. That includes lost, changed or missed tasks.
      </p>

      <h2>Your Google account and Claude</h2>
      <p>
        Your tasks live in your Google account, and <a href="https://policies.google.com/terms">Google’s Terms of
        Service</a> apply to them. When you use the connector with Claude,{" "}
        <a href="https://www.anthropic.com/legal">Anthropic’s terms</a> apply to your use of Claude. Claude can make
        changes to your tasks when asked, so check important changes yourself.
      </p>

      <h2>Not affiliated</h2>
      <p>
        Tasks isn’t made, endorsed or reviewed by Google, Apple or Anthropic. Google Tasks is a trademark of Google LLC.
      </p>

      <h2>Changes</h2>
      <p>These terms may change. The new version will be posted here with a new date.</p>

      <h2>Contact</h2>
      <p>
        <a href="https://github.com/binhnguyeeen/tasks/issues">Open an issue on GitHub</a> or email{" "}
        <a href={`mailto:${address()}`}>{address()}</a>.
      </p>
    </Legal>
  );
}
