import SwiftUI

// MARK: - Packages View

struct PackagesView: View {

    @State private var searchText = ""

    private let packageCategories = [
        "Free Fire",
        "Free Fire Max",
        "MOD VIP"
    ]

    private var filteredCategories: [String] {
        let query = searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if query.isEmpty {
            return packageCategories
        }

        return packageCategories.filter {
            $0.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {

                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Package Center")
                            .font(.system(size: 30, weight: .bold))

                        Text("Các package được cung cấp bởi Shinn Cheat")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    // Categories
                    ForEach(filteredCategories, id: \.self) { category in
                        PackageCategoryCard(
                            title: category
                        )
                    }

                    if filteredCategories.isEmpty {
                        ContentUnavailableView(
                            "Không tìm thấy",
                            systemImage: "magnifyingglass",
                            description: Text(
                                "Không có package phù hợp với từ khóa."
                            )
                        )
                        .padding(.top, 40)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Packages")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $searchText,
                prompt: "Tìm package"
            )
        }
    }
}

// MARK: - Package Category Card

private struct PackageCategoryCard: View {

    let title: String

    private var icon: String {
        switch title {
        case "Free Fire":
            return "flame.fill"

        case "Free Fire Max":
            return "sparkles"

        case "MOD VIP":
            return "crown.fill"

        default:
            return "shippingbox.fill"
        }
    }

    var body: some View {
        HStack(spacing: 16) {

            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial)

                Image(systemName: icon)
                    .font(.system(size: 23, weight: .semibold))
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))

                Text("Xem các package")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    Color.primary.opacity(0.08),
                    lineWidth: 1
                )
        )
        .padding(.horizontal)
    }
}

// MARK: - Settings

struct SettingsView: View {

    @AppStorage("notificationsEnabled")
    private var notificationsEnabled = true

    @AppStorage("autoRefreshEnabled")
    private var autoRefreshEnabled = true

    var body: some View {
        NavigationStack {
            List {

                Section("Ứng dụng") {

                    Toggle(
                        "Thông báo",
                        isOn: $notificationsEnabled
                    )

                    Toggle(
                        "Tự động cập nhật",
                        isOn: $autoRefreshEnabled
                    )
                }

                Section("Giao diện") {

                    HStack {
                        Label(
                            "Chủ đề",
                            systemImage: "circle.lefthalf.filled"
                        )

                        Spacer()

                        Text("Tự động")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label(
                            "Phong cách",
                            systemImage: "rectangle.on.rectangle"
                        )

                        Spacer()

                        Text("Glass")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Thông tin") {

                    HStack {
                        Label(
                            "Phiên bản",
                            systemImage: "info.circle"
                        )

                        Spacer()

                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Cài Đặt")
        }
    }
}

// MARK: - About

struct AboutView: View {

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Logo
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)

                        Image(systemName: "crown.fill")
                            .font(
                                .system(
                                    size: 48,
                                    weight: .semibold
                                )
                            )
                    }
                    .frame(width: 110, height: 110)

                    // Name
                    VStack(spacing: 6) {

                        Text("SHINN CHEAT")
                            .font(
                                .system(
                                    size: 28,
                                    weight: .bold
                                )
                            )

                        Text("Play Smart • Stay Ahead")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Description
                    Text(
                        """
                        Shinn Cheat là ứng dụng quản lý và \
                        phân phối các package được cấu hình \
                        thông qua repository của Shinn.
                        """
                    )
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)

                    // Features
                    VStack(spacing: 12) {

                        InfoCard(
                            icon: "shippingbox.fill",
                            title: "Package Center",
                            subtitle: "Quản lý các package"
                        )

                        InfoCard(
                            icon: "arrow.triangle.2.circlepath",
                            title: "Remote JSON",
                            subtitle: "Cập nhật dữ liệu từ repository"
                        )

                        InfoCard(
                            icon: "checkmark.shield.fill",
                            title: "SHA256",
                            subtitle: "Kiểm tra tính toàn vẹn của file"
                        )

                        InfoCard(
                            icon: "icloud.and.arrow.down.fill",
                            title: "Download",
                            subtitle: "Tải package từ nguồn được cấu hình"
                        )
                    }
                    .padding(.horizontal)

                    Text("© 2026 Shinn Cheat")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
                .padding(.vertical, 30)
            }
            .navigationTitle("Giới Thiệu")
        }
    }
}

// MARK: - Info Card

private struct InfoCard: View {

    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {

            ZStack {
                RoundedRectangle(cornerRadius: 13)
                    .fill(.ultraThinMaterial)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 3) {

                Text(title)
                    .font(.system(size: 16, weight: .semibold))

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    Color.primary.opacity(0.07),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Support

struct SupportView: View {

    var body: some View {
        NavigationStack {
            List {

                Section("Hỗ trợ") {

                    SupportRow(
                        icon: "paperplane.fill",
                        title: "Telegram",
                        subtitle: "Liên hệ nhóm hỗ trợ"
                    )

                    SupportRow(
                        icon: "questionmark.circle.fill",
                        title: "Trợ giúp",
                        subtitle: "Xem hướng dẫn sử dụng"
                    )

                    SupportRow(
                        icon: "exclamationmark.triangle.fill",
                        title: "Báo lỗi",
                        subtitle: "Thông báo lỗi hoặc sự cố"
                    )
                }

                Section("Lưu ý") {

                    Text(
                        """
                        Không chia sẻ thông tin quản trị \
                        cho người khác.
                        """
                    )
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Support")
        }
    }
}

// MARK: - Support Row

private struct SupportRow: View {

    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {

            Image(systemName: icon)
                .font(.system(size: 18))
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 3) {

                Text(title)
                    .font(.system(size: 16, weight: .medium))

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 5)
    }
}

// MARK: - Role View

struct RoleView: View {

    var body: some View {
        NavigationStack {
            List {

                RoleRow(
                    icon: "person.fill",
                    title: "Member",
                    description:
                        "Người dùng thông thường."
                )

                RoleRow(
                    icon: "headphones",
                    title: "Support",
                    description:
                        "Hỗ trợ người dùng và tiếp nhận báo lỗi."
                )

                RoleRow(
                    icon: "person.badge.key.fill",
                    title: "Admin",
                    description:
                        "Quản lý nội dung repository theo quyền được cấp."
                )

                RoleRow(
                    icon: "crown.fill",
                    title: "Owner",
                    description:
                        "Quản lý toàn bộ hệ thống repository."
                )
            }
            .navigationTitle("Vai Trò")
        }
    }
}

// MARK: - Role Row

private struct RoleRow: View {

    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 14) {

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)

                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {

                Text(title)
                    .font(
                        .system(
                            size: 16,
                            weight: .semibold
                        )
                    )

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 5)
    }
}

// MARK: - Preview

#Preview {
    PackagesView()
}