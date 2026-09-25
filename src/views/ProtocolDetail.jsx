import { useEffect, useState } from 'react';
import { useParams, Link } from 'react-router-dom';
import { useCrisisDB } from '../db/DataProvider.jsx';
import { getEntity } from '../db/query.js';
import { SectionBlocks } from '../components/BlockRenderer.jsx';
import { contentIssueUrl } from '../config.js';

/**
 * Renders a protocol or procedure detail page — the two content types share
 * an identical JSON shape (title/subtitle/badges/sections/footer) and now
 * live in the same `entries` store, so one component serves both
 * `/protocols/:id` and `/halo/:id`.
 */
export default function ProtocolDetail({ backTo = '/protocols', backLabel = 'Protocols', notFoundLabel = 'Protocol' }) {
  const { id } = useParams();
  const { db } = useCrisisDB();
  const [protocol, setProtocol] = useState(undefined);

  useEffect(() => {
    if (!db) return;
    getEntity(db, id).then(setProtocol);
  }, [db, id]);

  if (protocol === undefined) return <div className="page-pad">Loading…</div>;
  if (protocol === null) {
    return (
      <div className="empty-state">
        <div className="icon">⚠️</div>
        <div>{notFoundLabel} not found.</div>
        <Link to={backTo} className="btn" style={{ marginTop: 14, display: 'inline-block' }}>Back to {backLabel}</Link>
      </div>
    );
  }

  return (
    <div>
      <nav className="quicknav-strip">
        <div className="quicknav-strip-inner">
          {/* Must not be an <a href="#id">: under HashRouter that reads as a
              route change to "/id", matches nothing, and blanks the page.
              Scroll the section into view directly instead. */}
          {protocol.sections.map((s) => (
            <button
              type="button"
              className="qn"
              key={s.id}
              onClick={() => document.getElementById(s.id)?.scrollIntoView({ behavior: 'smooth', block: 'start' })}
            >
              {s.title}
            </button>
          ))}
        </div>
      </nav>

      <div className="page-pad" style={{ paddingTop: 6 }}>
        <div className="kicker" style={{ marginBottom: 8 }}>{protocol.kicker}</div>
        <div className="page-title" style={{ fontSize: 22 }}>{protocol.title}</div>
        <p className="page-lede">{protocol.subtitle}</p>
        <div className="badges" style={{ marginBottom: 12 }}>
          {protocol.badges.map((b, i) => (
            <span className={`badge ${b.color}`} key={i}>{b.text}</span>
          ))}
        </div>

        {protocol.lastVerified && (
          <div className="review-meta">
            <span>Last verified {protocol.lastVerified}</span>
            <a
              className="flag-link"
              href={contentIssueUrl({ kind: protocol.type, id: protocol.id, title: protocol.title, lastVerified: protocol.lastVerified })}
              target="_blank"
              rel="noopener noreferrer"
            >
              Flag as outdated
            </a>
          </div>
        )}

        {protocol.sections.map((section) => (
          <div key={section.id}>
            <div className={`sec-head c-${section.color}`} id={section.id}>
              <span className="sec-num">{section.num}</span>
              <h2>{section.title}</h2>
            </div>
            {section.tagline && <div className="tagline">{section.tagline}</div>}
            <SectionBlocks blocks={section.blocks} />
          </div>
        ))}

        {protocol.footer && <div className="footer-note">{protocol.footer}</div>}
      </div>
    </div>
  );
}
