import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: DataStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                PageHeader(kicker: "Settings", title: "App Data", lede: "")

                VStack(spacing: 0) {
                    row("Protocols loaded", "\(store.protocols.count)")
                    Divider().overlay(Theme.border)
                    row("Species loaded", "\(store.speciesCount)")
                    Divider().overlay(Theme.border)
                    row("HALO procedures loaded", "\(store.procedures.count)")
                    Divider().overlay(Theme.border)
                    row("Last synced", store.lastSyncedAt.map { $0.formatted(date: .abbreviated, time: .shortened) } ?? "—")
                    Divider().overlay(Theme.border)
                    row("Content build", store.contentCommit.map { String($0.prefix(7)) } ?? "—")
                    Divider().overlay(Theme.border)
                    HStack {
                        Button {
                            Task { await store.refreshFromCDN() }
                        } label: {
                            Text(store.isRefreshing ? "Checking…" : "Check for updates")
                                .font(AppFont.display(12.5))
                        }
                        .disabled(store.isRefreshing)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                }
                .padding(16)
                .background(Theme.surface2)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Text("Content is fetched from a live source and cached on-device for offline use — a correction can ship without an app update. \"Check for updates\" re-fetches now if you have connectivity; otherwise the app keeps working from whatever's cached.")
                    .font(.system(size: 12))
                    .italic()
                    .foregroundStyle(Theme.text3)
            }
            .padding(18)
        }
        .background(Theme.bg)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(AppFont.display(14)).foregroundStyle(Theme.text)
            Spacer()
            Text(value).font(AppFont.mono(12.5)).foregroundStyle(Theme.text2)
        }
        .padding(.vertical, 8)
    }
}
