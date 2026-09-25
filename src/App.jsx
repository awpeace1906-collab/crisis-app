import { HashRouter, Routes, Route, Link, useLocation, useNavigate } from 'react-router-dom';
import { DataProvider, useCrisisDB } from './db/DataProvider.jsx';
import Home from './views/Home.jsx';
import EntryList from './views/EntryList.jsx';
import CategoryView from './views/CategoryView.jsx';
import ProtocolDetail from './views/ProtocolDetail.jsx';
import EnvenomationHub from './views/EnvenomationHub.jsx';
import EnvenomationRegion from './views/EnvenomationRegion.jsx';
import SpeciesDetail from './views/SpeciesDetail.jsx';
import Settings from './views/Settings.jsx';

const TABS = [
  { to: '/', icon: '⌂', label: 'Home', match: (p) => p === '/' },
  { to: '/protocols', icon: '⚡', label: 'Protocols', match: (p) => p.startsWith('/protocols') },
  { to: '/halo', icon: '✚', label: 'HALO', match: (p) => p.startsWith('/halo') },
  { to: '/settings', icon: '⚙', label: 'Settings', match: (p) => p.startsWith('/settings') },
];

function Header() {
  const location = useLocation();
  const navigate = useNavigate();
  const atRoot = ['/', '/protocols', '/halo', '/settings'].includes(location.pathname);

  return (
    <header className="app-header">
      {!atRoot && (
        <button className="back-btn" onClick={() => navigate(-1)} aria-label="Back">‹</button>
      )}
      {atRoot ? (
        <Link to="/" className="brand-mark">
          <img src="/icons/icon.svg" className="mark" alt="" />
          <span className="name">CRISIS</span>
        </Link>
      ) : (
        <h1>&nbsp;</h1>
      )}
    </header>
  );
}

function TabBar() {
  const location = useLocation();
  return (
    <nav className="app-tabbar">
      {TABS.map((tab) => (
        <Link key={tab.to} to={tab.to} className={`tab-link ${tab.match(location.pathname) ? 'active' : ''}`}>
          <span className="tab-icon">{tab.icon}</span>
          <span>{tab.label}</span>
        </Link>
      ))}
    </nav>
  );
}

function AppShell() {
  const { status, error } = useCrisisDB();

  if (status === 'loading') {
    return (
      <div className="empty-state" style={{ paddingTop: 100 }}>
        <div className="icon">◌</div>
        <div>Loading CRISIS data…</div>
      </div>
    );
  }
  if (status === 'error') {
    return (
      <div className="empty-state" style={{ paddingTop: 100 }}>
        <div className="icon">⚠️</div>
        <div>Failed to load data: {error}</div>
      </div>
    );
  }

  return (
    <>
      <Header />
      <main className="app-main">
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/category/:categoryId" element={<CategoryView />} />
          <Route
            path="/protocols"
            element={(
              <EntryList
                typeFilter="protocol"
                basePath="/protocols"
                kicker="Crisis Protocols"
                title="Protocols"
                lede="Anesthesia, resuscitation, toxicologic, obstetric, pediatric, and environmental crises — recognize it, treat it, know why."
                searchPlaceholder="Search protocols…"
                emptyLabel="No protocols"
              />
            )}
          />
          <Route path="/protocols/:id" element={<ProtocolDetail backTo="/protocols" backLabel="Protocols" notFoundLabel="Protocol" />} />
          <Route
            path="/halo"
            element={(
              <EntryList
                typeFilter="procedure"
                basePath="/halo"
                kicker="HALO"
                title="High Acuity, Low Occurrence"
                lede="Procedures and events rare enough that recall fades between exposures — the ones worth having a reference for precisely because you won't have practiced them recently."
                searchPlaceholder="Search procedures…"
                emptyLabel="No procedures"
              />
            )}
          />
          <Route path="/halo/:id" element={<ProtocolDetail backTo="/halo" backLabel="HALO" notFoundLabel="Procedure" />} />
          <Route path="/envenomation" element={<EnvenomationHub />} />
          <Route path="/envenomation/:regionId" element={<EnvenomationRegion />} />
          <Route path="/envenomation/:regionId/:speciesId" element={<SpeciesDetail />} />
          <Route path="/settings" element={<Settings />} />
        </Routes>
      </main>
      <TabBar />
    </>
  );
}

export default function App() {
  return (
    <HashRouter>
      <DataProvider>
        <AppShell />
      </DataProvider>
    </HashRouter>
  );
}
