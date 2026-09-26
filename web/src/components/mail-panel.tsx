import { useEffect, useRef, useState } from "react";
import { AnimatePresence, motion, useReducedMotion } from "motion/react";
import { Check, Copy, ExternalLink, Mail, X } from "lucide-react";
import { address, mailto } from "@/lib/contact";

export interface MailRequest {
  title: string;
  description: string;
  subject: string;
  body: string;
}

const openEvent = "tasks:open-mail";

export function openMail(request: MailRequest) {
  window.dispatchEvent(new CustomEvent<MailRequest>(openEvent, { detail: request }));
}

function gmailLink(request: MailRequest) {
  const query = new URLSearchParams({ view: "cm", fs: "1", to: address(), su: request.subject, body: request.body });
  return `https://mail.google.com/mail/?${query.toString()}`;
}

const option =
  "flex w-full items-center gap-3 rounded-2xl border border-black/10 px-4 py-3 text-left transition hover:bg-zinc-100 dark:border-white/15 dark:hover:bg-zinc-900";

export function MailPanel() {
  const [request, setRequest] = useState<MailRequest | null>(null);
  const [copied, setCopied] = useState(false);
  const panel = useRef<HTMLDivElement>(null);
  const opener = useRef<Element | null>(null);
  const reduceMotion = useReducedMotion();

  useEffect(() => {
    const open = (event: Event) => {
      opener.current = document.activeElement;
      setCopied(false);
      setRequest((event as CustomEvent<MailRequest>).detail);
    };
    window.addEventListener(openEvent, open);
    return () => window.removeEventListener(openEvent, open);
  }, []);

  useEffect(() => {
    if (!request) return;
    panel.current?.querySelector<HTMLElement>("[data-first-option]")?.focus();
    const onKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        close();
        return;
      }
      if (event.key !== "Tab" || !panel.current) return;
      const items = [...panel.current.querySelectorAll<HTMLElement>("a, button")];
      const first = items[0];
      const last = items[items.length - 1];
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault();
        last.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        first.focus();
      }
    };
    document.addEventListener("keydown", onKey);
    return () => document.removeEventListener("keydown", onKey);
  }, [request]);

  function close() {
    setRequest(null);
    if (opener.current instanceof HTMLElement) opener.current.focus();
  }

  async function copy() {
    try {
      await navigator.clipboard.writeText(address());
      setCopied(true);
    } catch {
      setCopied(false);
    }
  }

  return (
    <AnimatePresence>
      {request && (
        <motion.div
          key="mail-panel"
          className="fixed inset-0 z-50 flex items-end justify-center bg-black/40 p-4 backdrop-blur-sm sm:items-center"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.2 }}
          onClick={event => {
            if (event.target === event.currentTarget) close();
          }}
        >
          <motion.div
            ref={panel}
            role="dialog"
            aria-modal="true"
            aria-labelledby="mail-panel-title"
            aria-describedby="mail-panel-description"
            className="relative w-full max-w-sm rounded-3xl bg-white p-6 text-zinc-900 shadow-2xl dark:bg-zinc-950 dark:text-zinc-100"
            initial={reduceMotion ? { opacity: 0 } : { opacity: 0, y: 24, scale: 0.97 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={reduceMotion ? { opacity: 0 } : { opacity: 0, y: 16, scale: 0.98 }}
            transition={{ type: "spring", stiffness: 380, damping: 30 }}
          >
            <button
              type="button"
              onClick={close}
              aria-label="Close"
              className="absolute right-4 top-4 flex size-9 items-center justify-center rounded-full text-zinc-500 transition hover:bg-zinc-100 dark:text-zinc-400 dark:hover:bg-zinc-900"
            >
              <X size={18} />
            </button>
            <h2 id="mail-panel-title" className="font-display pr-10 text-3xl leading-tight">
              {request.title}
            </h2>
            <p id="mail-panel-description" className="mt-2 text-pretty text-sm text-zinc-600 dark:text-zinc-400">
              {request.description}
            </p>
            <div className="mt-6 flex flex-col gap-2">
              <a
                href={gmailLink(request)}
                target="_blank"
                rel="noopener noreferrer"
                onClick={close}
                className={option}
                data-first-option
              >
                <ExternalLink size={18} className="shrink-0 text-zinc-500 dark:text-zinc-400" />
                <span className="flex-1">Open in Gmail</span>
              </a>
              <a href={mailto(request.subject, request.body)} onClick={close} className={option}>
                <Mail size={18} className="shrink-0 text-zinc-500 dark:text-zinc-400" />
                <span className="flex-1">Open Mail App</span>
              </a>
              <button type="button" onClick={copy} className={option}>
                {copied ? (
                  <Check size={18} className="shrink-0 text-green-700 dark:text-green-400" />
                ) : (
                  <Copy size={18} className="shrink-0 text-zinc-500 dark:text-zinc-400" />
                )}
                <span className="flex min-w-0 flex-1 flex-col">
                  <span>{copied ? "Copied" : "Copy Email Address"}</span>
                  <span className="truncate text-xs text-zinc-500 dark:text-zinc-400">{address()}</span>
                </span>
              </button>
            </div>
            <p aria-live="polite" className="sr-only">
              {copied ? "Email address copied" : ""}
            </p>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
