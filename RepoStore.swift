import Foundation
import CryptoKit
import SwiftUI
import UniformTypeIdentifiers

enum DLError: Error {
    case badURL
    case http(Int)
    case hashMismatch
    case other(String)
}

enum PatchState {
    case idle
    case applying
    case applied
    case restoring
    case restored
    case failed(String)
}

enum DownloadState {
    case idle
    case downloading
    case done(URL)
    case failed(DLError)
}

enum LoadState: Equatable {
    case idle
    case loading
    case loaded
    case failed
}

func sha256Hex(
    of url: URL
) throws -> String {

    let data =
        try Data(
            contentsOf: url,
            options: .mappedIfSafe
        )

    return SHA256
        .hash(data: data)
        .map {
            String(
                format: "%02x",
                $0
            )
        }
        .joined()
}

@MainActor
final class RepoStore:
    ObservableObject {

    @Published private(set) var manifest:
        RepoManifest?

    @Published private(set) var loadState:
        LoadState = .idle

    @Published private(set) var downloads:
        [String: DownloadState] = [:]

    @Published private(set) var patchStates:
        [String: PatchState] = [:]

    @Published private(set) var lastOutput:
        [String: URL] = [:]

    private var didBootstrap = false

    private var documentsURL: URL {

        FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
    }

    private var cacheURL: URL {

        FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )[0]
        .appendingPathComponent(
            "repo_default.json"
        )
    }

    var packages: [RepoPackage] {
        manifest?.packages ?? []
    }

    var categories: [CategoryInfo] {

        var order: [String] = []
        var counts: [String: Int] = [:]

        for package in packages {

            let category =
                package.category ?? "Other"

            if counts[category] == nil {
                order.append(category)
            }

            counts[category, default: 0] += 1
        }

        return order.map {
            CategoryInfo(
                name: $0,
                count: counts[$0] ?? 0
            )
        }
    }

    // MARK: Bootstrap

    func bootstrap(
        autoRefresh: Bool
    ) async {

        guard !didBootstrap else {
            return
        }

        didBootstrap = true

        loadCache()

        if manifest == nil ||
            autoRefresh {

            await refresh()
        }
    }

    private func loadCache() {

        guard
            let data =
                try? Data(
                    contentsOf: cacheURL
                ),
            let decoded =
                try? JSONDecoder()
                    .decode(
                        RepoManifest.self,
                        from: data
                    )
        else {
            return
        }

        manifest = decoded
        loadState = .loaded
    }

    // MARK: Remote repo

    func refresh() async {

        loadState = .loading

        do {

            var request =
                URLRequest(
                    url: AppInfo.defaultRepoURL,
                    cachePolicy:
                        .reloadIgnoringLocalCacheData,
                    timeoutInterval: 20
                )

            request.setValue(
                "no-cache",
                forHTTPHeaderField:
                    "Cache-Control"
            )

            let (data, response) =
                try await URLSession.shared.data(
                    for: request
                )

            if let http =
                response as? HTTPURLResponse,
                !(200..<300)
                    .contains(http.statusCode) {

                throw DLError.http(
                    http.statusCode
                )
            }

            let decoded =
                try JSONDecoder()
                    .decode(
                        RepoManifest.self,
                        from: data
                    )

            manifest = decoded

            try? data.write(
                to: cacheURL,
                options: .atomic
            )

            loadState = .loaded

        } catch {

            if manifest == nil {
                loadState = .failed
            } else {
                loadState = .loaded
            }
        }
    }

    // MARK: Download

    private func destination(
        for package: RepoPackage
    ) -> URL? {

        guard
            let url =
                URL(string: package.download)
        else {
            return nil
        }

        return documentsURL
            .appendingPathComponent(
                url.lastPathComponent
            )
    }

    func existingFile(
        for package: RepoPackage
    ) -> URL? {

        guard
            let url =
                destination(for: package),
            FileManager.default.fileExists(
                atPath: url.path
            )
        else {
            return nil
        }

        return url
    }

    func state(
        for package: RepoPackage
    ) -> DownloadState {

        if let state =
            downloads[package.id] {

            return state
        }

        if let file =
            existingFile(for: package) {

            return .done(file)
        }

        return .idle
    }

    func download(
        _ package: RepoPackage
    ) async {

        guard
            let remote =
                URL(string: package.download),
            let destination =
                destination(for: package)
        else {

            downloads[package.id] =
                .failed(.badURL)

            return
        }

        downloads[package.id] =
            .downloading

        do {

            let (
                temporaryURL,
                response
            ) =
                try await URLSession.shared
                    .download(
                        from: remote
                    )

            if let http =
                response as? HTTPURLResponse,
                !(200..<300)
                    .contains(http.statusCode) {

                throw DLError.http(
                    http.statusCode
                )
            }

            if let expected =
                package.sha256?
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .lowercased(),
                !expected.isEmpty {

                let actual =
                    try await Task.detached(
                        priority: .utility
                    ) {
                        try sha256Hex(
                            of: temporaryURL
                        )
                    }.value

                guard actual == expected else {

                    try? FileManager.default
                        .removeItem(
                            at: temporaryURL
                        )

                    throw DLError.hashMismatch
                }
            }

            if FileManager.default.fileExists(
                atPath: destination.path
            ) {

                try FileManager.default
                    .removeItem(
                        at: destination
                    )
            }

            try FileManager.default.moveItem(
                at: temporaryURL,
                to: destination
            )

            downloads[package.id] =
                .done(destination)

        } catch let error as DLError {

            downloads[package.id] =
                .failed(error)

        } catch {

            downloads[package.id] =
                .failed(
                    .other(
                        error.localizedDescription
                    )
                )
        }
    }

    // MARK: Patch

    func apply(
        _ package: RepoPackage,
        ipaURL: URL
    ) async {

        patchStates[package.id] =
            .applying

        do {

            guard
                let packageURL =
                    existingFile(
                        for: package
                    )
            else {
                throw DLError.other(
                    "Chưa tải package."
                )
            }

            let packageData =
                try Data(
                    contentsOf: packageURL
                )

            let decoded =
                try ShinnPatchCodec.decode(
                    packageData,
                    password: nil
                )

            let project =
                decoded.project

            let outputDirectory =
                documentsURL
                    .appendingPathComponent(
                        "Patched",
                        isDirectory: true
                    )

            try FileManager.default
                .createDirectory(
                    at: outputDirectory,
                    withIntermediateDirectories: true
                )

            let outputURL =
                outputDirectory
                    .appendingPathComponent(
                        "\(package.identifier)-ShinnPatched.ipa"
                    )

            let result =
                try IPAPatchEngine.apply(
                    ipaURL: ipaURL,
                    project: project,
                    outputURL: outputURL
                )

            lastOutput[package.id] =
                result.outputURL

            patchStates[package.id] =
                .applied

        } catch {

            patchStates[package.id] =
                .failed(
                    error.localizedDescription
                )
        }
    }

    func restore(
        _ package: RepoPackage
    ) async {

        patchStates[package.id] =
            .restoring

        if let output =
            lastOutput[package.id] {

            try? FileManager.default
                .removeItem(
                    at: output
                )

            lastOutput.removeValue(
                forKey: package.id
            )

            patchStates[package.id] =
                .restored

        } else {

            patchStates[package.id] =
                .failed(
                    "Không tìm thấy IPA đã xuất."
                )
        }
    }

    func patchState(
        for package: RepoPackage
    ) -> PatchState {

        patchStates[package.id] ??
            .idle
    }

    func outputURL(
        for package: RepoPackage
    ) -> URL? {

        lastOutput[package.id]
    }
}