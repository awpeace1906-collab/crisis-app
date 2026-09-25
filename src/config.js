// Content Update Architecture, 2026-08-31 — see crisis-content's README for
// the full picture. This file is the one place both the fetch logic
// (src/db/seed.js) and the UI (last-verified/flag-as-outdated) point at the
// content repo, so the URL only needs updating in one spot if it ever moves.
export const CONTENT_REPO = 'awpeace1906-collab/crisis-content';
export const CONTENT_BRANCH = 'main';

// jsDelivr's GitHub CDN — free, no infra, and it fronts raw.githubusercontent
// with real edge caching + CORS enabled. Branch URLs like this refresh on a
// short TTL (usually well under an hour) rather than instantly; the content
// repo's CI purges this exact path after every push so in practice updates
// land within seconds, not whatever jsDelivr's default TTL would otherwise be.
export const CDN_BASE = `https://cdn.jsdelivr.net/gh/${CONTENT_REPO}@${CONTENT_BRANCH}/dist`;

export function contentIssueUrl({ kind, id, title, lastVerified }) {
  const title_ = `Outdated: ${title}`;
  const body = [
    `Flagged from the app as possibly outdated.`,
    ``,
    `- Type: ${kind}`,
    `- id: \`${id}\``,
    `- Last verified in the app: ${lastVerified ?? 'unknown'}`,
    ``,
    `What looks wrong / out of date:`,
    ``,
  ].join('\n');
  const params = new URLSearchParams({ title: title_, body, labels: 'flagged-from-app' });
  return `https://github.com/${CONTENT_REPO}/issues/new?${params.toString()}`;
}
