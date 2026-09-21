import Foundation
import ZIPFoundation

enum IPAPatchEngineError: Error, LocalizedError {
    case invalidIPA
    case noApplicationBundle
    case bundleIdentifierNotFound
    case targetBundleMismatch(String)
    case unsafePath
    case replacementWriteFailed
    case archiveFailed

    var errorDescription: String? {
        switch self {
        case .invalidIPA:
            return "File IPA không hợp lệ."

        case .noApplicationBundle:
            return "Không tìm thấy Payload/*.app."

        case .bundleIdentifierNotFound:
            return "Không đọc được Bundle Identifier."

        case .targetBundleMismatch(let id):
            return "Bundle Identifier không khớp: \(id)"

        case .unsafePath:
            return "Đường dẫn patch không an toàn."

        case .replacementWriteFailed:
            return "Không thể ghi file thay thế."

        case .archiveFailed:
            return "Không thể tạo IPA mới."
        }
    }
}

struct IPAPatchResult {
    let outputURL: URL
    let bundleIdentifier: String
    let appliedRules: Int
}

enum IPAPatchEngine {

    static func apply(
        ipaURL: URL,
        project: PatchProject,
        outputURL: URL
    ) throws -> IPAPatchResult {

        try ShinnPatchCodec.validate(project)

        let fm = FileManager.default

        let workspace =
            fm.temporaryDirectory
                .appendingPathComponent(
                    "ShinnPatch-\(UUID().uuidString)",
                    isDirectory: true
                )

        try fm.createDirectory(
            at: workspace,
            withIntermediateDirectories: true
        )

        defer {
            try? fm.removeItem(
                at: workspace
            )
        }

        let extracted =
            workspace.appendingPathComponent(
                "Extracted",
                isDirectory: true
            )

        try fm.createDirectory(
            at: extracted,
            withIntermediateDirectories: true
        )

        do {
            try fm.unzipItem(
                at: ipaURL,
                to: extracted
            )
        } catch {
            throw IPAPatchEngineError.invalidIPA
        }

        let payload =
            extracted.appendingPathComponent(
                "Payload",
                isDirectory: true
            )

        guard fm.fileExists(
            atPath: payload.path
        ) else {
            throw IPAPatchEngineError.noApplicationBundle
        }

        let apps =
            try fm.contentsOfDirectory(
                at: payload,
                includingPropertiesForKeys: [
                    .isDirectoryKey
                ],
                options: [.skipsHiddenFiles]
            )
            .filter {
                $0.pathExtension.lowercased() == "app"
            }

        guard
            let appBundle = apps.first
        else {
            throw IPAPatchEngineError.noApplicationBundle
        }

        guard
            let infoURL =
                BundleInfo.plistURL(
                    in: appBundle
                ),
            let info =
                NSDictionary(
                    contentsOf: infoURL
                ),
            let bundleID =
                info["CFBundleIdentifier"] as? String
        else {
            throw IPAPatchEngineError
                .bundleIdentifierNotFound
        }

        if !project.bundleIdentifiers.isEmpty &&
            !project.bundleIdentifiers.contains(bundleID) {

            throw IPAPatchEngineError
                .targetBundleMismatch(bundleID)
        }

        var applied = 0

        for rule in project.rules {

            guard
                rule.bundleID == bundleID
            else {
                continue
            }

            let target =
                try safeTarget(
                    root: appBundle,
                    relativePath: rule.relativePath
                )

            let parent =
                target.deletingLastPathComponent()

            try fm.createDirectory(
                at: parent,
                withIntermediateDirectories: true
            )

            do {
                try rule.replacementData.write(
                    to: target,
                    options: .atomic
                )

                applied += 1

            } catch {
                throw IPAPatchEngineError
                    .replacementWriteFailed
            }
        }

        /*
         Không cố gắng ký lại IPA ở trên iOS.

         Sau khi nội dung .app thay đổi, chữ ký hiện tại
         không còn hợp lệ. IPA đầu ra phải được ký lại bằng
         môi trường signing hợp lệ trước khi cài.
        */

        if fm.fileExists(
            atPath: outputURL.path
        ) {
            try fm.removeItem(
                at: outputURL
            )
        }

        do {
            try fm.zipItem(
                at: extracted,
                to: outputURL
            )
        } catch {
            throw IPAPatchEngineError.archiveFailed
        }

        return IPAPatchResult(
            outputURL: outputURL,
            bundleIdentifier: bundleID,
            appliedRules: applied
        )
    }

    private static func safeTarget(
        root: URL,
        relativePath: String
    ) throws -> URL {

        let normalized =
            try PatchPathValidator
                .canonicalRelativePath(
                    relativePath
                )

        let target =
            root
                .appendingPathComponent(
                    normalized,
                    isDirectory: false
                )
                .standardizedFileURL

        guard
            target.path.hasPrefix(
                root.standardizedFileURL.path + "/"
            )
        else {
            throw IPAPatchEngineError.unsafePath
        }

        return target
    }
}

private enum BundleInfo {

    static func plistURL(
        in appURL: URL
    ) -> URL? {

        let url =
            appURL.appendingPathComponent(
                "Info.plist"
            )

        return FileManager.default.fileExists(
            atPath: url.path
        )
        ? url
        : nil
    }
}