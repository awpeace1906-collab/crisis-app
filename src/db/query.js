export async function getMeta(db) {
  return db.get('meta', 'bundle');
}

/** Single-record lookup for the detail page — protocols and procedures now live in one store. */
export async function getEntity(db, id) {
  return db.get('entries', id);
}

export async function getAllEntries(db, typeFilter) {
  if (!typeFilter) return db.getAll('entries');
  return db.getAllFromIndex('entries', 'by_type', typeFilter);
}

export async function getAllProtocols(db) {
  return getAllEntries(db, 'protocol');
}

export async function getAllProcedures(db) {
  return getAllEntries(db, 'procedure');
}

export async function getAllRegions(db) {
  return db.getAll('envenomation_regions');
}

export async function getRegion(db, id) {
  return db.get('envenomation_regions', id);
}

function norm(s) {
  return (s || '').toLowerCase();
}

export function searchProtocols(protocols, text) {
  const q = norm(text);
  if (!q) return protocols;
  return protocols.filter(
    (p) => norm(p.title).includes(q) || norm(p.subtitle).includes(q) || norm(p.description).includes(q)
  );
}

/** Flattens species out of regions for cross-region search/filter. */
export function flattenSpecies(regions) {
  const out = [];
  for (const region of regions) {
    for (const species of region.species) {
      out.push({ ...species, regionId: region.id, regionLabel: region.label });
    }
  }
  return out;
}

export function searchSpecies(species, text, { classFilter, mechanismFilter } = {}) {
  const q = norm(text);
  return species.filter((s) => {
    if (classFilter && classFilter !== 'all' && s.class !== classFilter) return false;
    if (mechanismFilter && mechanismFilter !== 'all' && s.mechanism !== mechanismFilter) return false;
    if (!q) return true;
    return norm(s.title).includes(q) || norm(s.search).includes(q) || norm(s.subtitle).includes(q);
  });
}
