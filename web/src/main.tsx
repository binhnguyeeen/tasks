import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { PageShell } from "@/components/page-shell";
import Home from "@/pages/Home";
import "./index.css";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <PageShell current="index">
      <Home />
    </PageShell>
  </StrictMode>
);
