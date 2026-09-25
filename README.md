# CRISIS

**Clinical Reference for Immediate Stabilization In Situ** — an offline-first
reference for crisis protocols, high-acuity low-occurrence (HALO) procedures,
and envenomation.

**Live:** https://awpeace1906-collab.github.io/crisis-app/

> A reference for rapid recall under pressure — not a substitute for
> institutional protocol, clinical judgment, or real-time specialist
> consultation. Verify doses and technique against your own institution's
> protocols before clinical use.

## Two apps, one content source

| | |
|---|---|
| `src/`, `public/` | React + Vite PWA. Installable, works fully offline. |
| `ios/` | Native SwiftUI app (generated with `xcodegen` from `ios/project.yml`). |

Neither app owns its content. Protocols, procedures and species data live in
the separate **[crisis-content](https://github.com/awpeace1906-collab/crisis-content)**
repo, which builds them to JSON and serves them from the jsDelivr CDN. Both apps
fetch from the CDN at runtime and cache for offline use — so a content
correction ships by pushing to crisis-content, with no app release.

The JSON under `public/data/` and `ios/CRISIS/Resources/` is only the **offline
fallback** baked into each build, used on a first launch with no network.

## Working on it

```bash
npm install
npm run dev            # local dev (serves the bundled /data first, then the CDN)
npm run sync-content   # refresh the offline fallback from ../../crisis-content/dist
npm run build          # production build (base "/")
npm run build:demo     # single self-contained HTML file, for sharing a preview
```

Pushing to `main` deploys to GitHub Pages (`.github/workflows/pages.yml`). The
site is served from `/crisis-app/`, so every local asset path goes through
`import.meta.env.BASE_URL` (or `%BASE_URL%` in `index.html`) — a root-absolute
path like `/data/...` builds fine and then 404s under the subpath, and for the
offline fallback that failure only shows up when the device is actually offline.

## Categories and ordering

Category membership, order, and cross-listing are defined in crisis-content's
`scripts/unified-categories.mjs`. Within a category, entries sort by
`entryOrder`, not alphabetically — the app stores entries in IndexedDB keyed by
`id`, so any order in the JSON is discarded on read. The web `EntryList.jsx` and
iOS `DataStore.groupByCategory` both implement this and must stay in parity.
