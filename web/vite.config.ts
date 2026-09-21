import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";
import path from "node:path";

const pages = ["index", "guide", "claude", "help", "mac", "privacy", "terms"];

export default defineConfig({
  base: "/tasks/",
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: { "@": path.resolve(__dirname, "./src") },
  },
  build: {
    outDir: "../docs",
    emptyOutDir: true,
    rollupOptions: {
      input: Object.fromEntries(pages.map(p => [p, path.resolve(__dirname, `${p}.html`)])),
    },
  },
});
