import Foundation

struct EnvenomationBundle: Codable {
    let generatedAt: String
    let regions: [EnvenomationRegion]
}

struct EnvenomationRegion: Codable, Identifiable, Hashable {
    let id: String
    let file: String
    let label: String
    let lede: String
    let species: [Species]
    let nonCritical: NonCritical?

    static func == (lhs: EnvenomationRegion, rhs: EnvenomationRegion) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct Species: Codable, Identifiable, Hashable {
    let id: String?
    let `class`: String?
    let mechanism: String?
    let search: String
    let regionTag: String?
    let classTag: String?
    let mechanismTag: String?
    let title: String
    let subtitle: String
    let fields: [SpeciesField]
    let pearls: Pearls?
    /// Content Update Architecture, 2026-08-31 — see crisis-content's
    /// review-policy.mjs and CrisisProtocol's matching fields.
    let reviewTier: Int?
    let reviewTierIsDefault: Bool?
    let lastVerified: String?
    let reviewDue: String?

    var stableId: String { id ?? title }

    static func == (lhs: Species, rhs: Species) -> Bool { lhs.stableId == rhs.stableId }
    func hash(into hasher: inout Hasher) { hasher.combine(stableId) }
}

struct SpeciesField: Codable, Hashable {
    let label: String
    let html: String
}

struct Pearls: Codable, Hashable {
    let label: String
    let html: String
}

struct NonCritical: Codable, Hashable {
    let label: String
    let sub: String
    let items: [NonCriticalItem]
}

struct NonCriticalItem: Codable, Hashable {
    let name: String
    let html: String
}
