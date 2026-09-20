import SwiftUI

struct ContentView: View {
    @State private var route: Route? = nil

    var body: some View {
        NavigationStack {
            HomeView(route: $route)
                .navigationDestination(item: $route) { route in
                    switch route {
                    case .packages:
                        PackagesView()
                    case .settings:
                        SettingsView()
                    case .about:
                        AboutView()
                    case .support:
                        SupportView()
                    case .role:
                        RoleView()
                    }
                }
        }
        .tint(.white)
    }
}

enum Route: String, Identifiable {
    case packages, settings, about, support, role
    var id: String { rawValue }
}
