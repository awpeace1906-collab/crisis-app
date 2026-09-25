import SwiftUI

struct EnvenomationRegionView: View {
    @EnvironmentObject private var store: DataStore
    let region: EnvenomationRegion
    @State private var query = ""
    @State private var classFilter = "all"

    private var filtered: [Species] {
        store.species(in: region, query: query, classFilter: classFilter)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                PageHeader(kicker: "Envenomation · \(region.label)", title: region.label, lede: region.lede)
                SearchField(placeholder: "Search species, syndrome, keyword…", text: $query)

                HStack(spacing: 6) {
                    ForEach(store.availableClasses(in: region), id: \.self) { c in
                        ChipView(label: c == "all" ? "All" : c.capitalized, active: classFilter == c) {
                            classFilter = c
                        }
                    }
                }

                if filtered.isEmpty {
                    EmptyStateView(icon: "🔍", message: "No species match.")
                }

                ForEach(filtered) { species in
                    NavigationLink(value: species) {
                        EntryCard(
                            title: species.title,
                            subtitle: species.subtitle,
                            accent: Theme.purple,
                            meta: [species.classTag, species.mechanismTag].compactMap { $0 }.map { ($0, Theme.purple) }
                        )
                    }
                }

                if let nc = region.nonCritical {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(nc.label)
                            .font(AppFont.display(12))
                            .foregroundStyle(Theme.text2)
                        Text(nc.sub)
                            .font(AppFont.serif(13, italic: true))
                            .foregroundStyle(Theme.text2)
                        ForEach(Array(nc.items.enumerated()), id: \.offset) { _, item in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name).font(AppFont.display(13)).foregroundStyle(Theme.text)
                                HTMLTextView(html: item.html)
                                    .font(.system(size: 13.5))
                                    .foregroundStyle(Theme.text2)
                            }
                            .padding(.vertical, 8)
                            Divider().overlay(Theme.border)
                        }
                    }
                    .padding(16)
                    .background(Theme.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.top, 10)
                }
            }
            .padding(18)
        }
        .background(Theme.bg)
        .buttonStyle(.plain)
        .navigationDestination(for: Species.self) { SpeciesDetailView(species: $0, regionId: region.id) }
        .navigationBarTitleDisplayMode(.inline)
    }
}
