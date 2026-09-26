import { useEffect, useRef, useState } from "react";

const INTERACTIVE = 'a, button, [role="button"], input, select, textarea, summary, label, [data-cursor]';

export function CursorFollower() {
  const ref = useRef<HTMLDivElement>(null);
  const target = useRef({ x: 0, y: 0 });
  const current = useRef({ x: 0, y: 0 });
  const [visible, setVisible] = useState(false);
  const [hovering, setHovering] = useState(false);
  const [label, setLabel] = useState<string | null>(null);
  const startRef = useRef<(() => void) | null>(null);

  useEffect(() => {
    if (window.matchMedia("(pointer: coarse), (prefers-reduced-motion: reduce)").matches) return;
    document.documentElement.classList.add("cursor-hidden");

    const move = (e: PointerEvent) => {
      target.current = { x: e.clientX, y: e.clientY };
      setVisible(true);
      startRef.current?.();
      const hit = (e.target as Element | null)?.closest?.(INTERACTIVE) ?? null;
      setHovering(Boolean(hit));
      setLabel(hit?.getAttribute("data-cursor") ?? null);
    };
    const leave = () => setVisible(false);
    window.addEventListener("pointermove", move);
    window.addEventListener("pointerleave", leave);
    document.addEventListener("mouseleave", leave);

    let frame = 0;
    const tick = () => {
      const dx = target.current.x - current.current.x;
      const dy = target.current.y - current.current.y;
      if (Math.abs(dx) < 0.1 && Math.abs(dy) < 0.1) {
        frame = 0;
        return;
      }
      current.current.x += dx * 0.2;
      current.current.y += dy * 0.2;
      if (ref.current) {
        ref.current.style.transform = `translate3d(${current.current.x}px, ${current.current.y}px, 0) translate(-50%, -50%)`;
      }
      frame = requestAnimationFrame(tick);
    };
    const start = () => {
      if (!frame) frame = requestAnimationFrame(tick);
    };
    startRef.current = start;
    start();

    return () => {
      document.documentElement.classList.remove("cursor-hidden");
      window.removeEventListener("pointermove", move);
      window.removeEventListener("pointerleave", leave);
      document.removeEventListener("mouseleave", leave);
      cancelAnimationFrame(frame);
    };
  }, []);

  const expanded = hovering && Boolean(label);

  return (
    <div
      ref={ref}
      className="pointer-events-none fixed left-0 top-0 z-[60] motion-reduce:hidden"
      style={{ opacity: visible ? 1 : 0, transition: "opacity 200ms ease" }}
      aria-hidden="true"
    >
      <div
        className={`${expanded ? "rounded-2xl" : "squircle"} flex items-center justify-center overflow-hidden whitespace-nowrap bg-zinc-900 text-white shadow-lg ring-1 ring-black/10 dark:bg-white dark:text-zinc-900 dark:ring-white/20`}
        style={{
          width: expanded ? 168 : hovering ? 46 : 22,
          height: expanded ? 34 : hovering ? 46 : 22,
          opacity: hovering && !expanded ? 0.55 : 1,
          transition:
            "width 240ms cubic-bezier(0.32, 0.72, 0, 1), height 240ms cubic-bezier(0.32, 0.72, 0, 1), opacity 160ms ease",
        }}
      >
        <span className="px-3 text-xs font-medium" style={{ opacity: expanded ? 1 : 0, transition: "opacity 140ms ease" }}>
          {label}
        </span>
      </div>
    </div>
  );
}
