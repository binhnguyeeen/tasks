import { useCallback, useEffect, useRef, useState } from "react";
import { flushSync } from "react-dom";
import { PageShell } from "@/components/page-shell";
import { matchRoute, routes, tabIndex, type Route } from "@/routes";

const SLIDE_MS = 320;
const OVERLAP_MS = 100;

type Enter = "right" | "left" | "fade";

interface Leaving {
  route: Route;
  enter: Enter;
  top: number;
}

function currentRoute(): Route {
  return matchRoute(window.location.pathname) ?? routes[0];
}

function enterFrom(from: Route, to: Route): Enter {
  const a = tabIndex(from.id);
  const b = tabIndex(to.id);
  if (a === -1 || b === -1) return "fade";
  return b > a ? "right" : "left";
}

function scrollMs(distance: number) {
  return Math.round(Math.min(360, Math.max(220, distance * 0.35)));
}

function reducedMotion() {
  return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
}

export function App() {
  const [route, setRoute] = useState(currentRoute);
  const [leaving, setLeaving] = useState<Leaving | null>(null);
  const main = useRef<HTMLElement>(null);
  const firstRender = useRef(true);
  const routeRef = useRef(route);
  const frame = useRef(0);
  const timers = useRef<number[]>([]);

  const clearPending = useCallback(() => {
    cancelAnimationFrame(frame.current);
    frame.current = 0;
    for (const id of timers.current) clearTimeout(id);
    timers.current = [];
  }, []);

  const swap = useCallback((prev: Route, next: Route, enter: Enter, top: number) => {
    setLeaving({ enter, route: prev, top });
    setRoute(next);
    timers.current.push(window.setTimeout(() => setLeaving(null), SLIDE_MS));
  }, []);

  const glideToTop = useCallback((duration: number) => {
    const start = window.scrollY;
    const began = performance.now();
    const step = () => {
      const progress = Math.min(1, (performance.now() - began) / duration);
      const eased = 1 - (1 - progress) ** 3;
      window.scrollTo(0, start * (1 - eased));
      if (progress < 1) frame.current = requestAnimationFrame(step);
      else frame.current = 0;
    };
    frame.current = requestAnimationFrame(step);
    timers.current.push(
      window.setTimeout(() => {
        cancelAnimationFrame(frame.current);
        frame.current = 0;
        window.scrollTo(0, 0);
      }, duration + 60)
    );
  }, []);

  const go = useCallback(
    (next: Route, hash: string) => {
      const prev = routeRef.current;
      if (next.id === prev.id && !hash) {
        window.scrollTo({ behavior: reducedMotion() ? "auto" : "smooth", top: 0 });
        return;
      }

      clearPending();
      window.history.replaceState({ y: window.scrollY }, "", window.location.href);
      window.history.pushState({ y: 0 }, "", next.path + hash);

      const enter = enterFrom(prev, next);

      if (reducedMotion()) {
        window.scrollTo(0, 0);
        setRoute(next);
        return;
      }

      const from = window.scrollY;
      if (from <= 4) {
        swap(prev, next, enter, 0);
        return;
      }

      const duration = scrollMs(from);
      glideToTop(duration);
      timers.current.push(window.setTimeout(() => swap(prev, next, enter, 0), duration - OVERLAP_MS));
    },
    [clearPending, glideToTop, swap]
  );

  useEffect(() => {
    if ("scrollRestoration" in window.history) window.history.scrollRestoration = "manual";

    const onClick = (event: MouseEvent) => {
      if (event.defaultPrevented || event.button !== 0) return;
      if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
      const link = (event.target as Element | null)?.closest?.("a");
      if (!link || link.hasAttribute("download")) return;
      if (link.target && link.target !== "_self") return;
      const url = new URL(link.href, window.location.href);
      if (url.origin !== window.location.origin) return;
      const next = matchRoute(url.pathname);
      if (!next) return;
      event.preventDefault();
      go(next, url.hash);
    };

    const onPop = (event: PopStateEvent) => {
      const next = currentRoute();
      const prev = routeRef.current;
      const y = (event.state as { y?: number } | null)?.y ?? 0;
      if (next.id === prev.id) {
        window.scrollTo(0, y);
        return;
      }
      clearPending();
      if (reducedMotion()) {
        setRoute(next);
        window.scrollTo(0, y);
        return;
      }
      const offset = y - window.scrollY;
      flushSync(() => swap(prev, next, enterFrom(prev, next), offset));
      window.scrollTo(0, y);
    };

    document.addEventListener("click", onClick);
    window.addEventListener("popstate", onPop);
    return () => {
      document.removeEventListener("click", onClick);
      window.removeEventListener("popstate", onPop);
      clearPending();
    };
  }, [clearPending, go, swap]);

  useEffect(() => {
    routeRef.current = route;
    document.title = route.title;
    document.querySelector('meta[name="description"]')?.setAttribute("content", route.description);
    if (firstRender.current) {
      firstRender.current = false;
      return;
    }
    main.current?.focus({ preventScroll: true });
  }, [route]);

  const Page = route.Component;
  const Leaving = leaving?.route.Component;

  return (
    <PageShell current={route.id} mainRef={main}>
      <div className="route-viewport">
        {leaving && Leaving && (
          <div key={leaving.route.id} className={`route-layer route-out-${leaving.enter}`} style={{ top: leaving.top }}>
            <Leaving />
          </div>
        )}
        <div key={route.id} className={leaving ? `route-layer route-in-${leaving.enter}` : "route-layer"}>
          <Page />
        </div>
      </div>
    </PageShell>
  );
}
