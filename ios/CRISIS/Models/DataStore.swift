import Foundation
import CryptoKit

@MainActor
final class DataStore: ObservableObject {
    /// The unified 7-category taxonomy both protocols and procedures now
    /// carry (Option 3, 2026-08-25) — drives Home's tile grid. There is no
    /// separate `haloCategories` any more; HALO's own 8 procedure-hub
    /// categories are vestigial once every record's `category` field points
    /// at this same list (see extract-procedures.mjs's HALO_CATEGORY_MAP).
    @Published private(set) var categories: [ProtocolCategory] = []
    @Published private(set) var pending: [PendingProtocol] = []
    @Published private(set) var regions: [EnvenomationRegion] = []
    /// Protocols and procedures merged — both share one record shape
    /// (`CrisisProtocol`), distinguished by `type`. Mirrors the web app's
    /// unified `entries` IndexedDB store.
    @Published private(set) var entries: [CrisisProtocol] = []
    @Published private(set) var loadError: String?

    /// Content Update Architecture, 2026-08-31 — see crisis-content's
    /// README and the web app's src/db/seed.js for the full picture. `entries`
    /// is populated synchronously from whatever's on disk (a previously
    /// fetched CDN copy, or the bundled fallback snapshot on first launch)
    /// so the app is usable immediately with no network. `refreshFromCDN()`
    /// then fetches the live bundle in the background and swaps it in if it
    /// parses cleanly, so a content fix ships without an app update.
    @Published private(set) var contentCommit: String?
    @Published private(set) var lastSyncedAt: Date?
    @Published private(set) var isRefreshing = false
    /// Bumped after figures are refreshed, so views showing a figure re-read it.
    @Published private(set) var figureRevision = 0
    /// builtAt of the content currently loaded. A refresh only swaps in CDN
    /// content that is newer, so the app never goes backwards — e.g. after an
    /// app update ships a bundle newer than what the CDN cache had.
    private var loadedBuiltAt = ""

    var protocols: [CrisisProtocol] { entries.filter { $0.type == "protocol" } }
    var procedures: [CrisisProtocol] { entries.filter { $0.type == "procedure" } }
    var speciesCount: Int { regions.reduce(0) { $0 + $1.species.count } }

    private static let contentFiles = ["protocols", "procedures", "envenomation", "manifest"]

    private static var cacheDir: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("CRISIS", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    init() {
        loadFromDisk()
        Task { await refreshFromCDN() }
    }

    /// Synchronous, network-free load from whichever's available: a
    /// previously cached CDN fetch takes priority over the bundled fallback
    /// snapshot, so a device that's fetched fresh content before keeps
    /// using it across launches even offline.
    private func loadFromDisk() {
        // An app update can ship bundled content newer than a previously
        // cached CDN copy. The cache used to win unconditionally, leaving the
        // device on older content until (and unless) a refresh succeeded.
        if let cached = try? DataStore.decodeCached(ContentManifest.self, "manifest"),
           let bundled = try? DataStore.decodeBundled(ContentManifest.self, "manifest"),
           bundled.builtAt > cached.builtAt {
            DataStore.clearCachedContent()
        }
        do {
            let protocolBundle: ProtocolBundle = try DataStore.decodeLocal("protocols")
            let envenomationBundle: EnvenomationBundle = try DataStore.decodeLocal("envenomation")
            let procedureBundle: ProcedureBundle = try DataStore.decodeLocal("procedures")
            categories = protocolBundle.categories.sorted { $0.order < $1.order }
            pending = protocolBundle.pending
            regions = envenomationBundle.regions.sorted { $0.label < $1.label }
            entries = protocolBundle.protocols + procedureBundle.procedures
            if let manifest: ContentManifest = try? DataStore.decodeLocal("manifest") {
                contentCommit = manifest.commit
                loadedBuiltAt = manifest.builtAt
            }
        } catch {
            loadError = "Failed to load bundled data: \(error.localizedDescription)"
        }
    }

    private static func decodeCached<T: Decodable>(_ type: T.Type, _ name: String) throws -> T {
        try JSONDecoder().decode(T.self, from: Data(contentsOf: cacheDir.appendingPathComponent("\(name).json")))
    }

    private static func decodeBundled<T: Decodable>(_ type: T.Type, _ name: String) throws -> T {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            throw NSError(domain: "DataStore", code: 1)
        }
        return try JSONDecoder().decode(T.self, from: Data(contentsOf: url))
    }

    /// Drops the cached CDN copy (JSON and figures) so the bundle is used.
    private static func clearCachedContent() {
        for name in contentFiles {
            try? FileManager.default.removeItem(at: cacheDir.appendingPathComponent("\(name).json"))
        }
        try? FileManager.default.removeItem(at: figuresDir)
    }

