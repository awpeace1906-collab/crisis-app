import SwiftUI

struct SectionBlocksView: View {
    let blocks: [ContentBlock]
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(blocks) { BlockView(block: $0) }
        }
    }
}

struct BlockView: View {
    let block: ContentBlock

    var body: some View {
        switch block.type {
        case "steps":
            StepsBlockView(steps: block.steps ?? [])
        case "box":
            BoxBlockView(color: block.color ?? "teal", html: block.html ?? "")
        case "alert":
            AlertBlockView(color: block.color ?? "red", title: block.title, html: block.html ?? "")
        case "table":
            TableBlockView(headers: block.headers ?? [], rows: block.rows ?? [])
        case "xref":
            XrefBlockView(html: block.html ?? "")
        case "sources":
            SourcesBlockView(items: block.items ?? [])
        case "html":
            HTMLTextView(html: block.html ?? "")
                .font(AppFont.serif(15))
                .foregroundStyle(Theme.text)
                .lineSpacing(3)
        case "tagline":
            HTMLTextView(html: block.html ?? "")
                .font(AppFont.serif(13, italic: true))
                .foregroundStyle(Theme.text2)
        case "figure":
            // SwiftUI has no native SVG rendering, so the diagram itself
            // arrives as a build-time PNG rasterization (see
            // crisis-content/scripts/rasterize-figures.mjs). Until a given
            // figure has been rasterized, still render the caption — it
            // carries real teaching content that shouldn't vanish on iOS.
            FigureBlockView(assetId: block.figureId ?? "", caption: block.caption ?? "", alt: block.alt ?? "")
        default:
            EmptyView()
        }
    }
}

private struct StepsBlockView: View {
    let steps: [ProtocolStep]
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 14) {
                    Text(step.num)
                        .font(AppFont.display(13))
                        .foregroundStyle(Theme.bg)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Theme.color(step.color)))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.title)
                            .font(AppFont.display(14))
                            .foregroundStyle(Theme.text)
                        HTMLTextView(html: step.html, spacing: 5)
                            .font(.system(size: 13.5))
                            .foregroundStyle(Theme.text2)
                            .lineSpacing(2)
                    }
                }
                .padding(.vertical, 11)
                if index < steps.count - 1 {
                    Divider().overlay(Theme.border)
                }
            }
        }
        .padding(16)
        .background(Theme.surface2)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct BoxBlockView: View {
    let color: String
    let html: String
    var body: some View {
        HTMLTextView(html: html, spacing: 8)
            .font(AppFont.serif(15))
            .foregroundStyle(Theme.text)
            .lineSpacing(3)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color == "red" ? Theme.tint("red") : Theme.surface2)
            .overlay(alignment: .leading) {
                Rectangle().fill(Theme.color(color)).frame(width: 3)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct AlertBlockView: View {
    let color: String
    let title: String?
    let html: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let title, !title.isEmpty {
                Text(title.uppercased())
                    .font(AppFont.mono(10.5, weight: .semibold))
                    .foregroundStyle(Theme.color(color))
            }
            HTMLTextView(html: html)
                .font(.system(size: 14))
                .foregroundStyle(Theme.text)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.tint(color))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.color(color).opacity(0.3)))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// Tables are laid out to FIT the screen, never to scroll sideways. The old
/// layout sized every header and body cell independently inside a horizontal
/// ScrollView, so columns never lined up with their headers and wide tables
/// ran off the side of a phone.
///
/// - Two columns: a real grid. The first column has a fixed share of the
///   width, so every row and the header line up, and text wraps.
/// - Three or more: one card per row. The first cell is the card's title and
///   every other cell sits under its own column header. That is the only
///   layout that keeps four columns readable at 375 pt.
private struct TableBlockView: View {
    let headers: [String]
    let rows: [[String]]

