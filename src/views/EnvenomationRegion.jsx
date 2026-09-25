import { useEffect, useMemo, useState } from 'react';
import { useParams, Link } from 'react-router-dom';
import { useCrisisDB } from '../db/DataProvider.jsx';
import { getRegion } from '../db/query.js';
import { searchSpecies } from '../db/query.js';

const CLASS_OPTIONS = ['all', 'snake', 'spider', 'scorpion', 'marine', 'other'];

export default function EnvenomationRegion() {
  const { regionId } = useParams();
  const { db } = useCrisisDB();
  const [region, setRegion] = useState(undefined);
  const [query, setQuery] = useState('');
  const [classFilter, setClassFilter] = useState('all');

  useEffect(() => {
    if (!db) return;
    getRegion(db, regionId).then(setRegion);
  }, [db, regionId]);

  const availableClasses = useMemo(() => {
    if (!region) return [];
    const set = new Set(region.species.map((s) => s.class).filter(Boolean));
    return CLASS_OPTIONS.filter((c) => c === 'all' || set.has(c));
  }, [region]);

  const filtered = useMemo(() => {
    if (!region) return [];
    return searchSpecies(region.species, query, { classFilter });
  }, [region, query, classFilter]);

  if (region === undefined) return <div className="page-pad">Loading…</div>;
  if (region === null) {
    return (
      <div className="empty-state">
        <div className="icon">⚠️</div>
        <div>Region not found.</div>
        <Link to="/envenomation" className="btn" style={{ marginTop: 14, display: 'inline-block' }}>Back to Regions</Link>
      </div>
    );
  }

  return (
    <div className="page-pad">
      <div className="kicker" style={{ marginBottom: 8 }}>Envenomation · {region.label}</div>
      <div className="page-title" style={{ fontSize: 22 }}>{region.label}</div>
      <p className="page-lede">{region.lede}</p>

      <input
        className="search-input"
        placeholder="Search species, syndrome, keyword…"
        value={query}
        onChange={(e) => setQuery(e.target.value)}
      />
      <div className="chip-row">
        {availableClasses.map((c) => (
          <button key={c} className={`chip ${classFilter === c ? 'active' : ''}`} onClick={() => setClassFilter(c)}>
            {c === 'all' ? 'All' : c[0].toUpperCase() + c.slice(1)}
          </button>
        ))}
      </div>

      <div className="species-list">
        {filtered.map((s) => (
          <Link className="entry-card" to={`/envenomation/${region.id}/${s.id}`} key={s.id} style={{ '--accent': 'var(--purple)' }}>
            <div className="entry-title">{s.title}</div>
            <div className="entry-desc">{s.subtitle}</div>
            <div className="entry-meta">
              {s.classTag && <span className="tag class">{s.classTag}</span>}
              {s.mechanismTag && <span className="tag mechanism">{s.mechanismTag}</span>}
            </div>
          </Link>
        ))}
        {filtered.length === 0 && (
          <div className="empty-state">
            <div className="icon">🔍</div>
            <div>No species match.</div>
          </div>
        )}
      </div>

      {region.nonCritical && (
        <div className="box" style={{ marginTop: 24 }}>
          <div className="alert-t" style={{ color: 'var(--text2)', marginBottom: 6 }}>{region.nonCritical.label}</div>
          <p style={{ fontStyle: 'italic', color: 'var(--text2)', fontSize: 13, marginBottom: 10 }}>{region.nonCritical.sub}</p>
          <ul style={{ listStyle: 'none' }}>
            {region.nonCritical.items.map((item, i) => (
              <li key={i} style={{ padding: '8px 0', borderBottom: '1px solid var(--border)', fontSize: 13.5 }}>
                <b>{item.name}</b>
                <span dangerouslySetInnerHTML={{ __html: item.html }} />
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}
