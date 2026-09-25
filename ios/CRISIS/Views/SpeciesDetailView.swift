import SwiftUI

struct SpeciesDetailView: View {
    let species: Species
    let regionId: String
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 6) {
                    if let t = species.regionTag { TagView(text: t, color: Theme.blue) }
                    if let t = species.classTag { TagView(text: t, color: Theme.purple) }
                    if let t = species.mechanismTag { TagView(text: t, color: Theme.amber) }
                }
                Text(species.title)
                    .font(AppFont.display(21))
                    .foregroundStyle(Theme.text)
                Text(species.subtitle)
                    .font(AppFont.serif(14, italic: true))
                    .foregroundStyle(Theme.text2)

                if let lastVerified = species.lastVerified {
                    ReviewMetaView(lastVerified: lastVerified) {
                        if let url = ContentConfig.issueURL(kind: "species", id: "\(regionId)/\(species.stableId)", title: species.title, lastVerified: lastVerified) {
                            openURL(url)
                        }
                    }
                }

                ForEach(Array(species.fields.enumerated()), id: \.offset) { _, field in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(field.label.uppercased())
                            .font(AppFont.mono(10, weight: .semibold))
                            .foregroundStyle(Theme.teal)
                        HTMLTextView(html: field.html)
                            .font(AppFont.serif(14))
                            .foregroundStyle(Theme.text2)
                    }
                    .padding(.vertical, 12)
                    Divider().overlay(Theme.border)
                }

                if let pearls = species.pearls {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(pearls.label.uppercased())
                            .font(AppFont.mono(10, weight: .semibold))
                            .foregroundStyle(Theme.red)
                        HTMLTextView(html: pearls.html)
                            .font(AppFont.serif(14))
                            .foregroundStyle(Theme.text2)
                    }
                    .padding(16)
                    .background(Theme.tint("red"))
                    .overlay(alignment: .leading) { Rectangle().fill(Theme.red).frame(width: 3) }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(18)
        }
        .background(Theme.bg)
        .navigationBarTitleDisplayMode(.inline)
    }
}
