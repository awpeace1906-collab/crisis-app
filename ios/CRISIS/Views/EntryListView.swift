import SwiftUI

/// Category-grouped, searchable list — shared by the Protocols tab, the
/// HALO tab, and Home's per-category drill-down. Protocols and procedures
/// share one record shape and live in one `DataStore.entries` array, so the
/// only real difference between call sites is `typeFilter` (nil shows both
/// types mixed, e.g. for a category that holds both) and copy/props.
struct EntryListView: View {
    @EnvironmentObject private var store: DataStore
    @State private var query = ""

    var typeFilter: String? = nil
    let kicker: String
    let title: String
    let lede: String
    let searchPlaceholder: String
    let emptyLabel: String
    var initialCategory: String? = nil

    private var mixed: Bool { typeFilter == nil }

    private var sourceItems: [CrisisProtocol] {
        switch typeFilter {
        case "protocol": return store.protocols
        case "procedure": return store.procedures
        default: return store.entries
        }
    }

    private var grouped: [(category: (id: String, label: String, order: Int), items: [CrisisProtocol])] {
        store.groupByCategory(sourceItems, query: query, initialCategory: initialCategory)
    }

    private func typeIcon(for entry: CrisisProtocol) -> String {
        entry.type == "protocol" ? "⚡" : "✱"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PageHeader(kicker: kicker, title: title, lede: lede)
                SearchField(placeholder: searchPlaceholder, text: $query)

                if grouped.isEmpty {
                    EmptyStateView(icon: "🔍", message: "\(emptyLabel) match \"\(query)\"")
                }

                ForEach(grouped, id: \.category.id) { group in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            Circle().fill(Theme.color(group.items.first?.color ?? "teal")).frame(width: 8, height: 8)
                            Text(group.category.label)
                                .font(AppFont.display(14))
                                .foregroundStyle(Theme.text)
                            Spacer()
                            Text("\(group.items.count)")
                                .font(AppFont.mono(11))
                                .foregroundStyle(Theme.text3)
                        }
                        ForEach(group.items) { p in
                            NavigationLink(value: p) {
                                EntryCard(title: p.title, subtitle: p.description, accent: Theme.color(p.color), typeIcon: mixed ? typeIcon(for: p) : nil)
                            }
                        }
                    }
                }
            }
            .padding(18)
        }
        .background(Theme.bg)
        .buttonStyle(.plain)
        .navigationDestination(for: CrisisProtocol.self) { ProtocolDetailView(protocol: $0) }
        .navigationBarTitleDisplayMode(.inline)
    }
}
