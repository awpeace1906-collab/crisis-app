import { useEffect, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { useCrisisDB } from '../db/DataProvider.jsx';
import { getAllEntries, searchProtocols } from '../db/query.js';
import { TYPE_ICON, entryHref } from '../entryType.js';

/**
 * Category-grouped, searchable list — shared by the Protocols tab, the HALO
 * tab, and Home's per-category drill-down. Protocols and procedures share
 * one record shape and one IndexedDB store, so the only real difference
 * between call sites is `typeFilter` (omit it to show both types mixed,
 * e.g. for a category that holds both) and copy/props.
 */
export default function EntryList({
  typeFilter,
  basePath,
  kicker,
  title,
  lede,
  searchPlaceholder,
  emptyLabel,
  initialCategory,
}) {
  const { db } = useCrisisDB();
  const [items, setItems] = useState([]);
  const [query, setQuery] = useState('');
  const mixed = !typeFilter;

  useEffect(() => {
    if (!db) return;
    getAllEntries(db, typeFilter).then(setItems);
  }, [db, typeFilter]);

  const filtered = useMemo(() => searchProtocols(items, query), [items, query]);

  const grouped = useMemo(() => {
    const map = new Map();
    const place = (p, id, label, order) => {
      if (!map.has(id)) map.set(id, { id, label, order, items: [] });
      map.get(id).items.push(p);
    };
    const browsing = query.trim() === '';
    for (const p of filtered) {
      place(p, p.category, p.categoryLabel, p.categoryOrder);
      // An entry has one primary category (what it is) and may surface under
      // others (where people go looking for it) — a surgical airway is an
      // Airway procedure, but an anesthesiologist looks under Anesthesia.
      // Only while browsing: in search results the same hit under two headings
      // is noise, not discovery.
      if (browsing) for (const s of p.secondaryCategories ?? []) place(p, s.id, s.label, s.order);
    }
    // Entries arrive from IndexedDB in primary-key order — i.e. alphabetically
    // by slug — so the order they had in the JSON is already gone by here.
    // `entryOrder` is how content overrides that: inside Airway, alphabetical
    // would put "Awake Fiberoptic Intubation" at the top of the list you open
    // during a CICO, ahead of the two entries you actually need. Defaulted for
    // the bundled offline snapshot, which may predate the field.
    for (const g of map.values()) {
      g.items.sort((a, b) => (a.entryOrder ?? 50) - (b.entryOrder ?? 50) || a.title.localeCompare(b.title));
    }
    let groups = [...map.values()].sort((a, b) => a.order - b.order);
    // Match the group itself. The previous test — "any group containing an item
    // whose primary category is this one" — was only equivalent while every
    // item lived in exactly one group; with cross-listing, opening Airway would
    // also have shown Anesthesia, since airway entries now appear in both.
    if (initialCategory && browsing) {
      groups = groups.filter((g) => g.id === initialCategory);
    }
    return groups;
  }, [filtered, initialCategory, query]);

  return (
    <div className="page-pad">
      <div className="page-kicker kicker">{kicker}</div>
      <div className="page-title">{title}</div>
      <p className="page-lede">{lede}</p>

      <input
        className="search-input"
        placeholder={searchPlaceholder}
        value={query}
        onChange={(e) => setQuery(e.target.value)}
      />

      {grouped.length === 0 && (
        <div className="empty-state">
          <div className="icon">🔍</div>
          <div>{emptyLabel} match "{query}"</div>
        </div>
      )}

      {grouped.map((cat) => (
        <div className="cat-block" key={cat.label}>
          <div className="cat-block-head">
            <span className="cat-dot" style={{ background: `var(--${cat.items[0].color})` }} />
            <span className="cat-block-title">{cat.label}</span>
            <span className="cat-count">{cat.items.length}</span>
          </div>
          <div className="grid-list">
            {cat.items.map((p) => (
              <Link className="entry-card" to={mixed ? entryHref(p) : `${basePath}/${p.id}`} key={p.id} style={{ '--accent': `var(--${p.color})` }}>
                <div className="entry-title">
                  {mixed && (
                    <span className="entry-type-icon" title={p.type === 'protocol' ? 'Protocol' : 'HALO procedure'}>{TYPE_ICON[p.type]}</span>
                  )}
                  {p.title}
                </div>
                <div className="entry-desc">{p.description}</div>
              </Link>
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}
