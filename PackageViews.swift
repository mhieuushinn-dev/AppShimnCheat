import SwiftUI

func categoryIcon(_ name: String) -> String {
    switch name {
    case "AIM": return "scope"
    case "ESP": return "eye.fill"
    case "Free Fire": return "flame.fill"
    case "Free Fire Max": return "sparkles"
    case "MOD SKIN": return "paintbrush.fill"
    case "Liên Quân Mobile": return "gamecontroller.fill"
    default: return "shippingbox.fill"
    }
}

// MARK: - Packages list

struct PackagesView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var store: RepoStore
    @State private var searchText = ""
    @State private var category: String?

    init(initialCategory: String?) {
        _category = State(initialValue: initialCategory)
    }

    private func matches(_ p: RepoPackage, _ q: String) -> Bool {
        if p.name.localizedCaseInsensitiveContains(q) { return true }
        if (p.summary ?? "").localizedCaseInsensitiveContains(q) { return true }
        return (p.tags ?? []).contains { $0.localizedCaseInsensitiveContains(q) }
    }

    private var filtered: [RepoPackage] {
        var result = store.packages
        if let c = category {
            result = result.filter { $0.category == c }
        }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            result = result.filter { matches($0, q) }
        }
        return result
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(settings.t(.packageCenter))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text(settings.t(.packageCenterSub))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                chips

                if store.packages.isEmpty {
                    ProgressView().padding(.top, 40)
                } else if filtered.isEmpty {
                    ContentUnavailableView(
                        settings.t(.notFound),
                        systemImage: "magnifyingglass",
                        description: Text(settings.t(.notFoundDesc))
                    )
                    .padding(.top, 30)
                } else {
                    ForEach(filtered) { p in
                        NavigationLink(value: Route.detail(p.id)) {
                            PackageRow(pkg: p)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .background(BackgroundView())
        .navigationTitle(settings.t(.packagesTitle))
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: settings.t(.searchPrompt))
        .refreshable { await store.refresh() }
    }

    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(settings.t(.allLabel), selected: category == nil) { category = nil }
                ForEach(store.categories) { c in
                    chip(c.name, selected: category == c.name) { category = c.name }
                }
            }
        }
    }

    private func chip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(selected ? Color.primary : Color.primary.opacity(0.08), in: Capsule())
                .foregroundStyle(selected ? Color(.systemBackground) : Color.primary)
        }
        .buttonStyle(.plain)
    }
}

struct PackageRow: View {
    let pkg: RepoPackage

    private func tag(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.primary.opacity(0.08), in: Capsule())
    }

    var body: some View {
        HStack(spacing: 14) {
            IconBox(systemName: categoryIcon(pkg.category ?? ""), size: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(pkg.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                Text(pkg.summary ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if let v = pkg.version { tag("v\(v)") }
                    if let s = pkg.size { tag(formatBytes(s)) }
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.footnote.bold())
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .contentShape(Rectangle())
        .shinnGlass(radius: 20)
    }
}

// MARK: - Package detail

struct PackageDetailView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var store: RepoStore
    let packageID: String

    private var pkg: RepoPackage? {
        store.packages.first { $0.id == packageID }
    }

    var body: some View {
        ZStack {
            BackgroundView()
            if let pkg {
                content(pkg)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(pkg?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func content(_ pkg: RepoPackage) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                remoteIcon(pkg)

                VStack(spacing: 4) {
                    Text(pkg.name)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                    if let s = pkg.summary {
                        Text(s)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(spacing: 0) {
                    infoRow(settings.t(.versionLabel), pkg.version ?? "-")
                    infoRow(settings.t(.authorLabel), pkg.author ?? "-")
                    infoRow(settings.t(.categoryLabel), pkg.category ?? "-")
                    infoRow(settings.t(.sizeLabel), pkg.size.map { formatBytes($0) } ?? "-")
                }
                .padding(.horizontal, 16)
                .shinnGlass()

                downloadSection(pkg)

                if let d = pkg.description, !d.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(settings.t(.descriptionLabel))
                            .font(.headline)
                        Text(d)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .shinnGlass()
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
    }

    @ViewBuilder
    private func remoteIcon(_ pkg: RepoPackage) -> some View {
        if let s = pkg.icon, let url = URL(string: s) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Image(systemName: categoryIcon(pkg.category ?? ""))
                        .font(.system(size: 38, weight: .semibold))
                }
            }
            .frame(width: 96, height: 96)
            .background(Color.primary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        } else {
            IconBox(systemName: categoryIcon(pkg.category ?? ""), size: 96)
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
        .font(.subheadline)
        .padding(.vertical, 13)
    }

    private func mainButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.primary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .foregroundStyle(Color(.systemBackground))
        }
        .buttonStyle(.plain)
    }

    private func message(_ e: DLError) -> String {
        switch e {
        case .badURL: return settings.t(.errURL)
        case .http(let code): return settings.t(.errHTTP) + " (\(code))"
        case .hashMismatch: return settings.t(.errHash)
        case .other(let m): return m
        }
    }

    @ViewBuilder
    private func downloadSection(_ pkg: RepoPackage) -> some View {
        VStack(spacing: 12) {
            switch store.state(for: pkg) {
            case .idle:
                mainButton(settings.t(.downloadAction), icon: "arrow.down.circle.fill") {
                    Task { await store.download(pkg) }
                }
            case .downloading:
                HStack(spacing: 10) {
                    ProgressView()
                    Text(settings.t(.downloading))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .shinnGlass(radius: 16)
            case .done(let url):
                Label(settings.t(.downloaded), systemImage: "checkmark.circle.fill")
                    .font(.headline)
                if let h = pkg.sha256, !h.isEmpty {
                    Label(settings.t(.sha256OK), systemImage: "checkmark.shield.fill")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                ShareLink(item: url) {
                    Label(settings.t(.shareAction), systemImage: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.primary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .foregroundStyle(Color(.systemBackground))
                }
                Text(settings.t(.savedHint))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button(settings.t(.redownload)) {
                    Task { await store.download(pkg) }
                }
                .font(.subheadline)
            case .failed(let err):
                Text(message(err))
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                mainButton(settings.t(.retry), icon: "arrow.clockwise") {
                    Task { await store.download(pkg) }
                }
            }
        }
    }
}
