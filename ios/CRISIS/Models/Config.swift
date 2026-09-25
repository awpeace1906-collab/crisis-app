import Foundation

/// Content Update Architecture, 2026-08-31 — mirrors the web app's
/// src/config.js. One place both DataStore's fetch logic and the
/// last-verified/flag-as-outdated UI point at the content repo.
enum ContentConfig {
    static let repo = "awpeace1906-collab/crisis-content"
    static let branch = "main"

    /// jsDelivr's GitHub CDN — see src/config.js for the full rationale
    /// (free, no infra, CI purges this path on every content push).
    static let cdnBase = "https://cdn.jsdelivr.net/gh/\(repo)@\(branch)/dist"

    static func issueURL(kind: String, id: String, title: String, lastVerified: String?) -> URL? {
        var body = "Flagged from the app as possibly outdated.\n\n"
        body += "- Type: \(kind)\n"
        body += "- id: `\(id)`\n"
        body += "- Last verified in the app: \(lastVerified ?? "unknown")\n\n"
        body += "What looks wrong / out of date:\n\n"

        var components = URLComponents(string: "https://github.com/\(repo)/issues/new")
        components?.queryItems = [
            URLQueryItem(name: "title", value: "Outdated: \(title)"),
            URLQueryItem(name: "body", value: body),
            URLQueryItem(name: "labels", value: "flagged-from-app"),
        ]
        return components?.url
    }
}

/// Decoded from crisis-content's dist/manifest.json — ties whatever content
/// is currently loaded back to the exact commit that produced it.
struct ContentManifest: Codable {
    let commit: String
    let builtAt: String
    let version: String
}
