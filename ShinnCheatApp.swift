import SwiftUI

@main
struct ShinnCheatApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var store = RepoStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(store)
                .preferredColorScheme(settings.theme.colorScheme)
                .task { await store.bootstrap(autoRefresh: settings.autoRefresh) }
        }
    }
}
