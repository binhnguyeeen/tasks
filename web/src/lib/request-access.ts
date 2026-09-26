import { openMail } from "@/components/mail-panel";

export function requestAccess() {
  openMail({
    title: "Request Access",
    description:
      "Send me the Google account you want to use with the connector, and I’ll add it by hand. Pick how you’d like to send it.",
    subject: "Tasks connector access",
    body: "Hi, could you add me to the Tasks connector? My Google account is: ",
  });
}

export function reportProblem() {
  openMail({
    title: "Get Help",
    description: "Tell me what isn’t working, and include what you tried. Pick how you’d like to send it.",
    subject: "Tasks: something isn’t working",
    body: "",
  });
}
