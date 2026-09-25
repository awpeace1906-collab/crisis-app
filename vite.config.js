import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';
import { VitePWA } from 'vite-plugin-pwa';

export default defineConfig({
  plugins: [
    react(),
    VitePWA({
      registerType: 'autoUpdate',
      includeAssets: ['favicon.svg', 'icons/icon.svg', 'icons/apple-touch-icon.png'],
      manifest: {
        name: 'CRISIS — Clinical Reference for Immediate Stabilization In Situ',
        short_name: 'CRISIS',
        description: 'Offline-first crisis protocols and envenomation reference.',
        theme_color: '#0a0e14',
        background_color: '#0a0e14',
        display: 'standalone',
        start_url: '/',
        icons: [
          { src: '/icons/icon-192.png', sizes: '192x192', type: 'image/png' },
          { src: '/icons/icon-512.png', sizes: '512x512', type: 'image/png' },
          { src: '/icons/icon-512.png', sizes: '512x512', type: 'image/png', purpose: 'maskable' },
          { src: '/icons/icon.svg', sizes: 'any', type: 'image/svg+xml' },
        ],
      },
      workbox: {
        globPatterns: ['**/*.{js,css,html,svg,json}'],
        // Content Update Architecture, 2026-08-31: the app's real content
        // source is the crisis-content CDN (see src/config.js), fetched
        // cross-origin at runtime — this rule caches *that* for offline use.
        // NetworkFirst (not CacheFirst — that was the earlier bug: a
        // same-origin /data/*.json rule that served a stale response
        // forever once cached, regardless of the app's own version-check
        // reseed logic) means a connected device always tries the network
        // first and only falls back to the cache when it's actually
        // offline, so a content fix is visible on next load rather than
        // stuck behind an indefinite cache. The bundled /data/*.json
        // fallback copy is same-origin and precached normally above (a
        // fixed snapshot is exactly what CacheFirst-via-precache is for).
        runtimeCaching: [
          {
            urlPattern: /^https:\/\/cdn\.jsdelivr\.net\/gh\/.*\/dist\/.*\.json$/,
            handler: 'NetworkFirst',
            options: {
              cacheName: 'crisis-content-cdn',
              networkTimeoutSeconds: 4,
              expiration: { maxEntries: 16, maxAgeSeconds: 60 * 60 * 24 * 30 },
            },
          },
        ],
      },
      devOptions: {
        enabled: true,
      },
    }),
  ],
});
