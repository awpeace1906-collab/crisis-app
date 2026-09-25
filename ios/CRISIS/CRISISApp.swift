import SwiftUI

@main
struct CRISISApp: App {
    @StateObject private var store = DataStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}
