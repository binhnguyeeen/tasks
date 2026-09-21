const address = ["trinhquocbinhnguyen", "gmail.com"].join("@");

document.querySelectorAll("[data-request]").forEach(link => {
  const subject = "Tasks connector access";
  const body = "Hi, could you add me to the Tasks connector? My Google account is: ";
  link.href = `mailto:${address}?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;
});

document.querySelectorAll("[data-mail]").forEach(link => {
  link.href = `mailto:${address}?subject=${encodeURIComponent("Tasks")}`;
});
