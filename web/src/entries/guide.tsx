import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { PageShell } from "@/components/page-shell";
import Guide from "@/pages/Guide";
import "../index.css";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <PageShell current="guide">
      <Guide />
    </PageShell>
  </StrictMode>
);
