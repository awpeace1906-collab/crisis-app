import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { useCrisisDB } from '../db/DataProvider.jsx';
import { getAllRegions } from '../db/query.js';

export default function EnvenomationHub() {
  const { db } = useCrisisDB();
  const [regions, setRegions] = useState([]);

  useEffect(() => {
    if (!db) return;
    getAllRegions(db).then(setRegions);
  }, [db]);

  return (
    <div className="page-pad">
      <div className="page-kicker kicker">Envenomation</div>
      <div className="page-title">By Region</div>
      <p className="page-lede">Species-level reference for critical-intervention bites and stings — onset, syndrome, field and ED management, and antivenom dosing.</p>

      <div className="grid-list">
        {regions.map((r) => (
          <Link className="entry-card region-card" to={`/envenomation/${r.id}`} key={r.id} style={{ '--accent': 'var(--purple)' }}>
            <div className="entry-title">{r.label}</div>
            <div className="entry-desc">{r.lede}</div>
            <span className="region-count-badge">{r.species.length} species</span>
          </Link>
        ))}
      </div>
    </div>
  );
}
