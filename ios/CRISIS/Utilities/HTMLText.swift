import SwiftUI

/// Converts the small HTML subset used across the source content
/// (b/strong/i/em/span/p/ul/li/br/a) into an AttributedString for native
/// Text rendering. NSAttributedString's HTML importer must run on the main
/// thread, but inputs here are short (a sentence to a paragraph), so the
/// synchronous cost per call is negligible.
enum HTMLText {
    private static var cache: [String: AttributedString] = [:]

    static func render(_ html: String) -> AttributedString {
        if let cached = cache[html] { return cached }

        let wrapped = """
        <span style="font-family: -apple-system; font-size: 15px; color: #e8edf5;">\(html)</span>
        """
        guard let data = wrapped.data(using: .utf8) else { return AttributedString(plainText(html)) }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue,
        ]

        guard let ns = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else {
            return AttributedString(plainText(html))
        }

        let attributed = AttributedString(ns)
        cache[html] = attributed
        return attributed
    }

    private static func plainText(_ html: String) -> String {
        html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&nbsp;", with: " ")
    }
}

/// A Text-like view that renders a source HTML string.
struct HTMLTextView: View {
    let html: String
    var body: some View {
        Text(HTMLText.render(html))
    }
}
