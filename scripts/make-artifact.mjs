// Strips the outer <!doctype>/<html>/<head>/<body> shell from the
// single-file demo build so it's a bare content fragment suitable for the
// Artifact tool (which supplies its own document skeleton).
import { readFileSync, writeFileSync } from 'node:fs';

const src = readFileSync('dist-demo/index.html', 'utf-8');
const iconSvgBase64 = readFileSync('public/icons/icon.svg', 'utf-8');
const iconDataUri = `data:image/svg+xml;base64,${Buffer.from(iconSvgBase64).toString('base64')}`;

let out = src
  .replace(/^<!doctype html>\s*/i, '')
  .replace(/<html[^>]*>/i, '')
  .replace(/<\/html>\s*$/i, '')
  .replace(/<head>/i, '')
  .replace(/<\/head>/i, '')
  .replace(/<body[^>]*>/i, '')
  .replace(/<\/body>\s*/i, '')
  // Artifact provides its own charset/viewport/favicon via the publish skeleton + favicon param.
  .replace(/<meta charset="UTF-8" \/>\s*/i, '')
  .replace(/<meta name="viewport"[^>]*\/>\s*/i, '')
  .replace(/<link rel="icon"[^>]*\/>\s*/i, '')
  .replace(/<link rel="apple-touch-icon"[^>]*\/>\s*/i, '')
  // The header logo <img> is rendered client-side by React, so its src is a
  // JS string literal (minifier emits backtick-quoted literals here) rather
  // than an HTML attribute — replace that literal, not an HTML attr.
  //
  // Matched with a pattern, not an exact string: the src is built from
  // import.meta.env.BASE_URL, and vite-plugin-singlefile forces base "./", so
  // the literal is `./icons/icon.svg` — while it was `/icons/icon.svg` before
  // BASE_URL was introduced for GitHub Pages. An exact-string .replace() that
  // matches nothing fails silently and ships a broken logo; see the guard below.
  .replace(/src:`[^`]*icons\/icon\.svg`/, `src:\`${iconDataUri}\``)
  .replace('<title>CRISIS — Clinical Reference for Immediate Stabilization In Situ</title>', '<title>CRISIS</title>')
  .trim();

// The artifact has no /icons/ directory to fall back on, so any surviving
// reference is a broken image. Fail the build instead of publishing it.
if (/icons\/icon\.svg/.test(out)) {
  throw new Error('make-artifact: an icons/icon.svg reference survived — the logo would be broken in the artifact');
}

writeFileSync('dist-demo/artifact.html', out);
console.log('wrote dist-demo/artifact.html', out.length, 'bytes');
