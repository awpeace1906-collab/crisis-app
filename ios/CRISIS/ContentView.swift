import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: DataStore

    var body: some View {
        if let error = store.loadError {
            VStack(spacing: 10) {
                Text("⚠️").font(.system(size: 36))
                Text(error).foregroundStyle(Theme.text3)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.bg)
        } else {
            TabView {
                NavigationStack { HomeView() }
                    .tabItem { Label("Home", systemImage: "house.fill") }

                NavigationStack {
                    EntryListView(
                        typeFilter: "protocol",
                        kicker: "Crisis Protocols",
                        title: "Protocols",
                        lede: "Anesthesia, resuscitation, toxicologic, obstetric, pediatric, and environmental crises — recognize it, treat it, know why.",
                        searchPlaceholder: "Search protocols…",
                        emptyLabel: "No protocols"
                    )
                }
                .tabItem { Label("Protocols", systemImage: "bolt.fill") }

                NavigationStack {
                    EntryListView(
                        typeFilter: "procedure",
                        kicker: "HALO",
                        title: "High Acuity, Low Occurrence",
                        lede: "Procedures and events rare enough that recall fades between exposures — the ones worth having a reference for precisely because you won't have practiced them recently.",
                        searchPlaceholder: "Search procedures…",
                        emptyLabel: "No procedures"
                    )
                }
                .tabItem { Label("HALO", systemImage: "staroflife.fill") }

                NavigationStack { SettingsView() }
                    .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            }
            .tint(Theme.teal)
            .preferredColorScheme(.dark)
        }
    }
}
