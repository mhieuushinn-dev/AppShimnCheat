import SwiftUI

struct ContentView: View {
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(open: { path.append($0) })
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .packages(let category):
                        PackagesView(initialCategory: category)
                    case .detail(let id):
                        PackageDetailView(packageID: id)
                    case .settings:
                        SettingsView()
                    case .about:
                        AboutView()
                    case .support:
                        SupportView()
                    }
                }
        }
        .tint(.primary)
    }
}
