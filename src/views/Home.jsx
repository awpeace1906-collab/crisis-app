import { useEffect, useMemo, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useCrisisDB } from '../db/DataProvider.jsx';
import { getAllEntries, searchProtocols } from '../db/query.js';
import { TYPE_ICON, entryHref } from '../entryType.js';

export default function Home() {
  const { db, meta } = useCrisisDB();
  const [entries, setEntries] = useState([]);
  const [query, setQuery] = useState('');
  const navigate = useNavigate();

  useEffect(() => {
    if (!db) return;
    getAllEntries(db).then(setEntries);
  }, [db]);

  const results = useMemo(() => (query ? searchProtocols(entries, query).slice(0, 8) : []), [entries, query]);

  const categories = meta?.categories ?? [];

  return (
    <div className="page-pad">
      <div className="page-title">CRISIS</div>
      <p className="page-lede">Clinical Reference for Immediate Stabilization In Situ</p>

      <input
        className="search-input"
        placeholder="Search protocols & procedures…"
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        onKeyDown={(e) => {
          if (e.key === 'Enter' && results[0]) navigate(entryHref(results[0]));
        }}
      />

      {query && (
        <div className="grid-list" style={{ marginBottom: 20 }}>
          {results.map((p) => (
            <Link className="entry-card" to={entryHref(p)} key={p.id} style={{ '--accent': `var(--${p.color})` }}>
              <div className="entry-title">
                <span className="entry-type-icon" title={p.type === 'protocol' ? 'Protocol' : 'HALO procedure'}>{TYPE_ICON[p.type]}</span>
                {p.title}
              </div>
              <div className="entry-desc">{p.description}</div>
            </Link>
          ))}
          {results.length === 0 && (
            <div className="empty-state">
              <div className="icon">🔍</div>
              <div>No protocols or procedures match "{query}"</div>
            </div>
          )}
        </div>
      )}

      {!query && (
        <>
          <div className="cat-block-head" style={{ marginBottom: 10 }}>
            <span className="cat-block-title">Categories</span>
          </div>
          <div className="grid-list" style={{ marginBottom: 26 }}>
            {categories.map((c) => (
              <Link className="entry-card" to={`/category/${c.id}`} key={c.id} style={{ '--accent': `var(--${c.color})` }}>
                <div className="entry-title">{c.label}</div>
              </Link>
            ))}
            <Link className="entry-card" to="/envenomation" style={{ '--accent': 'var(--red)' }}>
              <div className="entry-title">Envenomation</div>
              <div className="entry-desc">{meta?.speciesCount ?? '—'} species, 8 regions</div>
            </Link>
          </div>
        </>
      )}
    </div>
  );
}
