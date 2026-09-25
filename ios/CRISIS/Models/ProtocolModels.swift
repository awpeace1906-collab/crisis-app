import Foundation

struct ProtocolBundle: Codable {
    let generatedAt: String
    let categories: [ProtocolCategory]
    let protocols: [CrisisProtocol]
    let pending: [PendingProtocol]
}

/// HALO procedures share the exact same JSON shape as protocols (see
/// extract-procedures.mjs), so this reuses CrisisProtocol/ProtocolSection/
/// ContentBlock rather than duplicating a parallel model hierarchy — only
/// the top-level key name ("procedures" vs "protocols") differs.
struct ProcedureBundle: Codable {
    let generatedAt: String
    let categories: [ProtocolCategory]
    let procedures: [CrisisProtocol]
    let pending: [PendingProtocol]
}

struct ProtocolCategory: Codable, Identifiable, Hashable {
    let id: String
    let label: String
    let color: String
    let order: Int
}

struct PendingProtocol: Codable, Identifiable {
    var id: String { file }
    let file: String
    let categoryId: String
    let categoryLabel: String
    let categoryOrder: Int
    let color: String
    let description: String
}

struct Badge: Codable, Hashable {
    let color: String
    let text: String
}

/// A resolved category placement — crisis-content emits these for
/// `secondaryCategories` so the app never has to look labels up.
struct CategoryRef: Codable, Hashable {
    let id: String
    let label: String
    let order: Int
}

struct CrisisProtocol: Codable, Identifiable, Hashable {
    let id: String
    /// "protocol" or "procedure" — both content types share this exact
    /// shape and now live in one unified `DataStore.entries` array.
    let type: String
    let file: String
    let title: String
    let kicker: String
    let subtitle: String
    let badges: [Badge]
    let category: String?
    let categoryLabel: String?
    let categoryOrder: Int
    /// Within-category sort key (crisis-content's ENTRY_ORDER, default 50).
    /// Optional because the bundled offline snapshot may predate it.
    let entryOrder: Int?
    /// Extra categories this entry also lists under — e.g. a surgical airway
    /// is primary Airway but also surfaces under Anesthesia. Optional for the
    /// same reason as `entryOrder`.
    let secondaryCategories: [CategoryRef]?
    let color: String
    let description: String
    /// Content Update Architecture, 2026-08-31 — see crisis-content's
    /// review-policy.mjs. `reviewTierIsDefault` is true when the source file
    /// never declared data-review-tier/data-last-verified and this is just
    /// the pipeline's fallback, not a real classification.
    let reviewTier: Int?
    let reviewTierIsDefault: Bool?
    let lastVerified: String?
    let reviewDue: String?
    let sections: [ProtocolSection]
    let footer: String

    static func == (lhs: CrisisProtocol, rhs: CrisisProtocol) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct ProtocolSection: Codable, Identifiable, Hashable {
    let id: String
    let num: String
    let color: String
    let title: String
    let tagline: String?
    let blocks: [ContentBlock]

    static func == (lhs: ProtocolSection, rhs: ProtocolSection) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// A single content block within a section. Source JSON is a discriminated
/// union on `type`; the payload fields relevant to that type are populated,
/// others left nil. Kept as one flat struct rather than a Swift enum so
/// Codable decoding stays simple against the extractor's JSON shape.
struct ContentBlock: Codable, Identifiable, Hashable {
    let type: String
    // steps
    let steps: [ProtocolStep]?
    // box / alert / xref / html
    let color: String?
    let title: String?
    let html: String?
    // table
    let headers: [String]?
    let rows: [[String]]?
    // figure — `figureId` (not `id`) because `id` below is the computed
    // Identifiable conformance. `svg` is decoded but unused on iOS, which
    // renders the build-time PNG rasterization instead.
    let figureId: String?
    let svg: String?
    let alt: String?
    let caption: String?
    // sources
    let items: [SourceItem]?

    // Must be genuinely unique per block, not just per section — a section
    // can hold several `steps` blocks back-to-back (e.g. Intraosseous
    // Access's humerus/sternal/tibial technique variants) whose individual
    // ProtocolStep entries have no `.step-title` in the source HTML, so
    // `html`/`title` alone collapse to the same id for all of them. That
    // previously made every steps block in a multi-technique section
    // compare equal and share one SwiftUI identity, so scrolling caused
    // later blocks to render the first block's stale content. Fold in the
    // actual step/row/source text so distinct blocks never collide.
    var id: String {
        var parts = [type, html ?? "", title ?? ""]
        if let steps { parts.append(contentsOf: steps.flatMap { [$0.title, $0.html] }) }
        if let rows { parts.append(contentsOf: rows.flatMap { $0 }) }
        if let items { parts.append(contentsOf: items.map { $0.html }) }
        // Figures carry no html/title, so without these two a section with
        // more than one diagram would collapse them to a single identity —
        // the same collision class as the steps-block bug described above.
        if let figureId { parts.append(figureId) }
        if let caption { parts.append(caption) }
        return parts.joined(separator: "|")
    }

    static func == (lhs: ContentBlock, rhs: ContentBlock) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct ProtocolStep: Codable, Hashable {
    let num: String
    let color: String
    let title: String
    let html: String
}

struct SourceItem: Codable, Hashable {
    let tier: String
    let html: String
}
