import SwiftUI

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
                    Toggle("Thông báo", isOn: $notificationsEnabled)

                    Toggle("Tự động cập nhật", isOn: $autoRefreshEnabled)
                }

                Section("Giao diện") {
                    HStack {
                        Text("Chủ đề")
                        Spacer()
                        Text("Tự động")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Phong cách")
                        Spacer()
                        Text("Glass")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Thông tin") {
                    HStack {
                        Text("Phiên bản")
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

                    Image(systemName: "crown.fill")
                        .font(.system(size: 54))
                        .foregroundStyle(.primary)
                        .padding(24)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                        )

                    Text("SHINN CHEAT")
                        .font(.system(size: 28, weight: .bold))

                    Text("Play Smart • Stay Ahead")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(
                        "Shinn Cheat là ứng dụng quản lý và phân phối các gói "
                        + "được cấu hình từ repository của Shinn."
                    )
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 14) {
                        InfoRow(
                            icon: "arrow.down.circle.fill",
                            title: "Package Center",
                            subtitle: "Quản lý các gói được cung cấp"
                        )

                        InfoRow(
                            icon: "arrow.triangle.2.circlepath",
                            title: "Remote JSON",
                            subtitle: "Cập nhật dữ liệu từ repository"
                        )

                        InfoRow(
                            icon: "shield.fill",
                            title: "SHA256",
                            subtitle: "Kiểm tra tính toàn vẹn của file"
                        )
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.ultraThinMaterial)
                    )
                    .padding(.horizontal)

                    Text("© 2026 Shinn Cheat")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 30)
            }
            .navigationTitle("Giới Thiệu")
        }
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
                        "Không chia sẻ thông tin tài khoản quản trị "
                        + "cho người khác."
                    )
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Support")
        }
    }
}

// MARK: - Role

struct RoleView: View {
    var body: some View {
        NavigationStack {
            List {
                RoleRow(
                    icon: "person.fill",
                    title: "Member",
                    description: "Người dùng thông thường."
                )

                RoleRow(
                    icon: "headphones",
                    title: "Support",
                    description: "Hỗ trợ người dùng và tiếp nhận báo lỗi."
                )

                RoleRow(
                    icon: "person.badge.key.fill",
                    title: "Admin",
                    description: "Quản lý nội dung repository theo quyền được cấp."
                )

                RoleRow(
                    icon: "crown.fill",
                    title: "Owner",
                    description: "Quản lý toàn bộ hệ thống repository."
                )
            }
            .navigationTitle("Vai Trò")
        }
    }
}

// MARK: - Components

private struct InfoRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .frame(width: 34, height: 34)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.thinMaterial)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

private struct SupportRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct RoleRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .frame(width: 34)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SettingsView()
}