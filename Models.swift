import Foundation

struct PackageItem: Identifiable, Codable {
    let id: String
    let name: String
    let subtitle: String
    let count: Int
    let icon: String
}

struct RepoManifest: Codable {
    let appName: String?
    let packages: [PackageItem]
}
