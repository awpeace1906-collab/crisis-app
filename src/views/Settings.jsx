import { useState } from 'react';
import { useCrisisDB } from '../db/DataProvider.jsx';

export default function Settings() {
  const { meta, reload } = useCrisisDB();
  const [checking, setChecking] = useState(false);

  const handleCheck = async () => {
    setChecking(true);
    await reload();
    setChecking(false);
  };

  return (
    <div className="page-pad">
      <div className="page-kicker kicker">Settings</div>
      <div className="page-title">App Data</div>

      <div className="box" style={{ marginTop: 6 }}>
        <div className="settings-row">
          <span className="settings-label">Protocols loaded</span>
          <span className="settings-value">{meta?.protocolCount ?? '—'}</span>
        </div>
        <div className="settings-row">
          <span className="settings-label">Species loaded</span>
          <span className="settings-value">{meta?.speciesCount ?? '—'}</span>
        </div>
        <div className="settings-row">
          <span className="settings-label">HALO procedures loaded</span>
          <span className="settings-value">{meta?.procedureCount ?? '—'}</span>
        </div>
        <div className="settings-row">
          <span className="settings-label">Last synced</span>
          <span className="settings-value">{meta?.seededAt ? new Date(meta.seededAt).toLocaleString() : '—'}</span>
        </div>
        <div className="settings-row">
          <span className="settings-label">Content build</span>
          <span className="settings-value">{meta?.contentCommit ? meta.contentCommit.slice(0, 7) : '—'}</span>
        </div>
        <div className="settings-row">
          <button className="btn" onClick={handleCheck} disabled={checking}>
            {checking ? 'Checking…' : 'Check for updates'}
          </button>
        </div>
      </div>

      <p style={{ color: 'var(--text3)', fontSize: 12, marginTop: 16, fontStyle: 'italic' }}>
        Content is fetched from a live source and cached on-device for offline use — a correction can ship
        without an app update. "Check for updates" re-fetches now if you have connectivity; otherwise the
        app keeps working from whatever's cached.
      </p>
    </div>
  );
}
