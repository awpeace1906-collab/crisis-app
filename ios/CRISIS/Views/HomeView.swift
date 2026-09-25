import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: DataStore
    @State private var query = ""

    private var results: [CrisisProtocol] {
        query.isEmpty ? [] : Array(store.search(store.entries, query: query).prefix(8))
    }

    private func typeIcon(for entry: CrisisProtocol) -> String {
        entry.type == "protocol" ? "⚡" : "✱"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                PageHeader(
                    kicker: "",
                    title: "CRISIS",
                    lede: "Clinical Reference for Immediate Stabilization In Situ"
                )

                SearchField(placeholder: "Search protocols & procedures…", text: $query)

                if !query.isEmpty {
                    if results.isEmpty {
                        EmptyStateView(icon: "🔍", message: "No protocols or procedures match \"\(query)\"")
                    } else {
                        ForEach(results) { p in
                            NavigationLink(value: p) {
                                EntryCard(title: p.title, subtitle: p.description, accent: Theme.color(p.color), typeIcon: typeIcon(for: p))
                            }
                        }
                    }
                } else {
                    Text("Categories")
                        .font(AppFont.display(14))
                        .foregroundStyle(Theme.text)

                    ForEach(store.categories) { cat in
                        NavigationLink(value: cat) {
                            EntryCard(title: cat.label, subtitle: "", accent: Theme.color(cat.color))
                        }
                    }

                    NavigationLink(value: EnvenomationRoute.hub) {
                        EntryCard(
                            title: "Envenomation",
                            subtitle: "\(store.speciesCount) species, \(store.regions.count) regions",
                            accent: Theme.red
                        )
                    }
                }
            }
            .padding(18)
        }
        .background(Theme.bg)
        .buttonStyle(.plain)
        .navigationDestination(for: CrisisProtocol.self) { ProtocolDetailView(protocol: $0) }
        .navigationDestination(for: ProtocolCategory.self) { cat in
            EntryListView(
                kicker: "Category",
                title: cat.label,
                lede: "Protocols and procedures for this category, together.",
                searchPlaceholder: "Search this category…",
                emptyLabel: "Nothing here",
                initialCategory: cat.id
            )
        }
        .navigationDestination(for: EnvenomationRoute.self) { _ in EnvenomationHubView() }
    }
}

enum EnvenomationRoute: Hashable { case hub }
