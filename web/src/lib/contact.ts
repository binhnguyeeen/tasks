const parts = ["trinhquocbinhnguyen", "gmail", "com"];

export const address = () => `${parts[0]}@${parts.slice(1).join(".")}`;

export function mailto(subject: string, body?: string) {
  const query = [`subject=${encodeURIComponent(subject)}`];
  if (body) query.push(`body=${encodeURIComponent(body)}`);
  return `mailto:${address()}?${query.join("&")}`;
}

export function requestAccess() {
  window.location.href = mailto(
    "Tasks connector access",
    "Hi, could you add me to the Tasks connector? My Google account is: "
  );
}