    private static func decodeLocal<T: Decodable>(_ name: String) throws -> T {
        let cached = cacheDir.appendingPathComponent("\(name).json")
        let data: Data
        if FileManager.default.fileExists(atPath: cached.path) {
            data = try Data(contentsOf: cached)
        } else {
            guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
                throw NSError(domain: "DataStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "\(name).json not found in bundle"])
            }
            data = try Data(contentsOf: url)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    /// Fetches the live bundle from the crisis-content CDN. Offline-first by
    /// design: any failure (no network, CDN hiccup, a malformed response) is
    /// swallowed and leaves whatever's already loaded untouched — there's
    /// never a network-required error state for the reader to hit.
    func refreshFromCDN() async {
        isRefreshing = true
        defer { isRefreshing = false }

        var fetched: [String: Data] = [:]
        for name in Self.contentFiles {
            guard let url = URL(string: "\(ContentConfig.cdnBase)/\(name).json") else { continue }
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            guard let (data, response) = try? await URLSession.shared.data(for: request),
                  let http = response as? HTTPURLResponse, http.statusCode == 200 else { continue }
            fetched[name] = data
        }

        guard let protocolsData = fetched["protocols"],
              let proceduresData = fetched["procedures"],
              let envenomationData = fetched["envenomation"] else { return }

        guard let protocolBundle = try? JSONDecoder().decode(ProtocolBundle.self, from: protocolsData),
              let procedureBundle = try? JSONDecoder().decode(ProcedureBundle.self, from: proceduresData),
              let envenomationBundle = try? JSONDecoder().decode(EnvenomationBundle.self, from: envenomationData) else { return }

        // Never go backwards: a CDN copy older than what is loaded (say, a
        // new app build whose bundle was synced after the last CDN build) is
        // ignored rather than swapped in.
        let remoteManifest = fetched["manifest"].flatMap { try? JSONDecoder().decode(ContentManifest.self, from: $0) }
        // Figures are skipped too: the CDN's would be older than the bundle's.
        if let remoteManifest, !loadedBuiltAt.isEmpty, remoteManifest.builtAt < loadedBuiltAt {
            return
        }

        for (name, data) in fetched {
            try? data.write(to: Self.cacheDir.appendingPathComponent("\(name).json"))
        }

        categories = protocolBundle.categories.sorted { $0.order < $1.order }
        pending = protocolBundle.pending
        regions = envenomationBundle.regions.sorted { $0.label < $1.label }
        entries = protocolBundle.protocols + procedureBundle.procedures
        lastSyncedAt = Date()
        if let remoteManifest {
            contentCommit = remoteManifest.commit
            loadedBuiltAt = remoteManifest.builtAt
        }
        await refreshFigures()
    }

    // MARK: - Figures

    private static var figuresDir: URL { cacheDir.appendingPathComponent("figures", isDirectory: true) }

    private struct FigureIndex: Codable {
        struct Entry: Codable { let file: String; let sha1: String }
        let figures: [String: Entry]
    }

    /// Rasterized figures used to reach iOS only in an app release — the
    /// JSON came from the CDN but the images came from the bundle, so a new or
    /// corrected figure showed caption-only (or stale) until the next build.
    /// crisis-content now publishes figures-index.json (figureId -> file +
    /// sha1); this downloads just the figures whose sha1 differs from both the
    /// cached and the bundled copy, verifies each, and removes cached files
    /// the index no longer lists. Any failure leaves what is there untouched.
    private func refreshFigures() async {
        let base = "\(ContentConfig.cdnBase)/figures/png"
        guard let url = URL(string: "\(base)/figures-index.json") else { return }
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let index = try? JSONDecoder().decode(FigureIndex.self, from: data) else { return }

        let fm = FileManager.default
        let dir = Self.figuresDir
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        let cachedIndexURL = dir.appendingPathComponent("figures-index.json")
        let cachedIndex = (try? Data(contentsOf: cachedIndexURL))
            .flatMap { try? JSONDecoder().decode(FigureIndex.self, from: $0) }

        var kept = Set<String>(["figures-index.json"])
        for (id, entry) in index.figures {
            let dest = dir.appendingPathComponent(entry.file)
            // Already have exactly this version cached.
            if cachedIndex?.figures[id]?.sha1 == entry.sha1, fm.fileExists(atPath: dest.path) {
                kept.insert(entry.file)
                continue
            }
            // The copy in the app bundle is this version: use it, no download.
            let name = (entry.file as NSString).deletingPathExtension
            let ext = (entry.file as NSString).pathExtension
            if let bundled = Bundle.main.url(forResource: name, withExtension: ext),
               let bundledData = try? Data(contentsOf: bundled),
               Self.sha1(bundledData) == entry.sha1 {
                continue
            }
            guard let fileURL = URL(string: "\(base)/\(entry.file)"),
                  let (fileData, fileResponse) = try? await URLSession.shared.data(from: fileURL),
                  (fileResponse as? HTTPURLResponse)?.statusCode == 200,
                  Self.sha1(fileData) == entry.sha1,
                  (try? fileData.write(to: dest, options: .atomic)) != nil else { continue }
            kept.insert(entry.file)
        }
        // Anything else in the cache is stale — including the other extension
        // of a figure that switched between PNG and JPEG, which figureURL would
        // otherwise find first.
        for file in (try? fm.contentsOfDirectory(atPath: dir.path)) ?? [] where !kept.contains(file) {
            try? fm.removeItem(at: dir.appendingPathComponent(file))
        }
        try? data.write(to: cachedIndexURL, options: .atomic)
        figureRevision += 1
    }

    private static func sha1(_ data: Data) -> String {
        Insecure.SHA1.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    func entry(_ id: String) -> CrisisProtocol? {
        entries.first { $0.id == id }
    }

    /// Rasterized figures are PNG for line art and JPEG for anything that
    /// embeds a plate or scan (see crisis-content's rasterize-figures.mjs).
    static let figureExtensions = ["png", "jpg"]

    /// Location of a rasterized figure in the content cache, if it has been
    /// fetched. Returns nil when the file isn't present, which lets
    /// FigureBlockView fall back to the app bundle and then to caption-only.
    static func figureURL(_ figureId: String) -> URL? {
        guard !figureId.isEmpty else { return nil }
        let dir = cacheDir.appendingPathComponent("figures", isDirectory: true)
        for ext in figureExtensions {
            let url = dir.appendingPathComponent("\(figureId).\(ext)")
            if FileManager.default.fileExists(atPath: url.path) { return url }
        }
        return nil
    }

    /// Groups by whatever category fields the items themselves carry — no
    /// separate categories list needed (mirrors web's `EntryList.jsx`),
    /// which is what lets this work identically for protocols-only,
    /// procedures-only, or mixed item sets.
    func groupByCategory(_ items: [CrisisProtocol], query: String, initialCategory: String? = nil) -> [(category: (id: String, label: String, order: Int), items: [CrisisProtocol])] {
        let filtered = search(items, query: query)
        let browsing = query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        var grouped: [String: (label: String, order: Int, items: [CrisisProtocol])] = [:]
        for p in filtered {
            let key = p.category ?? ""
            grouped[key, default: (p.categoryLabel ?? "", p.categoryOrder, [])].items.append(p)
            // Cross-listing: primary category is what an entry is; secondaries
            // are where people look for it. Only while browsing — in search
            // results the same hit under two headings is noise.
            if browsing {
                for s in p.secondaryCategories ?? [] {
                    grouped[s.id, default: (s.label, s.order, [])].items.append(p)
                }
            }
        }
        // entryOrder before title: alphabetical alone puts "Awake Fiberoptic
        // Intubation" at the top of Airway, ahead of the CICO entries.
        var groups = grouped.map { (id, v) in
            (category: (id: id, label: v.label, order: v.order),
             items: v.items.sorted { ($0.entryOrder ?? 50, $0.title) < ($1.entryOrder ?? 50, $1.title) })
        }
            .sorted { $0.category.order < $1.category.order }
        if let initialCategory, browsing {
            groups = groups.filter { $0.category.id == initialCategory }
        }
        return groups
    }

    func search(_ protocols: [CrisisProtocol], query: String) -> [CrisisProtocol] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return protocols }
        return protocols.filter {
            $0.title.lowercased().contains(q) ||
            $0.subtitle.lowercased().contains(q) ||
            $0.description.lowercased().contains(q)
        }
    }

    func region(_ id: String) -> EnvenomationRegion? {
        regions.first { $0.id == id }
    }

    func species(in region: EnvenomationRegion, query: String, classFilter: String) -> [Species] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return region.species.filter { s in
            if classFilter != "all", (s.class ?? "") != classFilter { return false }
            if q.isEmpty { return true }
            return s.title.lowercased().contains(q) || s.search.lowercased().contains(q) || s.subtitle.lowercased().contains(q)
        }
    }

    func availableClasses(in region: EnvenomationRegion) -> [String] {
        let set = Set(region.species.compactMap { $0.class })
        let order = ["snake", "spider", "scorpion", "marine", "other"]
        return ["all"] + order.filter { set.contains($0) }
    }
}
