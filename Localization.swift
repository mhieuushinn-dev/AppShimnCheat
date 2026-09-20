import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case vi, en
    var id: String { rawValue }
    var title: String { self == .vi ? "Tiếng Việt" : "English" }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var titleKey: K {
        switch self {
        case .system: return .themeSystem
        case .light: return .themeLight
        case .dark: return .themeDark
        }
    }
}

final class AppSettings: ObservableObject {
    @Published var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "theme") }
    }
    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "language") }
    }
    @Published var autoRefresh: Bool {
        didSet { UserDefaults.standard.set(autoRefresh, forKey: "autoRefresh") }
    }

    init() {
        let d = UserDefaults.standard
        theme = AppTheme(rawValue: d.string(forKey: "theme") ?? "") ?? .system
        if let raw = d.string(forKey: "language"), let l = AppLanguage(rawValue: raw) {
            language = l
        } else {
            let first = Locale.preferredLanguages.first ?? "en"
            language = first.hasPrefix("vi") ? .vi : .en
        }
        autoRefresh = d.object(forKey: "autoRefresh") as? Bool ?? true
    }

    func t(_ key: K) -> String {
        let pair = key.text
        return language == .vi ? pair.vi : pair.en
    }

    func countText(_ n: Int) -> String {
        if language == .vi { return "\(n) gói" }
        return n == 1 ? "1 package" : "\(n) packages"
    }
}

enum K {
    case heroFree, heroNote, categoriesTitle, allPackages, loadingText, loadFailed, retry
    case settingsTitle, settingsSub, aboutTitle, aboutSub
    case packagesTitle, packageCenter, packageCenterSub, searchPrompt, allLabel, notFound, notFoundDesc
    case versionLabel, authorLabel, categoryLabel, sizeLabel, descriptionLabel
    case downloadAction, downloading, downloaded, redownload, shareAction, savedHint, sha256OK
    case errHash, errHTTP, errURL
    case appearance, themeLabel, themeSystem, themeLight, themeDark, languageLabel
    case autoUpdate, repoSection, defaultSource, defaultBadge, repoLocked, refreshRepo, infoTitle
    case aboutDesc, madeBy, contactTitle, donateTitle, copy, copied
    case featPackages, featRemote, featSHA, featDownload, termsTitle, termsBody
    case supportTitle, telegramSub, reportTitle, reportSub, noteTitle, noteBody
}

