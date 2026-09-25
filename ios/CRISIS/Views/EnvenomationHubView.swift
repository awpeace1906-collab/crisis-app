import SwiftUI

struct EnvenomationHubView: View {
    @EnvironmentObject private var store: DataStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                PageHeader(
                    kicker: "Envenomation",
                    title: "By Region",
                    lede: "Species-level reference for critical-intervention bites and stings — onset, syndrome, field and ED management, and antivenom dosing."
                )
                ForEach(store.regions) { region in
                    NavigationLink(value: region) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(region.label)
                                .font(AppFont.display(17))
                                .foregroundStyle(Theme.text)
                            Text(region.lede)
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.text2)
                            Text("\(region.species.count) species")
                                .font(AppFont.mono(10.5))
                                .foregroundStyle(Theme.text3)
                                .padding(.top, 4)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.surface)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border))
                        .overlay(alignment: .leading) {
                            Rectangle().fill(Theme.purple).frame(width: 3)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding(18)
        }
        .background(Theme.bg)
        .buttonStyle(.plain)
        .navigationDestination(for: EnvenomationRegion.self) { EnvenomationRegionView(region: $0) }
        .navigationBarTitleDisplayMode(.inline)
    }
}
