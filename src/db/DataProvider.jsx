import { createContext, useContext, useEffect, useState, useCallback } from 'react';
import { ensureSeeded, ensureSeededWithData } from './seed.js';

const DataContext = createContext(null);

export function DataProvider({ children }) {
  const [state, setState] = useState({ status: 'loading', db: null, meta: null, error: null });

  const load = useCallback(async () => {
    setState((s) => ({ ...s, status: 'loading' }));
    try {
      const { db, meta } = import.meta.env.VITE_EMBED_DATA === 'true'
        ? await (async () => {
            const { protocolsData, envenomationData, proceduresData } = await import('../data/embedded.js');
            return ensureSeededWithData(protocolsData, envenomationData, proceduresData);
          })()
        : await ensureSeeded();
      setState({ status: 'ready', db, meta, error: null });
    } catch (err) {
      setState({ status: 'error', db: null, meta: null, error: err.message });
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  return <DataContext.Provider value={{ ...state, reload: load }}>{children}</DataContext.Provider>;
}

export function useCrisisDB() {
  const ctx = useContext(DataContext);
  if (!ctx) throw new Error('useCrisisDB must be used within DataProvider');
  return ctx;
}
