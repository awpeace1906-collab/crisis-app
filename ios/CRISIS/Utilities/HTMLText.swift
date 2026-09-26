import SwiftUI

/// Converts the small HTML subset used across the source content into native
/// SwiftUI text. Two layers:
///
/// - `HTMLText.render` handles INLINE markup (b/strong/i/em/span/a/sub/sup)
///   and returns an AttributedString with no font or color baked in, so the
///   calling view's `.font(...)` and `.foregroundStyle(...)` actually apply.
///   The NSAttributedString HTML importer used before hard-coded both on
///   every run, which made those modifiers silently do nothing (every table
///   cell and step rendered at 15 px). Bold and italic are presentation
///   intents instead of fonts.
///
/// - `HTMLBlocks.parse` splits BLOCK markup (p/br/ul/ol/li) into paragraphs
///   and list items, which `HTMLTextView` lays out as separate views. SwiftUI
///   `Text` drops paragraph styles, so a list rendered inside one Text loses
///   its hanging indent and wrapped lines run back under the bullet.
///
/// Both are cached; inputs are short (a sentence to a paragraph).
enum HTMLText {
    private static var cache: [String: AttributedString] = [:]
    // A tag must start with a letter: the content has literal text like "<60"
    // (already-decoded "&lt;60") that must stay text.
    private static let tag = try! NSRegularExpression(pattern: "<(/?)([a-zA-Z][a-zA-Z0-9]*)([^>]*)>")
    private static let href = try! NSRegularExpression(pattern: "href\\s*=\\s*[\"']([^\"']*)[\"']")
    private static let subDigits = Array("₀₁₂₃₄₅₆₇₈₉"), supDigits = Array("⁰¹²³⁴⁵⁶⁷⁸⁹")

    /// Deliberately NOT NSAttributedString's HTML importer: it spins a nested
    /// run loop (it is WebKit underneath), and calling it from inside a
    /// SwiftUI body, once per table cell and list item, re-enters the view
    /// update and hangs the app with "AttributeGraph: cycle detected". The
    /// content's inline vocabulary is tiny, so a direct scan is both safe and
    /// far faster.
    static func render(_ html: String) -> AttributedString {
        if let cached = cache[html] { return cached }

        var out = AttributedString()
        var bold = 0, italic = 0, sub = 0, sup = 0
        // HTML comments (e.g. crisis-content's colspan placeholder) render as nothing.
        let html = html.replacingOccurrences(of: "<!--[\\s\\S]*?-->", with: "", options: .regularExpression)
        var link: URL?
        let ns = html as NSString

        func emit(_ raw: String) {
            // HTML whitespace rules: any run of whitespace is one space.
            var text = raw.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            text = decode(text)
            if sub > 0 { text = String(text.map { $0.wholeNumberValue.map { subDigits[$0] } ?? $0 }) }
            if sup > 0 { text = String(text.map { $0.wholeNumberValue.map { supDigits[$0] } ?? $0 }) }
            guard !text.isEmpty else { return }
            var piece = AttributedString(text)
            var intent: InlinePresentationIntent = []
            if bold > 0 { intent.insert(.stronglyEmphasized) }
            if italic > 0 { intent.insert(.emphasized) }
            if !intent.isEmpty { piece.inlinePresentationIntent = intent }
            // Bold reads as the brighter text color, matching the web's
            // `.step-desc b { color: var(--text) }`.
            if bold > 0 { piece.foregroundColor = Theme.text }
            if let link { piece.link = link }
            out += piece
        }

        var cursor = 0
        for m in tag.matches(in: html, range: NSRange(location: 0, length: ns.length)) {
            emit(ns.substring(with: NSRange(location: cursor, length: m.range.location - cursor)))
            cursor = m.range.location + m.range.length
            let closing = ns.substring(with: m.range(at: 1)) == "/"
            let delta = closing ? -1 : 1
            switch ns.substring(with: m.range(at: 2)).lowercased() {
            case "b", "strong": bold = max(0, bold + delta)
            case "i", "em": italic = max(0, italic + delta)
            case "sub": sub = max(0, sub + delta)
            case "sup": sup = max(0, sup + delta)
            case "br": out += AttributedString("\n")
            case "a":
                if closing { link = nil } else {
                    let attrs = ns.substring(with: m.range(at: 3))
                    if let h = href.firstMatch(in: attrs, range: NSRange(location: 0, length: (attrs as NSString).length)) {
                        link = URL(string: (attrs as NSString).substring(with: h.range(at: 1)))
                    }
                }
            default: break
            }
        }
        emit(ns.substring(from: cursor))

        // Leading/trailing whitespace from the source's indentation.
        while let first = out.characters.first, first.isWhitespace { out.characters.removeFirst() }
        while let last = out.characters.last, last.isWhitespace { out.characters.removeLast() }
        cache[html] = out
        return out
    }