extension K {
    var text: (vi: String, en: String) {
        switch self {
        case .heroFree: return ("LÀ APP VÀ REPO HOÀN TOÀN FREE", "A COMPLETELY FREE APP AND REPO")
        case .heroNote: return ("Không bán key • Không khóa thiết bị", "No keys sold • No device lock")
        case .categoriesTitle: return ("DANH MỤC GÓI", "PACKAGE CATEGORIES")
        case .allPackages: return ("Tất cả gói", "All packages")
        case .loadingText: return ("Đang tải repo…", "Loading repo…")
        case .loadFailed: return ("Không tải được repo. Kiểm tra mạng và thử lại.", "Couldn't load the repo. Check your connection and try again.")
        case .retry: return ("Thử lại", "Retry")

        case .settingsTitle: return ("Cài Đặt", "Settings")
        case .settingsSub: return ("Tùy chỉnh app", "Customize the app")
        case .aboutTitle: return ("Giới Thiệu", "About")
        case .aboutSub: return ("Thông tin app", "App information")

        case .packagesTitle: return ("Packages", "Packages")
        case .packageCenter: return ("Package Center", "Package Center")
        case .packageCenterSub: return ("Các package được cung cấp bởi Shinn Cheat", "Packages provided by Shinn Cheat")
        case .searchPrompt: return ("Tìm package", "Search packages")
        case .allLabel: return ("Tất cả", "All")
        case .notFound: return ("Không tìm thấy", "No results")
        case .notFoundDesc: return ("Không có package phù hợp với từ khóa.", "No packages match your search.")

        case .versionLabel: return ("Phiên bản", "Version")
        case .authorLabel: return ("Tác giả", "Author")
        case .categoryLabel: return ("Danh mục", "Category")
        case .sizeLabel: return ("Dung lượng", "Size")
        case .descriptionLabel: return ("Mô tả", "Description")
        case .downloadAction: return ("Tải xuống", "Download")
        case .downloading: return ("Đang tải…", "Downloading…")
        case .downloaded: return ("Đã tải xong", "Downloaded")
        case .redownload: return ("Tải lại", "Download again")
        case .shareAction: return ("Chia sẻ / Mở bằng app khác", "Share / Open in another app")
        case .savedHint: return ("File được lưu trong Tệp › Trên iPhone › Shinn Cheat.", "Saved in Files › On My iPhone › Shinn Cheat.")
        case .sha256OK: return ("Đã xác minh SHA256", "SHA256 verified")
        case .errHash: return ("File tải về không khớp SHA256 nên đã bị hủy.", "The downloaded file failed the SHA256 check and was discarded.")
        case .errHTTP: return ("Lỗi máy chủ", "Server error")
        case .errURL: return ("Link tải không hợp lệ", "Invalid download link")

        case .appearance: return ("Giao diện", "Appearance")
        case .themeLabel: return ("Chủ đề", "Theme")
        case .themeSystem: return ("Theo hệ thống", "System")
        case .themeLight: return ("Sáng", "Light")
        case .themeDark: return ("Tối", "Dark")
        case .languageLabel: return ("Ngôn ngữ", "Language")
        case .autoUpdate: return ("Tự động cập nhật repo", "Auto-refresh repo")
        case .repoSection: return ("Nguồn repo", "Repository")
        case .defaultSource: return ("Nguồn mặc định", "Default source")
        case .defaultBadge: return ("MẶC ĐỊNH", "DEFAULT")
        case .repoLocked: return ("Nguồn mặc định của app, không thể xóa hoặc thay thế.", "The app's built-in source. It can't be removed or replaced.")
        case .refreshRepo: return ("Làm mới repo", "Refresh repo")
        case .infoTitle: return ("Thông tin", "Info")

        case .aboutDesc: return ("Shinn Cheat là ứng dụng quản lý và phân phối các package được cấu hình thông qua repository của Shinn.", "Shinn Cheat is an app for managing and distributing packages configured through Shinn's repository.")
        case .madeBy: return ("App được make bởi Shinn", "App made by Shinn")
        case .contactTitle: return ("Liên hệ", "Contact")
        case .donateTitle: return ("Donate", "Donate")
        case .copy: return ("Sao chép", "Copy")
        case .copied: return ("Đã sao chép", "Copied")
        case .featPackages: return ("Quản lý các package", "Manage packages")
        case .featRemote: return ("Cập nhật dữ liệu từ repository", "Sync data from the repository")
        case .featSHA: return ("Kiểm tra tính toàn vẹn của file", "Verify file integrity")
        case .featDownload: return ("Tải package từ nguồn được cấu hình", "Download packages from the configured source")
        case .termsTitle: return ("Điều khoản sử dụng", "Terms of use")
        case .termsBody:
            return (
                "Khi cài đặt và sử dụng ứng dụng này, bạn đã đồng ý với chính sách của chúng tôi.\n\n• Ứng dụng và repo hoàn toàn MIỄN PHÍ. Tuyệt đối không mua bán ứng dụng hay nội dung trong ứng dụng.\n• Không sử dụng ứng dụng vào bất kỳ hành vi nào trái với pháp luật của Nhà nước.\n• Mọi hành vi phá hoại, cố ý vi phạm sẽ bị cảnh báo.",
                "By installing and using this app, you agree to our policy.\n\n• The app and its repo are completely FREE. Selling the app or any of its content is strictly prohibited.\n• Do not use the app for anything that violates the law.\n• Sabotage or deliberate violations will result in a warning."
            )

        case .supportTitle: return ("Hỗ trợ", "Support")
        case .telegramSub: return ("Liên hệ nhóm hỗ trợ", "Contact the support team")
        case .reportTitle: return ("Báo lỗi", "Report a bug")
        case .reportSub: return ("Thông báo lỗi hoặc sự cố", "Report a bug or issue")
        case .noteTitle: return ("Lưu ý", "Notes")
        case .noteBody: return ("Không chia sẻ thông tin quản trị cho người khác.", "Don't share admin information with anyone.")
        }
    }
}
