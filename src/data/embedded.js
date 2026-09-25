// Statically-imported data bundle, used only by the single-file demo build
// (VITE_EMBED_DATA=true) so the whole app — including its content — can
// live in one self-contained HTML file with no runtime fetch. The real PWA
// build fetches these same files from /data/*.json instead (see seed.js).
import protocolsData from '../../public/data/protocols.json';
import envenomationData from '../../public/data/envenomation.json';
import proceduresData from '../../public/data/procedures.json';

export { protocolsData, envenomationData, proceduresData };
