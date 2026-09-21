import Foundation

// MARK: - Shinn Patch Models

struct PatchRule: Codable, Identifiable, Hashable {

    var id: UUID
    var bundleID: String
    var relativePath: String
    var replacementFilename: String
    var replacementData: Data

    init(
        id: UUID = UUID(),
        bundleID: String,
        relativePath: String,
        replacementFilename: String,
        replacementData: Data
    ) {
        self.id = id
        self.bundleID = bundleID
        self.relativePath = relativePath
        self.replacementFilename = replacementFilename
        self.replacementData = replacementData
    }
}

struct PatchDirectory: Codable, Identifiable, Hashable {

    var id: UUID
    var bundleID: String
    var relativePath: String

    init(
        id: UUID = UUID(),
        bundleID: String,
        relativePath: String
    ) {
        self.id = id
        self.bundleID = bundleID
        self.relativePath = relativePath
    }
}

struct PatchProject: Codable, Identifiable, Hashable {

    var id: UUID
    var name: String
    var author: String

    var isPrivate: Bool

    var createdAt: Date
    var updatedAt: Date

    var bundleIdentifiers: [String]

    var directories: [PatchDirectory]
    var rules: [PatchRule]

    init(
        id: UUID = UUID(),
        name: String,
        author: String = "",
        isPrivate: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        bundleIdentifiers: [String] = [],
        directories: [PatchDirectory] = [],
        rules: [PatchRule] = []
    ) {
        self.id = id
        self.name = name
        self.author = author
        self.isPrivate = isPrivate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.bundleIdentifiers = bundleIdentifiers
        self.directories = directories
        self.rules = rules
    }

    var allBundleIdentifiers: [String] {

        var result: [String] = []
        var seen = Set<String>()

        for bundleID in bundleIdentifiers {

            if seen.insert(bundleID).inserted {
                result.append(bundleID)
            }
        }

        for directory in directories {

            if seen.insert(directory.bundleID).inserted {
                result.append(
                    directory.bundleID
                )
            }
        }

        for rule in rules {

            if seen.insert(rule.bundleID).inserted {
                result.append(
                    rule.bundleID
                )
            }
        }

        return result
    }
}

struct DecodedPatchPackage {

    let project: PatchProject

    let contentKey: Data
}

struct PatchPackageSummary:
    Equatable {

    let packageID: UUID

    let schemaVersion: Int

    let isPasswordProtected: Bool

    let keyFingerprint: Data
}

enum PatchPackageError:
    Error,
    LocalizedError {

    case unsupportedFormat

    case unsupportedVersion

    case corruptedPackage

    case passwordProtected

    case invalidProject

    case invalidBundleIdentifier

    case unsafePath

    case duplicateTarget

    case hashMismatch

    case targetBundleNotFound(
        String
    )

    case targetFileNotFound(
        String
    )

    case applyFailed(
        String
    )

    case restoreFailed

    case noIPASelected

    case signingRequired

    var errorDescription: String? {

        switch self {

        case .unsupportedFormat:
            return "File không phải package patch hợp lệ."

        case .unsupportedVersion:
            return "Phiên bản package patch không được hỗ trợ."

        case .corruptedPackage:
            return "Package patch bị lỗi hoặc dữ liệu không hợp lệ."

        case .passwordProtected:
            return "Package này yêu cầu key/password."

        case .invalidProject:
            return "Cấu trúc patch project không hợp lệ."

        case .invalidBundleIdentifier:
            return "Bundle ID trong patch không hợp lệ."

        case .unsafePath:
            return "Patch chứa đường dẫn không an toàn."

        case .duplicateTarget:
            return "Patch có target bị trùng."

        case .hashMismatch:
            return "SHA-256 của package không khớp."

        case .targetBundleNotFound(let bundle):
            return "Không tìm thấy app bundle \(bundle)."

        case .targetFileNotFound(let path):
            return "Không tìm thấy file target: \(path)."

        case .applyFailed(let reason):
            return "Apply patch thất bại: \(reason)"

        case .restoreFailed:
            return "Không thể khôi phục."

        case .noIPASelected:
            return "Bạn chưa chọn IPA."

        case .signingRequired:
            return "IPA đã được sửa và cần được ký lại."
        }
    }
}

// MARK: - Validator

enum PatchValidator {

    static func bundleID(
        _ value: String
    ) throws -> String {

        let value =
            value.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard
            !value.isEmpty,
            value.count <= 255,
            !value.contains("/"),
            !value.contains("\\")
        else {
            throw PatchPackageError
                .invalidBundleIdentifier
        }

        let parts =
            value.split(
                separator: ".",
                omittingEmptySubsequences: false
            )

        guard parts.count >= 2 else {
            throw PatchPackageError
                .invalidBundleIdentifier
        }

        for part in parts {

            guard !part.isEmpty else {
                throw PatchPackageError
                    .invalidBundleIdentifier
            }

            for scalar in part.unicodeScalars {

                let number =
                    scalar.value

                let valid =
                    (48...57).contains(number) ||
                    (65...90).contains(number) ||
                    (97...122).contains(number) ||
                    number == 45

                guard valid else {
                    throw PatchPackageError
                        .invalidBundleIdentifier
                }
            }

            guard
                part.first != "-",
                part.last != "-"
            else {
                throw PatchPackageError
                    .invalidBundleIdentifier
            }
        }

        return value
    }

    static func relativePath(
        _ value: String
    ) throws -> String {

        let value =
            value.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard
            !value.isEmpty,
            !value.hasPrefix("/"),
            !value.contains("\\"),
            !value.contains("//")
        else {
            throw PatchPackageError
                .unsafePath
        }

        let components =
            value.split(
                separator: "/",
                omittingEmptySubsequences: false
            )

        guard components.allSatisfy({
            !$0.isEmpty &&
            $0 != "." &&
            $0 != ".."
        }) else {
            throw PatchPackageError
                .unsafePath
        }

        return components.joined(
            separator: "/"
        )
    }

    static func validate(
        _ project: PatchProject
    ) throws {

        guard
            !project.name
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty
        else {
            throw PatchPackageError
                .invalidProject
        }

        var bundles =
            Set<String>()

        for bundle in
            project.bundleIdentifiers {

            let canonical =
                try bundleID(bundle)

            guard
                canonical == bundle,
                bundles.insert(bundle).inserted
            else {
                throw PatchPackageError
                    .invalidProject
            }
        }

        var targets =
            Set<String>()

        for directory in
            project.directories {

            let bundle =
                try bundleID(
                    directory.bundleID
                )

            let path =
                try relativePath(
                    directory.relativePath
                )

            guard
                bundle == directory.bundleID,
                path == directory.relativePath
            else {
                throw PatchPackageError
                    .invalidProject
            }

            let key =
                "\(bundle)\0\(path)"

            guard
                targets.insert(key).inserted
            else {
                throw PatchPackageError
                    .duplicateTarget
            }
        }

        for rule in
            project.rules {

            let bundle =
                try bundleID(
                    rule.bundleID
                )

            let path =
                try relativePath(
                    rule.relativePath
                )

            guard
                bundle == rule.bundleID,
                path == rule.relativePath,
                !rule.replacementFilename.isEmpty,
                !rule.replacementFilename.contains("/"),
                !rule.replacementFilename.contains("\\")
            else {
                throw PatchPackageError
                    .invalidProject
            }

            let key =
                "\(bundle)\0\(path)"

            guard
                targets.insert(key).inserted
            else {
                throw PatchPackageError
                    .duplicateTarget
            }
        }
    }
}