import { useCallback, useEffect, useRef, useState } from "react";
import { PageShell } from "@/components/page-shell";
import { matchRoute, routes, type Route } from "@/routes";

function currentRoute(): Route {
  return matchRoute(window.location.pathname) ?? routes[0];
}

export function App() {
  const [route, setRoute] = useState(currentRoute);
  const main = useRef<HTMLElement>(null);
  const firstRender = useRef(true);

  const go = useCallback(
    (next: Route, hash: string) => {
      if (next.id === route.id && !hash) {
        window.scrollTo({ top: 0 });
        return;
      }
      window.history.replaceState({ y: window.scrollY }, "", window.location.href);
      window.history.pushState({ y: 0 }, "", next.path + hash);
      setRoute(next);
    },
    [route.id]
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
      setRoute(currentRoute());
      const y = (event.state as { y?: number } | null)?.y ?? 0;
      requestAnimationFrame(() => window.scrollTo(0, y));
    };

    document.addEventListener("click", onClick);
    window.addEventListener("popstate", onPop);
    return () => {
      document.removeEventListener("click", onClick);
      window.removeEventListener("popstate", onPop);
    };
  }, [go]);

  useEffect(() => {
    document.title = route.title;
    document.querySelector('meta[name="description"]')?.setAttribute("content", route.description);

    if (firstRender.current) {
      firstRender.current = false;
      return;
    }
    window.scrollTo(0, 0);
    main.current?.focus({ preventScroll: true });
  }, [route]);

  const Page = route.Component;

  return (
    <PageShell current={route.id} mainRef={main}>
      <div key={route.id} className="route-enter">
        <Page />
      </div>
    </PageShell>
  );
}
