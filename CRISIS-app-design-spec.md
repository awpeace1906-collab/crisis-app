# CRISIS App — Technical Design Spec

*Offline-first clinical reference app. Standalone from the Critical Vector website, reusing its design system and content model.*

---

## 1. Stack decision

| Layer | Choice | Why |
|---|---|---|
| Shell | PWA (Vite + vanilla JS or lightweight framework) | Matches AnesCalc's build pattern; installable, no App Store gate needed at v1 |
| Offline storage | IndexedDB (via `idb` wrapper) | Structured queries (filter by class/region) beat localStorage past a few hundred cards |
| Caching | Service Worker, cache-first for shell + data bundle | Zero-connectivity guarantee is the whole point of the app |
| Styling | Reuse CV CSS tokens as-is (ground-truthed against `iv_fluids_guide.html`) | No new visual language; `@media print` swap ports directly |
| Content authoring | JSON files, hand-edited or generated, versioned | Single source of truth, diffable in git, no CMS dependency |
| Wrapper (later) | Capacitor, only if App Store distribution becomes a goal | Defer — PWA install covers the offline requirement now |

If you want a component framework instead of vanilla JS (React/Preact), say so — it changes the file structure below but not the data/offline layers.

---

## 2. Repo structure

```
crisis-app/
├── public/
│   ├── manifest.json
│   ├── icons/
│   └── data/
│       ├── drugs.json           # base + antivenom-extended cards
│       ├── protocols.json       # 41-topic crisis library
│       ├── envenomation.json    # region → species → drug-id mapping
│       └── meta.json            # bundle version, last-updated
├── src/
│   ├── main.js                  # SW registration, router mount
│   ├── router.js                # hash-based, no server needed
│   ├── db/
│   │   ├── schema.js            # IndexedDB object stores + indexes
│   │   ├── seed.js              # first-load: JSON → IndexedDB
│   │   └── query.js             # search/filter functions
│   ├── views/
│   │   ├── ProtocolsList.js
│   │   ├── ProtocolDetail.js
│   │   ├── DrugCardsList.js
│   │   ├── DrugCardDetail.js
│   │   ├── EnvenomationHub.js
│   │   ├── Calculators.js
│   │   └── Settings.js
│   ├── components/
│   │   ├── DrugCard.js          # renders base fields + optional antivenom block
│   │   ├── FilterChips.js
│   │   ├── SearchBar.js
│   │   └── RegionGate.js        # shared by Envenomation hub + Drug Cards antivenom filter
│   └── styles/
│       └── (ported CV tokens, unchanged)
├── sw.js                        # service worker: install/activate/fetch
└── vite.config.js
```

---

## 3. Data model

**`drugs.json`** — flat array, one object per drug. Antivenom is an *extension block*, not a separate schema, so `DrugCard.js` stays a single component with conditional rendering:

```json
{
  "id": "crofab",
  "name": "CroFab",
  "class": "antivenom",
  "category": "snake",
  "starred_default": false,
  "fields": {
    "indication": "...",
    "dose_initial": "...",
    "dose_repeat": "...",
    "dose_pediatric": "...",
    "route": "IV",
    "onset": "...",
    "duration": "...",
    "contraindications": "...",
    "adverse_effects": "...",
    "pregnancy_category": "..."
  },
  "antivenom": {
    "source_species": ["copperhead", "rattlesnake", "cottonmouth"],
    "reconstitution": "...",
    "skin_test_required": false,
    "premedication": "...",
    "monitoring_window": "...",
    "storage": "refrigerated 2-8C",
    "region_availability": ["US"]
  }
}
```

**`envenomation.json`** — region-gated navigation index, cross-references `drugs.json` by id rather than duplicating antivenom data:

```json
{
  "regions": [
    {
      "id": "us-southeast",
      "label": "US Southeast",
      "species": [
        { "name": "Copperhead", "drug_ids": ["crofab", "anavip"] }
      ]
    }
  ]
}
```

**IndexedDB stores** (mirrors the JSON, adds indexes for query speed):
- `drugs` — keyPath `id`, indexes on `class`, `category`
- `protocols` — keyPath `id`, index on `system` (Anesthesia/Resus/Tox/OB/Peds/Environmental)
- `envenomation_regions` — keyPath `id`
- `meta` — single record: bundle version, last sync timestamp

---

## 4. Core logic pieces worth designing before coding

**a. First-load seed vs. update check**
On first launch: read `public/data/*.json` → bulk-write to IndexedDB → cache shell assets in SW. On later launches: read from IndexedDB only, never touch the JSON files unless the user taps "Check for updates" in Settings, which fetches `meta.json`, compares version, and — only if online and newer — re-seeds. This keeps the app fully deterministic offline; no background sync surprises.

**b. Search/filter (`query.js`)**
Single function `queryDrugs({ text, class, category, region })` reading from the `drugs` IndexedDB index. Text search does a simple substring match across `name` and `fields.indication` — no need for a search library at this content scale (tens to low hundreds of cards).

**c. Region-gating (`RegionGate.js`)**
One shared component, two call sites:
- Envenomation hub uses it to scope species lists to the user's set region (from Settings)
- Drug Cards' antivenom filter uses the same region value to sub-filter the antivenom chip

Region is a single Settings value, not per-view state — avoids the two nav paths drifting out of sync.

**d. Print handling**
`DrugCardDetail.js` and `ProtocolDetail.js` both render into the same print stylesheet contract already established on the website (`@media print` light-mode token swap). No new print CSS — literally the same file, imported.

**e. Service worker strategy**
Cache-first for everything in `public/` (shell, data, icons). Explicit versioned cache name (`crisis-v1`) so a future deploy can invalidate cleanly. No network fallback needed by design — if it's not cached, it doesn't exist offline, which is correct for this use case.

---

## 5. Suggested build order

1. IndexedDB schema + seed logic (`db/`) — get data loading and queryable before any UI
2. `DrugCard.js` component with conditional antivenom block, fed by a handful of hand-written sample records (2–3 standard drugs, 2–3 antivenoms)
3. `DrugCardsList.js` + search/filter wiring
4. Service worker + manifest — confirm true offline reload works early, not as an afterthought
5. `EnvenomationHub.js` + `RegionGate.js`, cross-linking into Drug Cards
6. Protocols and Calculators tabs (largely templated off the same list/detail pattern)
7. Settings (region picker, bundle version, update check)

Steps 1–4 are the load-bearing ones — once offline data + rendering + caching are proven, the remaining tabs are repetition of the same pattern.

---

## Open decisions before handoff to Claude Code

- Vanilla JS vs. a framework (React/Preact) — affects `views/`/`components/` structure above
- Full antivenom dataset — do you have the source content ready, or does Claude Code need to help draft it from the existing CV Envenomation hub content?
- Icon/manifest assets — reuse anything from AnesCalc, or net-new?