    /// The built JSON only ever carries these four (cheerio decodes the rest),
    /// plus numeric references for safety.
    private static func decode(_ s: String) -> String {
        guard s.contains("&") else { return s }
        var r = s.replacingOccurrences(of: "&nbsp;", with: "\u{00A0}")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
        if let re = try? NSRegularExpression(pattern: "&#(x?)([0-9a-fA-F]+);") {
            for m in re.matches(in: r, range: NSRange(r.startIndex..., in: r)).reversed() {
                guard let whole = Range(m.range, in: r), let num = Range(m.range(at: 2), in: r),
                      let hex = Range(m.range(at: 1), in: r),
                      let v = UInt32(r[num], radix: r[hex].isEmpty ? 10 : 16),
                      let scalar = Unicode.Scalar(v) else { continue }
                r.replaceSubrange(whole, with: String(Character(scalar)))
            }
        }
        return r.replacingOccurrences(of: "&amp;", with: "&")
    }

    static func plainText(_ html: String) -> String {
        decode(html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression))
    }
}

/// One laid-out piece of a block of HTML.
enum HTMLBlock: Hashable {
    case paragraph(String)
    case bullet(level: Int, html: String)
    case numbered(level: Int, number: Int, html: String)
}

enum HTMLBlocks {
    private static var cache: [String: [HTMLBlock]] = [:]
    private static let tagPattern = try! NSRegularExpression(
        pattern: "<(/?)(p|br|ul|ol|li)\\b[^>]*?/?>", options: [.caseInsensitive])

    static func parse(_ html: String) -> [HTMLBlock] {
        if let cached = cache[html] { return cached }

        var blocks: [HTMLBlock] = []
        var buffer = ""
        // Each open list: ordered?, next number.
        var lists: [(ordered: Bool, next: Int)] = []
        var inItem = false
        var itemNumber = 0

        func flush() {
            let text = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
            buffer = ""
            guard !text.isEmpty else { return }
            if inItem, let list = lists.last {
                let level = max(0, lists.count - 1)
                blocks.append(list.ordered
                    ? .numbered(level: level, number: itemNumber, html: text)
                    : .bullet(level: level, html: text))
            } else {
                blocks.append(.paragraph(text))
            }
        }

        let ns = html as NSString
        var cursor = 0
        for m in tagPattern.matches(in: html, range: NSRange(location: 0, length: ns.length)) {
            buffer += ns.substring(with: NSRange(location: cursor, length: m.range.location - cursor))
            cursor = m.range.location + m.range.length
            let closing = ns.substring(with: m.range(at: 1)) == "/"
            switch ns.substring(with: m.range(at: 2)).lowercased() {
            case "p", "br":
                flush()
            case "ul", "ol":
                flush()
                if closing {
                    if !lists.isEmpty { lists.removeLast() }
                    inItem = !lists.isEmpty
                } else {
                    lists.append((ns.substring(with: m.range(at: 2)).lowercased() == "ol", 1))
                    inItem = false
                }
            case "li":
                flush()
                if closing {
                    inItem = false
                } else if !lists.isEmpty {
                    inItem = true
                    itemNumber = lists[lists.count - 1].next
                    lists[lists.count - 1].next += 1
                }
            default:
                break
            }
        }
        buffer += ns.substring(from: cursor)
        flush()

        cache[html] = blocks
        return blocks
    }
}

/// Renders a source HTML string: paragraphs stacked, list items with a real
/// hanging indent. Takes its font and base color from the environment, so
/// call sites style it exactly like a Text.
struct HTMLTextView: View {
    let html: String
    var spacing: CGFloat = 6

    var body: some View {
        let blocks = HTMLBlocks.parse(html)
        if blocks.count == 1, case .paragraph(let p) = blocks[0] {
            Text(HTMLText.render(p))
        } else {
            VStack(alignment: .leading, spacing: spacing) {
                ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                    switch block {
                    case .paragraph(let p):
                        Text(HTMLText.render(p))
                    case .bullet(let level, let p):
                        item(marker: level == 0 ? "\u{2022}" : "\u{2013}", level: level, html: p)
                    case .numbered(let level, let n, let p):
                        item(marker: "\(n).", level: level, html: p)
                    }
                }
            }
        }
    }

    private func item(marker: String, level: Int, html: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 7) {
            Text(marker)
                .foregroundStyle(Theme.text3)
                .frame(minWidth: 10, alignment: .leading)
            Text(HTMLText.render(html))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, CGFloat(level) * 16)
    }
}
