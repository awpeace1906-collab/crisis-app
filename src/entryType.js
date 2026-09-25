// Shared by any view that can show protocols and procedures mixed together
// (Home's search, category-filtered views) — both content types share one
// record shape, distinguished only by `type`.
export const TYPE_ICON = { protocol: '⚡', procedure: '✱' };
export const TYPE_LABEL = { protocol: 'Protocol', procedure: 'HALO procedure' };
export const TYPE_ROUTE = { protocol: '/protocols', procedure: '/halo' };

export function entryHref(entry) {
  return `${TYPE_ROUTE[entry.type]}/${entry.id}`;
}
