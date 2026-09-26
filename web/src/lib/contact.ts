const parts = ["trinhquocbinhnguyen", "gmail", "com"];

export const address = () => `${parts[0]}@${parts.slice(1).join(".")}`;

export function mailto(subject: string, body?: string) {
  const query = [`subject=${encodeURIComponent(subject)}`];
  if (body) query.push(`body=${encodeURIComponent(body)}`);
  return `mailto:${address()}?${query.join("&")}`;
}
