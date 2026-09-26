import { Clause, Legal } from "@/components/legal";
import { address } from "@/lib/contact";

export default function Terms() {
  return (
    <Legal
      title="Tasks Terms of Service"
      scope="For the Tasks Mac app and the Tasks connector for Claude"
      updated="26 September 2026"
      notice={
        <p>
          Please read these terms carefully before using Tasks. By using the Tasks Mac app or the Tasks connector, you
          agree to these terms. If you do not agree, do not use Tasks.
        </p>
      }
    >
      <Clause n={1} title="A Personal Project">
        <p>
          Tasks is a personal, open-source project made by Binh Nguyen, an individual developer (“the developer”). The
          hosted connector is only open to Google accounts the developer has allowed. Anyone may run their own copy under
          the <a href="https://github.com/binhnguyeeen/tasks/blob/main/LICENSE">MIT license</a>.
        </p>
      </Clause>

      <Clause n={2} title="Free, With No Payments">
        <p>
          Tasks is free. There are no fees, subscriptions, in-app purchases or ads, so there’s nothing to refund. If that
          ever changes, the price will be shown clearly before you pay anything, and these terms will be updated first.
        </p>
      </Clause>

      <Clause n={3} title="Who Can Use It">
        <p>
          You need to be at least 13, or older if your country requires it for a Google account. Use Tasks only with a
          Google account you’re allowed to use.
        </p>
      </Clause>

      <Clause n={4} title="No Warranty">
        <p className="legal-caps">
          Tasks is provided “as is”, without warranty of any kind. It may have bugs, stop working, or change at any
          time. Don’t rely on it as your only reminder for anything important.
        </p>
      </Clause>

      <Clause n={5} title="Limitation of Liability">
        <p className="legal-caps">
          To the fullest extent the law allows, the developer isn’t liable for any damages from using or being unable to
          use Tasks. That includes lost, changed or missed tasks.
        </p>
      </Clause>

      <Clause n={6} title="Your Google Account and Claude">
        <p>
          Your tasks live in your Google account, and{" "}
          <a href="https://policies.google.com/terms">Google’s Terms of Service</a> apply to them. When you use the
          connector with Claude, <a href="https://www.anthropic.com/legal">Anthropic’s terms</a> apply to your use of
          Claude. Claude can make changes to your tasks when asked, so check important changes yourself.
        </p>
      </Clause>

      <Clause n={7} title="Not Affiliated">
        <p>
          Tasks isn’t made, endorsed or reviewed by Google, Apple or Anthropic. Google Tasks is a trademark of Google
          LLC.
        </p>
      </Clause>

      <Clause n={8} title="Changes">
        <p>These terms may change. The new version will be posted here with a new date.</p>
      </Clause>

      <Clause n={9} title="Contact">
        <p>
          <a href="https://github.com/binhnguyeeen/tasks/issues">Open an issue on GitHub</a> or email{" "}
          <a href={`mailto:${address()}`}>{address()}</a>.
        </p>
      </Clause>
    </Legal>
  );
}
