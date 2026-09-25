import { useEffect, useState } from 'react';
import { useParams, Link } from 'react-router-dom';
import { useCrisisDB } from '../db/DataProvider.jsx';
import { getRegion } from '../db/query.js';
import { contentIssueUrl } from '../config.js';

export default function SpeciesDetail() {
  const { regionId, speciesId } = useParams();
  const { db } = useCrisisDB();
  const [region, setRegion] = useState(undefined);

  useEffect(() => {
    if (!db) return;
    getRegion(db, regionId).then(setRegion);
  }, [db, regionId]);

  if (region === undefined) return <div className="page-pad">Loading…</div>;
  const species = region?.species.find((s) => s.id === speciesId);
  if (!species) {
    return (
      <div className="empty-state">
        <div className="icon">⚠️</div>
        <div>Species not found.</div>
        <Link to={`/envenomation/${regionId}`} className="btn" style={{ marginTop: 14, display: 'inline-block' }}>
          Back to {region?.label ?? 'Region'}
        </Link>
      </div>
    );
  }

  return (
    <div className="page-pad">
      <div className="entry-meta" style={{ marginBottom: 10 }}>
        {species.regionTag && <span className="tag region">{species.regionTag}</span>}
        {species.classTag && <span className="tag class">{species.classTag}</span>}
        {species.mechanismTag && <span className="tag mechanism">{species.mechanismTag}</span>}
      </div>
      <div className="page-title" style={{ fontSize: 21 }}>{species.title}</div>
      <p className="page-lede">{species.subtitle}</p>

      {species.lastVerified && (
        <div className="review-meta">
          <span>Last verified {species.lastVerified}</span>
          <a
            className="flag-link"
            href={contentIssueUrl({ kind: 'species', id: `${regionId}/${species.id}`, title: species.title, lastVerified: species.lastVerified })}
            target="_blank"
            rel="noopener noreferrer"
          >
            Flag as outdated
          </a>
        </div>
      )}

      {species.fields.map((field, i) => (
        <div className="field" key={i}>
          <div className="field-label">{field.label}</div>
          <div className="field-body" dangerouslySetInnerHTML={{ __html: field.html }} />
        </div>
      ))}

      {species.pearls && (
        <div className="box pearls-box" style={{ marginTop: 4 }}>
          <div className="field-label" style={{ color: 'var(--red)' }}>{species.pearls.label}</div>
          <div className="field-body" dangerouslySetInnerHTML={{ __html: species.pearls.html }} />
        </div>
      )}
    </div>
  );
}
