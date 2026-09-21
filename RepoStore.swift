import Foundation
import CryptoKit
import UIKit

enum DLError: Error {
    case badURL
    case http(Int)
    case hashMismatch
    case other(String)
}

enum PatchError: Error {
    case invalidPath
    case sourceNotFound
    case backupFailed
    case applyFailed
    case restoreFailed
    case other(String)
}

enum DownloadState {
    case idle
    case downloading
    case done(URL)
    case failed(DLError)
}

enum LoadState {
    case idle
    case loading
    case loaded
    case failed
}

enum PatchState {
    case idle
    case applying
    case applied
    case restoring
    case restored
    case failed(String)
}

func sha256Hex(of url: URL) throws -> String {
    let data = try Data(contentsOf: url, options: .mappedIfSafe)
    return SHA256.hash(data: data)
        .map { String(format: "%02x", $0) }
        .joined()
}

@MainActor
final class RepoStore: ObservableObject {

    @Published private(set) var manifest: RepoManifest?
    @Published private(set) var loadState: LoadState = .idle
    @Published private(set) var downloads: [String: DownloadState] = [:]
    @Published private(set) var patchStates: [String: PatchState] = [:]

    private var didBootstrap = false

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var cacheURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("repo_default.json")
    }

    private var backupDirectory: URL {
        documentsURL.appendingPathComponent(".ShinnBackups", isDirectory: true)
    }

    var packages: [RepoPackage] {
        manifest?.packages ?? []
    }

    var categories: [CategoryInfo] {
        var order: [String] = []
        var counts: [String: Int] = [:]

        for p in packages {
            let category = p.category ?? "Other"
            if counts[category] == nil {
                order.append(category)
            }
            counts[category, default: 0] += 1
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
        guard
            let data = try? Data(contentsOf: cacheURL),
            let decoded = try? JSONDecoder().decode(RepoManifest.self, from: data)
        else { return }

        manifest = decoded
        loadState = .loaded
    }

    func refresh() async {
        loadState = .loading

        do {
            var request = URLRequest(
                url: AppInfo.defaultRepoURL,
                cachePolicy: .reloadIgnoringLocalCacheData,
                timeoutInterval: 20
            )
            request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

            let (data, response) = try await URLSession.shared.data(for: request)

            if let http = response as? HTTPURLResponse,
               !(200..<300).contains(http.statusCode) {
                throw DLError.http(http.statusCode)
            }

            let decoded = try JSONDecoder().decode(RepoManifest.self, from: data)
            manifest = decoded
            try? data.write(to: cacheURL, options: .atomic)
            loadState = .loaded
        } catch {
            loadState = manifest == nil ? .failed : .loaded
        }
    }

    private func destination(for pkg: RepoPackage) -> URL? {
        guard let url = URL(string: pkg.download) else { return nil }
        return documentsURL.appendingPathComponent(url.lastPathComponent)
    }

    func existingFile(for pkg: RepoPackage) -> URL? {
        guard let destination = destination(for: pkg) else { return nil }
        guard FileManager.default.fileExists(atPath: destination.path) else { return nil }
        return destination
    }

    func state(for pkg: RepoPackage) -> DownloadState {
        if let state = downloads[pkg.id] { return state }
        if let file = existingFile(for: pkg) { return .done(file) }
        return .idle
    }

    func download(_ pkg: RepoPackage) async {
        guard
            let url = URL(string: pkg.download),
            let destination = destination(for: pkg)
        else {
            downloads[pkg.id] = .failed(.badURL)
            return
        }

        downloads[pkg.id] = .downloading

        do {
            let (temporaryURL, response) = try await URLSession.shared.download(from: url)

            if let http = response as? HTTPURLResponse,
               !(200..<300).contains(http.statusCode) {
                throw DLError.http(http.statusCode)
            }

            if let expected = pkg.sha256?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased(),
               !expected.isEmpty {

                let actual = try await Task.detached(priority: .utility) {
                    try sha256Hex(of: temporaryURL)
                }.value

                if actual.lowercased() != expected {
                    try? FileManager.default.removeItem(at: temporaryURL)
                    throw DLError.hashMismatch
                }
            }

            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }

            try FileManager.default.moveItem(at: temporaryURL, to: destination)
            downloads[pkg.id] = .done(destination)
        } catch let error as DLError {
            downloads[pkg.id] = .failed(error)
        } catch {
            downloads[pkg.id] = .failed(.other(error.localizedDescription))
        }
    }

    private func safeDocumentsPath(_ relativePath: String) -> URL? {
        let clean = relativePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !clean.isEmpty, !clean.contains("..") else { return nil }

        let candidate = documentsURL.appendingPathComponent(clean, isDirectory: false)
        let base = documentsURL.standardizedFileURL.path
        let path = candidate.standardizedFileURL.path

        guard path == base || path.hasPrefix(base + "/") else { return nil }
        return candidate
    }

    private func packageArchive(_ pkg: RepoPackage) -> URL? {
        existingFile(for: pkg)
    }

    private func patchDestination(_ pkg: RepoPackage) -> URL? {
        if let custom = pkg.patchPath, !custom.isEmpty {
            return safeDocumentsPath(custom)
        }
        return safeDocumentsPath("Applied/\(pkg.identifier)")
    }

    private func backupURL(for pkg: RepoPackage) -> URL {
        backupDirectory.appendingPathComponent("\(pkg.identifier).backup", isDirectory: false)
    }

    private func createBackupDirectory() throws {
        if !FileManager.default.fileExists(atPath: backupDirectory.path) {
            try FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        }
    }

    private func backupCurrentTarget(_ target: URL, for pkg: RepoPackage) throws {
        try createBackupDirectory()
        let backup = backupURL(for: pkg)

        if FileManager.default.fileExists(atPath: backup.path) {
            try FileManager.default.removeItem(at: backup)
        }

        guard FileManager.default.fileExists(atPath: target.path) else { return }
        try FileManager.default.copyItem(at: target, to: backup)
    }

    func apply(_ pkg: RepoPackage) async {
        patchStates[pkg.id] = .applying

        do {
            guard let archive = packageArchive(pkg) else {
                throw PatchError.sourceNotFound
            }
            guard let destination = patchDestination(pkg) else {
                throw PatchError.invalidPath
            }

            try createBackupDirectory()

            if FileManager.default.fileExists(atPath: destination.path) {
                try backupCurrentTarget(destination, for: pkg)
                try FileManager.default.removeItem(at: destination)
            }

            let parent = destination.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: archive, to: destination)

            patchStates[pkg.id] = .applied
            openTargetApp(for: pkg)
        } catch {
            patchStates[pkg.id] = .failed(errorMessage(error))
        }
    }

    func restore(_ pkg: RepoPackage) async {
        patchStates[pkg.id] = .restoring

        do {
            let backup = backupURL(for: pkg)
            guard FileManager.default.fileExists(atPath: backup.path) else {
                throw PatchError.restoreFailed
            }
            guard let destination = patchDestination(pkg) else {
                throw PatchError.invalidPath
            }

            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }

            let parent = destination.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: backup, to: destination)

            patchStates[pkg.id] = .restored
        } catch {
            patchStates[pkg.id] = .failed(errorMessage(error))
        }
    }

    func patchState(for pkg: RepoPackage) -> PatchState {
        patchStates[pkg.id] ?? .idle
    }

    func openTargetApp(for pkg: RepoPackage) {
        var schemes: [String] = []

        if let raw = pkg.openURL, !raw.isEmpty {
            schemes.append(raw)
        }

        switch (pkg.category ?? "").lowercased() {
        case "free fire":
            schemes += ["freefire://", "com.dts.freefireth://"]
        case "free fire max":
            schemes += ["freefiremax://", "com.dts.freefiremax://"]
        case "liên quân mobile", "lien quan":
            schemes += ["com.garena.game.kgvn://"]
        default:
            break
        }

        for raw in schemes {
            guard let url = URL(string: raw) else { continue }
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                return
            }
        }
    }

    private func errorMessage(_ error: Error) -> String {
        if let patchError = error as? PatchError {
            switch patchError {
            case .invalidPath: return "Đường dẫn patch không hợp lệ."
            case .sourceNotFound: return "Chưa tải package."
            case .backupFailed: return "Không thể tạo bản sao lưu."
            case .applyFailed: return "Không thể áp dụng package."
            case .restoreFailed: return "Không tìm thấy bản sao lưu."
            case .other(let message): return message
            }
        }
        return error.localizedDescription
    }
}