    var body: some View {
        Group {
            if max(headers.count, rows.map(\.count).max() ?? 0) >= 3 {
                stacked
            } else {
                twoColumn
            }
        }
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border))
    }

    private func header(_ h: String) -> some View {
        Text(h.uppercased())
            .font(AppFont.mono(10, weight: .semibold))
            .foregroundStyle(Theme.text3)
    }

    private var twoColumn: some View {
        Grid(alignment: .topLeading, horizontalSpacing: 12, verticalSpacing: 0) {
            if !headers.isEmpty {
                GridRow {
                    ForEach(Array(headers.enumerated()), id: \.offset) { i, h in
                        header(h)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .gridColumnAlignment(.leading)
                    }
                }
                .padding(.vertical, 8)
                .background(Theme.surface2)
            }
            ForEach(Array(rows.enumerated()), id: \.offset) { rIndex, row in
                if rIndex > 0 || !headers.isEmpty {
                    Divider().overlay(Theme.border).gridCellUnsizedAxes(.horizontal)
                }
                GridRow {
                    ForEach(Array(row.enumerated()), id: \.offset) { cIndex, cell in
                        HTMLTextView(html: cell, spacing: 4)
                            .font(.system(size: 13.5, weight: cIndex == 0 ? .semibold : .regular))
                            .foregroundStyle(cIndex == 0 ? Theme.text : Theme.text2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.vertical, 9)
            }
        }
        .padding(.horizontal, 12)
    }

    private var stacked: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { rIndex, row in
                VStack(alignment: .leading, spacing: 7) {
                    if let first = row.first {
                        HTMLTextView(html: first, spacing: 4)
                            .font(.system(size: 14.5, weight: .semibold))
                            .foregroundStyle(Theme.text)
                    }
                    ForEach(Array(row.enumerated().dropFirst()), id: \.offset) { cIndex, cell in
                        VStack(alignment: .leading, spacing: 2) {
                            if cIndex < headers.count { header(headers[cIndex]) }
                            HTMLTextView(html: cell, spacing: 4)
                                .font(.system(size: 13.5))
                                .foregroundStyle(Theme.text2)
                        }
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                if rIndex < rows.count - 1 {
                    Divider().overlay(Theme.border)
                }
            }
        }
    }
}

private struct XrefBlockView: View {
    let html: String
    var body: some View {
        HTMLTextView(html: html)
            .font(.system(size: 13.5))
            .foregroundStyle(Theme.text2)
            .padding(.vertical, 10).padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.tint("blue"))
            .overlay(alignment: .leading) {
                Rectangle().fill(Theme.blue).frame(width: 3)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct SourcesBlockView: View {
    let items: [SourceItem]
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 8) {
                    if !item.tier.isEmpty {
                        Text(item.tier)
                            .font(AppFont.mono(9.5))
                            .padding(.horizontal, 6).padding(.vertical, 1)
                            .foregroundStyle(Theme.teal)
                            .background(Theme.tint("teal"))
                            .overlay(RoundedRectangle(cornerRadius: 3).stroke(Theme.teal.opacity(0.3)))
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                    HTMLTextView(html: item.html)
                        .font(.system(size: 12.5))
                        .foregroundStyle(Theme.text2)
                }
                .padding(.vertical, 6)
                if index < items.count - 1 {
                    Divider().overlay(Theme.border)
                }
            }
        }
    }
}

/// Renders a figure: the rasterized diagram when one is available on disk
/// (bundled or in the content cache), plus its caption. Falls back to
/// caption-only rather than an empty space if the image isn't there yet.
struct FigureBlockView: View {
    let assetId: String
    let caption: String
    let alt: String

    private var image: UIImage? {
        guard !assetId.isEmpty else { return nil }
        // 1. A figure fetched from the CDN into the content cache (newest).
        if let cached = DataStore.figureURL(assetId),
           let data = try? Data(contentsOf: cached),
           let img = UIImage(data: data) {
            return img
        }
        // 2. The copy shipped in the app bundle. Note the build flattens
        //    Resources/figures/* to the bundle root, so look it up by
        //    name with no subdirectory — verified against the built .app.
        for ext in DataStore.figureExtensions {
            if let url = Bundle.main.url(forResource: assetId, withExtension: ext),
               let data = try? Data(contentsOf: url),
               let img = UIImage(data: data) {
                return img
            }
        }
        // 3. Asset-catalog lookup, in case a figure is ever added that way.
        return UIImage(named: assetId)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel(alt)
                    .padding(12)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border))
            }
            if !caption.isEmpty {
                HTMLTextView(html: caption)
                    .font(AppFont.serif(12, italic: true))
                    .foregroundStyle(Theme.text2)
            }
        }
    }
}
