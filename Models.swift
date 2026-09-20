import Foundation

enum AppInfo {
    static let telegramHandle = "@ShinnThieuu"
    static let telegramURL = URL(string: "https://t.me/ShinnThieuu")!
    static let bankName = "MB Bank"
    static let bankAccount = "104877777"
    static let defaultRepoName = "Shinn Cheat Share"
    static let defaultRepoURL = URL(string: "https://raw.githubusercontent.com/mhieuushinn-dev/ShinnCheatShare/main/ShinnThieuu.json")!

    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "2.0"
    }
}

struct RepoManifest: Codable {
    let name: String?
    let description: String?
    let icon: String?
    let packages: [RepoPackage]
}

struct RepoPackage: Codable, Identifiable, Hashable {
    let identifier: String
    let name: String
    let author: String?
    let version: String?
    let summary: String?
    let description: String?
    let category: String?
    let tags: [String]?
    let download: String
    let sha256: String?
    let size: Int?
    let icon: String?

    var id: String { identifier }
}

struct CategoryInfo: Identifiable {
    let name: String
    let count: Int
    var id: String { name }
}

enum Route: Hashable {
    case packages(String?)
    case detail(String)
    case settings
    case about
    case support
}

func formatBytes(_ n: Int) -> String {
    ByteCountFormatter.string(fromByteCount: Int64(n), countStyle: .file)
}
