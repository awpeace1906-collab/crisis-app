import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';
import { viteSingleFile } from 'vite-plugin-singlefile';

// Produces a single self-contained dist-demo/index.html for sharing as a
// static preview (e.g. a Claude Artifact) — no service worker, no /data
// fetch, content is embedded at build time. Not the deployable PWA; see
// vite.config.js for that.
export default defineConfig({
  define: {
    'import.meta.env.VITE_EMBED_DATA': JSON.stringify('true'),
  },
  build: {
    outDir: 'dist-demo',
    emptyOutDir: true,
  },
  plugins: [react(), viteSingleFile()],
});
