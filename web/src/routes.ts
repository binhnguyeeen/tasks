import type { ComponentType } from "react";
import Home from "@/pages/Home";
import Guide from "@/pages/Guide";
import Claude from "@/pages/Claude";
import Help from "@/pages/Help";
import Mac from "@/pages/Mac";
import Privacy from "@/pages/Privacy";
import Terms from "@/pages/Terms";

const base = import.meta.env.BASE_URL;

export interface Route {
  id: string;
  path: string;
  title: string;
  description: string;
  Component: ComponentType;
}

export const routes: Route[] = [
  {
    id: "index",
    path: base,
    title: "Tasks: Google Tasks on your Mac and in Claude",
    description:
      "A Mac menu bar app for Google Tasks, and a connector that lets Claude see, add and tick off your tasks.",
    Component: Home,
  },
  {
    id: "guide",
    path: `${base}guide.html`,
    title: "Guide · Tasks",
    description: "How to install the Tasks Mac app and connect Google Tasks to Claude.",
    Component: Guide,
  },
  {
    id: "claude",
    path: `${base}claude.html`,
    title: "Claude connector · Tasks",
    description: "Add the Tasks connector to Claude so it can see what is due, tick tasks off and add new ones.",
    Component: Claude,
  },
  {
    id: "help",
    path: `${base}help.html`,
    title: "Help · Tasks",
    description: "Common questions about the Tasks Mac app and the Google Tasks connector for Claude.",
    Component: Help,
  },
  {
    id: "mac",
    path: `${base}mac.html`,
    title: "Install Tasks on your Mac · Tasks",
    description: "How to download, open and sign in to the Tasks Mac app.",
    Component: Mac,
  },
  {
    id: "privacy",
    path: `${base}privacy.html`,
    title: "Privacy Policy · Tasks",
    description: "What data the Tasks Mac app and Claude connector touch, and what happens to it.",
    Component: Privacy,
  },
  {
    id: "terms",
    path: `${base}terms.html`,
    title: "Terms of Service · Tasks",
    description: "The terms that apply to the Tasks Mac app and the Claude connector.",
    Component: Terms,
  },
];

export const tabOrder = ["index", "guide", "claude", "help"];

export function tabIndex(id: string): number {
  return tabOrder.indexOf(id);
}

const home = routes[0];

export function matchRoute(pathname: string): Route | null {
  const clean = pathname.replace(/\/index\.html$/, "/");
  const withSlash = clean.endsWith("/") ? clean : `${clean}/`;
  if (withSlash === base) return home;
  return routes.find(route => route.path === clean) ?? null;
}
