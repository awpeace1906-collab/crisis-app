import { openDB } from 'idb';

const DB_NAME = 'crisis-db';
const DB_VERSION = 3;

export function openCrisisDB() {
  return openDB(DB_NAME, DB_VERSION, {
    upgrade(db) {
      // v3: protocols + procedures merged into one `entries` store (each
      // record tagged `type: 'protocol' | 'procedure'`) now that both
      // content types share one record shape end to end. Drop the old
      // per-type stores from earlier installs rather than leaving them
      // dangling and unused.
      if (db.objectStoreNames.contains('protocols')) db.deleteObjectStore('protocols');
      if (db.objectStoreNames.contains('procedures')) db.deleteObjectStore('procedures');

      if (!db.objectStoreNames.contains('entries')) {
        const entries = db.createObjectStore('entries', { keyPath: 'id' });
        entries.createIndex('by_category', 'category');
        entries.createIndex('by_type', 'type');
      }
      if (!db.objectStoreNames.contains('envenomation_regions')) {
        const regions = db.createObjectStore('envenomation_regions', { keyPath: 'id' });
        regions.createIndex('by_label', 'label');
      }
      if (!db.objectStoreNames.contains('meta')) {
        db.createObjectStore('meta', { keyPath: 'key' });
      }
    },
  });
}
