import { openCrisisDB } from './schema.js';
import { CDN_BASE } from '../config.js';

// Bundled offline copy. Resolved against Vite's base, not the domain root:
// on GitHub Pages the app lives under /crisis-app/, and a root-absolute
// "/data/..." there 404s — which only surfaces offline, because online the
// CDN answers first. That is exactly the case this fallback exists for.
const LOCAL_DATA = `${import.meta.env.BASE_URL}data`;

async function fetchJSON(path) {
  const res = await fetch(path, { cache: 'no-store' });
  if (!res.ok) throw new Error(`Failed to fetch ${path}: ${res.status}`);
  return res.json();
}

/**
 * Content Update Architecture, 2026-08-31: prefer the CDN copy (live,
 * updated by a `git push` to crisis-content with no app rebuild) and fall
 * back to the bundled same-origin copy shipped with this build only if the
 * CDN is unreachable — offline, DNS hiccup, jsDelivr down. The bundled copy
 * is a point-in-time snapshot synced via `npm run sync-content`; it exists
 * so the app still works the very first time it's opened with no network at
 * all, not as the primary content source.
 */
async function fetchJSONWithFallback(filename) {
  // In local dev, reverse the priority: read the bundled copy first. That's
  // the one `npm run sync-content` writes from the sibling crisis-content
  // checkout, so local content edits are actually visible locally. Without
  // this, `npm run dev` silently renders whatever is live on the CDN and
  // your local edits appear to do nothing — which is exactly as confusing
  // as it sounds. Production keeps CDN-first so a content fix ships without
  // an app release.
  const order = import.meta.env.DEV
    ? [`${LOCAL_DATA}/${filename}`, `${CDN_BASE}/${filename}`]
    : [`${CDN_BASE}/${filename}`, `${LOCAL_DATA}/${filename}`];

  try {
    return await fetchJSON(order[0]);
  } catch (err) {
    console.warn(`Content fetch failed for ${order[0]}, falling back to ${order[1]}:`, err.message);
    return fetchJSON(order[1]);
  }
}

function bundleVersionOf(protocolsData, envenomationData, proceduresData) {
  return `${protocolsData.generatedAt}|${envenomationData.generatedAt}|${proceduresData.generatedAt}`;
}

async function writeBundle(db, protocolsData, envenomationData, proceduresData, manifestData) {
  const tx = db.transaction(['entries', 'envenomation_regions', 'meta'], 'readwrite');

  await Promise.all([
    (async () => {
      const store = tx.objectStore('entries');
      await store.clear();
      for (const p of protocolsData.protocols) await store.put(p);
      for (const p of proceduresData.procedures) await store.put(p);
    })(),
    (async () => {
      const store = tx.objectStore('envenomation_regions');
      await store.clear();
      for (const r of envenomationData.regions) await store.put(r);
    })(),
    tx.objectStore('meta').put({
      key: 'bundle',
      version: bundleVersionOf(protocolsData, envenomationData, proceduresData),
      categories: protocolsData.categories,
      pendingProtocols: protocolsData.pending,
      protocolCount: protocolsData.protocols.length,
      speciesCount: envenomationData.regions.reduce((n, r) => n + r.species.length, 0),
      haloCategories: proceduresData.categories,
      pendingProcedures: proceduresData.pending,
      procedureCount: proceduresData.procedures.length,
      // Content Update Architecture, 2026-08-31: ties whatever's live in the
      // app back to the exact crisis-content commit that produced it — see
      // that repo's scripts/write-manifest.mjs. Absent on the demo build and
      // on any bundle seeded before this field existed.
      contentCommit: manifestData?.commit ?? null,
      seededAt: new Date().toISOString(),
    }),
  ]);

  await tx.done;
}

/**
 * Ensures IndexedDB holds the given data bundle, re-seeding only when its
 * generatedAt timestamps differ from what's already stored. Safe to call on
 * every app start — it no-ops once the DB is current.
 */
export async function ensureSeededWithData(protocolsData, envenomationData, proceduresData, manifestData, db) {
  db ??= await openCrisisDB();
  const existingMeta = await db.get('meta', 'bundle');

  const currentVersion = bundleVersionOf(protocolsData, envenomationData, proceduresData);
  if (existingMeta?.version === currentVersion) {
    return { db, reseeded: false, meta: existingMeta };
  }

  await writeBundle(db, protocolsData, envenomationData, proceduresData, manifestData);
  const meta = await db.get('meta', 'bundle');
  return { db, reseeded: true, meta };
}

/**
 * Fetch-based seeding for the real (server-hosted) PWA build. Prefers the
 * CDN (see fetchJSONWithFallback above); if every fetch fails outright —
 * genuinely offline before the app was ever seeded, not just "CDN
 * unreachable but bundled copy worked" — falls back to whatever's already
 * in IndexedDB from a prior successful run rather than surfacing an error,
 * since offline-first means "still works," not "works except when offline."
 */
export async function ensureSeeded() {
  const db = await openCrisisDB();
  try {
    const [protocolsData, envenomationData, proceduresData, manifestData] = await Promise.all([
      fetchJSONWithFallback('protocols.json'),
      fetchJSONWithFallback('envenomation.json'),
      fetchJSONWithFallback('procedures.json'),
      fetchJSONWithFallback('manifest.json').catch(() => null),
    ]);
    return ensureSeededWithData(protocolsData, envenomationData, proceduresData, manifestData, db);
  } catch (err) {
    const existingMeta = await db.get('meta', 'bundle');
    if (existingMeta) {
      console.warn('All content fetches failed; using previously cached data.', err.message);
      return { db, reseeded: false, meta: existingMeta };
    }
    throw err;
  }
}
