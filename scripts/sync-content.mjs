// Copies the built content bundle from the sibling crisis-content repo into
// this app's bundled offline-fallback copy — both the web app's public/data/
// (served same-origin, precached by the service worker) and the iOS app's
// Resources/data/ (baked into the binary). This is the *fallback* snapshot
// only: the live path both apps use at runtime is the CDN
// (cdn.jsdelivr.net/gh/.../crisis-content@main/dist/...), not this copy —
// see src/config.js and ios/CRISIS/Models/DataStore.swift. Run this before
// cutting an app release so the fallback isn't too stale, and any time you
// want the local dev server to reflect a content change made in the sibling
// repo without waiting on a CDN push.
import { copyFileSync, existsSync, mkdirSync, readdirSync, rmSync, statSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const CONTENT_DIST = path.resolve(__dirname, '../../../crisis-content/dist');
const WEB_DATA_DIR = path.resolve(__dirname, '../public/data');
const IOS_DATA_DIR = path.resolve(__dirname, '../ios/CRISIS/Resources/data');

const FILES = ['protocols.json', 'procedures.json', 'envenomation.json', 'manifest.json'];

function main() {
  if (!existsSync(CONTENT_DIST)) {
    console.error(`crisis-content/dist not found at ${CONTENT_DIST} — run "npm run build" there first.`);
    process.exit(1);
  }
  for (const dir of [WEB_DATA_DIR, IOS_DATA_DIR]) mkdirSync(dir, { recursive: true });

  for (const file of FILES) {
    const src = path.join(CONTENT_DIST, file);
    if (!existsSync(src)) {
      console.warn(`Skipping ${file} — not present in crisis-content/dist`);
      continue;
    }
    copyFileSync(src, path.join(WEB_DATA_DIR, file));
    copyFileSync(src, path.join(IOS_DATA_DIR, file));
    console.log(`Synced ${file} -> public/data/ and ios/CRISIS/Resources/data/`);
  }

  syncFigures();
}

/**
 * Rasterized figure PNGs, for iOS only — the web app renders the inline SVG
 * straight out of the JSON and needs no image files at all.
 */
function syncFigures() {
  const src = path.join(CONTENT_DIST, 'figures', 'png');
  if (!existsSync(src)) {
    console.warn('No rasterized figures found — run "npm run build" in crisis-content.');
    return;
  }
  const dest = path.resolve(__dirname, '../ios/CRISIS/Resources/figures');
  rmSync(dest, { recursive: true, force: true });
  mkdirSync(dest, { recursive: true });

  const pngs = readdirSync(src).filter((f) => f.endsWith('.png'));
  let bytes = 0;
  for (const png of pngs) {
    copyFileSync(path.join(src, png), path.join(dest, png));
    bytes += statSync(path.join(src, png)).size;
  }
  console.log(`Synced ${pngs.length} figure PNG(s) (${(bytes / 1024).toFixed(0)} KB) -> ios/CRISIS/Resources/figures/`);
}

main();
