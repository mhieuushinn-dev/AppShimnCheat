import SwiftUI

struct HomeView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var store: RepoStore
    @EnvironmentObject var session: Session
    let open: (Route) -> Void

    var body: some View {
        ZStack {
            BackgroundView()

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 14) {
                    header
                    hero
                    sectionTitle
                    categoriesSection
                    quickActions
                    credit
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 28)
            }
            .refreshable { await store.refresh() }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 28))

            Text("SHINN CHEAT")
                .font(.system(size: 27, weight: .black, design: .rounded))
                .tracking(-0.8)

            Spacer()

            Button(action: { open(.support) }) {
                Image(systemName: "paperplane.fill")
                    .font(.title3)
                    .frame(width: 48, height: 48)
                    .background(Color.primary.opacity(0.08), in: Circle())
                    .overlay(Circle().strokeBorder(Color.primary.opacity(0.15), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("APP", systemImage: "crown.fill")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                Spacer()
                Pill(text: "FREE")
            }

            Text("SHINN CHEAT")
                .font(.system(size: 37, weight: .black, design: .rounded))
                .tracking(-1)

            Text(settings.t(.heroFree))
                .font(.system(size: 14, weight: .bold))

            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                Text(settings.t(.heroNote))
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .shinnGlass()
    }

    private var sectionTitle: some View {
        HStack {
            Label(settings.t(.categoriesTitle), systemImage: "square.grid.2x2.fill")
                .font(.system(size: 18, weight: .black, design: .rounded))
            Spacer()
            Button(action: { session.role = nil }) {
                Label(session.role?.title ?? "", systemImage: session.role?.icon ?? "person.fill")
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.primary.opacity(0.1), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private var categoriesSection: some View {
        if store.packages.isEmpty {
            stateCard
        } else {
            CategoryCard(icon: "square.grid.2x2.fill", title: settings.t(.allPackages), count: store.packages.count) {
                open(.packages(nil))
            }
            ForEach(store.categories) { c in
                CategoryCard(icon: categoryIcon(c.name), title: c.name, count: c.count) {
                    open(.packages(c.name))
                }
            }
        }
    }

    private var stateCard: some View {
        VStack(spacing: 12) {
            if store.loadState == .failed {
                Image(systemName: "wifi.exclamationmark")
                    .font(.title)
                Text(settings.t(.loadFailed))
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                Button(settings.t(.retry)) {
                    Task { await store.refresh() }
                }
                .buttonStyle(.bordered)
            } else {
                ProgressView()
                Text(settings.t(.loadingText))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .shinnGlass()
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            QuickAction(title: settings.t(.settingsTitle), subtitle: settings.t(.settingsSub), icon: "gearshape.fill") {
                open(.settings)
            }
            QuickAction(title: settings.t(.aboutTitle), subtitle: settings.t(.aboutSub), icon: "info.circle.fill") {
                open(.about)
            }
        }
    }

    private var credit: some View {
        HStack {
            Image(systemName: "cube.fill")
                .font(.title2)
            VStack(alignment: .leading) {
                Text("SHINN CHEAT").font(.headline.bold())
                Text("FREE FIRE • FREE FIRE MAX")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("Play Smart\nStay Ahead")
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .italic()
                .multilineTextAlignment(.trailing)
        }
        .padding(18)
        .shinnGlass()
    }
}

struct CategoryCard: View {
    @EnvironmentObject var settings: AppSettings
    let icon: String
    let title: String
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                IconBox(systemName: icon, size: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .lineLimit(1)
                    Text(settings.countText(count))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.footnote.bold())
                    .frame(width: 34, height: 34)
                    .background(Color.primary.opacity(0.08), in: Circle())
            }
            .padding(12)
            .contentShape(Rectangle())
            .shinnGlass()
        }
        .buttonStyle(.plain)
    }
}

struct QuickAction: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon).font(.title2)
                Text(title).font(.headline.bold())
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .contentShape(Rectangle())
            .shinnGlass()
        }
        .buttonStyle(.plain)
    }
}
