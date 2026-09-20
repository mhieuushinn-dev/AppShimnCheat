import SwiftUI
import UIKit

// MARK: - Settings

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var store: RepoStore

    var body: some View {
        List {
            Section(settings.t(.appearance)) {
                Picker(selection: $settings.theme) {
                    ForEach(AppTheme.allCases) { item in
                        Text(settings.t(item.titleKey)).tag(item)
                    }
                } label: {
                    Label(settings.t(.themeLabel), systemImage: "circle.lefthalf.filled")
                }

                Picker(selection: $settings.language) {
                    ForEach(AppLanguage.allCases) { item in
                        Text(item.title).tag(item)
                    }
                } label: {
                    Label(settings.t(.languageLabel), systemImage: "globe")
                }
            }
            .listRowBackground(Color.primary.opacity(0.07))

            Section {
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.manifest?.name ?? AppInfo.defaultRepoName)
                            .font(.system(size: 16, weight: .semibold))
                        Text(AppInfo.defaultRepoURL.absoluteString)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Spacer()
                    Text(settings.t(.defaultBadge))
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.primary.opacity(0.12), in: Capsule())
                }

                Toggle(isOn: $settings.autoRefresh) {
                    Label(settings.t(.autoUpdate), systemImage: "arrow.triangle.2.circlepath")
                }

                Button {
                    Task { await store.refresh() }
                } label: {
                    HStack {
                        Label(settings.t(.refreshRepo), systemImage: "arrow.clockwise")
                        Spacer()
                        if store.loadState == .loading {
                            ProgressView()
                        }
                    }
                }
            } header: {
                Text(settings.t(.repoSection))
            } footer: {
                Text(settings.t(.repoLocked))
            }
            .listRowBackground(Color.primary.opacity(0.07))

            Section(settings.t(.infoTitle)) {
                HStack {
                    Label(settings.t(.versionLabel), systemImage: "info.circle")
                    Spacer()
                    Text(AppInfo.version).foregroundStyle(.secondary)
                }
            }
            .listRowBackground(Color.primary.opacity(0.07))
        }
        .scrollContentBackground(.hidden)
        .background(BackgroundView())
        .navigationTitle(settings.t(.settingsTitle))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - About

struct AboutView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var copied = false

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 46, weight: .semibold))
                    .frame(width: 108, height: 108)
                    .background(Color.primary.opacity(0.08), in: Circle())

                VStack(spacing: 6) {
                    Text("SHINN CHEAT")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text("Play Smart • Stay Ahead")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Pill(text: settings.t(.madeBy))
                        .padding(.top, 6)
                }

                Text(settings.t(.aboutDesc))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)

                VStack(spacing: 12) {
                    Text(settings.t(.contactTitle))
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Link(destination: AppInfo.telegramURL) {
                        ContactRow(icon: "paperplane.fill", title: "Telegram", value: AppInfo.telegramHandle, trailing: "arrow.up.right")
                    }
                    .buttonStyle(.plain)

                    Button {
                        UIPasteboard.general.string = AppInfo.bankAccount
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                    } label: {
                        ContactRow(
                            icon: "heart.fill",
                            title: settings.t(.donateTitle) + " • " + AppInfo.bankName,
                            value: AppInfo.bankAccount,
                            trailing: copied ? "checkmark" : "doc.on.doc"
                        )
                    }
                    .buttonStyle(.plain)

                    if copied {
                        Text(settings.t(.copied))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(spacing: 12) {
                    InfoCard(icon: "shippingbox.fill", title: "Package Center", subtitle: settings.t(.featPackages))
                    InfoCard(icon: "arrow.triangle.2.circlepath", title: "Remote JSON", subtitle: settings.t(.featRemote))
                    InfoCard(icon: "checkmark.shield.fill", title: "SHA256", subtitle: settings.t(.featSHA))
                    InfoCard(icon: "icloud.and.arrow.down.fill", title: "Download", subtitle: settings.t(.featDownload))
                }

                VStack(alignment: .leading, spacing: 10) {
                    Label(settings.t(.termsTitle), systemImage: "doc.text.fill")
                        .font(.headline)
                    Text(settings.t(.termsBody))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .shinnGlass(radius: 20)

                Text("© 2026 Shinn Cheat • v" + AppInfo.version)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 24)
        }
        .background(BackgroundView())
        .navigationTitle(settings.t(.aboutTitle))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ContactRow: View {
    let icon: String
    let title: String
    let value: String
    let trailing: String

    var body: some View {
        HStack(spacing: 14) {
            IconBox(systemName: icon, size: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 15, weight: .semibold))
                Text(value).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: trailing)
                .font(.footnote.bold())
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .contentShape(Rectangle())
        .shinnGlass(radius: 18)
    }
}

struct InfoCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            IconBox(systemName: icon, size: 46)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 16, weight: .semibold))
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .shinnGlass(radius: 20)
    }
}

// MARK: - Support

struct SupportView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        List {
            Section(settings.t(.supportTitle)) {
                Link(destination: AppInfo.telegramURL) {
                    SupportRow(icon: "paperplane.fill", title: "Telegram", subtitle: settings.t(.telegramSub))
                }
                Link(destination: AppInfo.telegramURL) {
                    SupportRow(icon: "exclamationmark.triangle.fill", title: settings.t(.reportTitle), subtitle: settings.t(.reportSub))
                }
            }
            .listRowBackground(Color.primary.opacity(0.07))

            Section(settings.t(.noteTitle)) {
                Text(settings.t(.noteBody))
                    .foregroundStyle(.secondary)
            }
            .listRowBackground(Color.primary.opacity(0.07))
        }
        .scrollContentBackground(.hidden)
        .background(BackgroundView())
        .navigationTitle(settings.t(.supportTitle))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SupportRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 16, weight: .medium))
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .foregroundStyle(.primary)
        .padding(.vertical, 5)
    }
}
