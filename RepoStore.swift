import Foundation
import CryptoKit

enum DLError: Error {
    case badURL
    case http(Int)
    case hashMismatch
    case other(String)
}

enum DownloadState {
    case idle
    case downloading
    case done(URL)
    case failed(DLError)
}

enum LoadState {
    case idle, loading, loaded, failed
}

func sha256Hex(of url: URL) throws -> String {
    let data = try Data(contentsOf: url, options: .mappedIfSafe)
    return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
}

@MainActor
final class RepoStore: ObservableObject {
    @Published private(set) var manifest: RepoManifest?
    @Published private(set) var loadState: LoadState = .idle
    @Published private(set) var downloads: [String: DownloadState] = [:]

    private var didBootstrap = false

    private var cacheURL: URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("repo_default.json")
    }

    var packages: [RepoPackage] { manifest?.packages ?? [] }

    var categories: [CategoryInfo] {
        var order: [String] = []
        var counts: [String: Int] = [:]
        for p in packages {
            let c = p.category ?? "Other"
            if counts[c] == nil { order.append(c) }
            counts[c, default: 0] += 1
        }
        return order.map { CategoryInfo(name: $0, count: counts[$0] ?? 0) }
    }

    func bootstrap(autoRefresh: Bool) async {
        if didBootstrap { return }
        didBootstrap = true
        loadCache()
        if manifest == nil || autoRefresh {
            await refresh()
        }
    }

    private func loadCache() {
        guard let data = try? Data(contentsOf: cacheURL),
              let decoded = try? JSONDecoder().decode(RepoManifest.self, from: data) else { return }
        manifest = decoded
        loadState = .loaded
    }

    func refresh() async {
        loadState = .loading
        do {
            let request = URLRequest(url: AppInfo.defaultRepoURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                throw URLError(.badServerResponse)
            }
            let decoded = try JSONDecoder().decode(RepoManifest.self, from: data)
            manifest = decoded
            try? data.write(to: cacheURL, options: .atomic)
            loadState = .loaded
        } catch {
            if (error as? URLError)?.code == .cancelled {
                loadState = manifest == nil ? .idle : .loaded
            } else {
                loadState = manifest == nil ? .failed : .loaded
            }
        }
    }

    // MARK: - Downloads

    private func destination(for pkg: RepoPackage) -> URL? {
        guard let url = URL(string: pkg.download),
              let docs = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else { return nil }
        return docs.appendingPathComponent(url.lastPathComponent)
    }

    func existingFile(for pkg: RepoPackage) -> URL? {
        guard let dest = destination(for: pkg),
              FileManager.default.fileExists(atPath: dest.path) else { return nil }
        return dest
    }

    func state(for pkg: RepoPackage) -> DownloadState {
        if let s = downloads[pkg.id] { return s }
        if let f = existingFile(for: pkg) { return .done(f) }
        return .idle
    }

    func download(_ pkg: RepoPackage) async {
        guard let url = URL(string: pkg.download), let dest = destination(for: pkg) else {
            downloads[pkg.id] = .failed(.badURL)
            return
        }
        downloads[pkg.id] = .downloading
        do {
            let (tmp, response) = try await URLSession.shared.download(from: url)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                throw DLError.http(http.statusCode)
            }
            if let expected = pkg.sha256?.lowercased(), !expected.isEmpty {
                let tmpCopy = tmp
                let actual = try await Task.detached(priority: .utility) {
                    try sha256Hex(of: tmpCopy)
                }.value
                if actual != expected {
                    try? FileManager.default.removeItem(at: tmp)
                    throw DLError.hashMismatch
                }
            }
            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }
            try FileManager.default.moveItem(at: tmp, to: dest)
            downloads[pkg.id] = .done(dest)
        } catch let e as DLError {
            downloads[pkg.id] = .failed(e)
        } catch {
            downloads[pkg.id] = .failed(.other(error.localizedDescription))
        }
    }
}
