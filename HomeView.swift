import SwiftUI

struct HomeView: View {

    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var store: RepoStore

    let open: (Route) -> Void

    var body: some View {

        ZStack {

            BackgroundView()

            ScrollView(
                showsIndicators: false
            ) {

                LazyVStack(spacing: 14) {

                    header
                    hero
                    sectionTitle
                    categoriesSection
                    quickActions
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 28)
            }
            .refreshable {
                await store.refresh()
            }
        }
        .toolbar(
            .hidden,
            for: .navigationBar
        )
    }

    private var header: some View {

        HStack(spacing: 12) {

            Image(systemName: "crown.fill")
                .font(.system(size: 28))

            VStack(
                alignment: .leading,
                spacing: 1
            ) {

                Text("SHINN CHEAT")
                    .font(
                        .system(
                            size: 27,
                            weight: .black,
                            design: .rounded
                        )
                    )
                    .tracking(-0.8)

                Text("GAMING CENTER")
                    .font(
                        .system(
                            size: 9,
                            weight: .medium
                        )
                    )
                    .tracking(4)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(
                action: {
                    open(.support)
                }
            ) {

                Image(
                    systemName: "paperplane.fill"
                )
                .font(.title3)
                .frame(
                    width: 48,
                    height: 48
                )
                .background(
                    Color.primary.opacity(0.08),
                    in: Circle()
                )
                .overlay(
                    Circle()
                        .strokeBorder(
                            Color.primary.opacity(0.15),
                            lineWidth: 1
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var hero: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            HStack {

                Label(
                    "APP",
                    systemImage: "crown.fill"
                )
                .font(
                    .system(
                        size: 14,
                        weight: .black,
                        design: .rounded
                    )
                )

                Spacer()

                Pill(text: "FREE")
            }

            Text("SHINN CHEAT")
                .font(
                    .system(
                        size: 37,
                        weight: .black,
                        design: .rounded
                    )
                )
                .tracking(-1)

            Text(settings.t(.heroFree))
                .font(
                    .system(
                        size: 14,
                        weight: .bold
                    )
                )

            HStack(spacing: 10) {

                Image(
                    systemName:
                        "exclamationmark.triangle.fill"
                )

                Text(settings.t(.heroNote))
                    .font(
                        .system(
                            size: 13,
                            weight: .semibold
                        )
                    )
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .background(
                Color.primary.opacity(0.08),
                in: RoundedRectangle(
                    cornerRadius: 16,
                    style: .continuous
                )
            )
        }
        .padding(20)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .shinnGlass()
    }

    private var sectionTitle: some View {

        HStack {

            Label(
                settings.t(.categoriesTitle),
                systemImage: "square.grid.2x2.fill"
            )
            .font(
                .system(
                    size: 18,
                    weight: .black,
                    design: .rounded
                )
            )

            Spacer()

            Pill(text: "FREE 100%")
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private var categoriesSection: some View {

        if store.packages.isEmpty {

            stateCard

        } else {

            CategoryCard(
                icon: "square.grid.2x2.fill",
                title: settings.t(.allPackages),
                count: store.packages.count
            ) {
                open(.packages(nil))
            }

            ForEach(store.categories) { category in

                CategoryCard(
                    icon: categoryIcon(category.name),
                    title: category.name,
                    count: category.count
                ) {
                    open(
                        .packages(
                            category.name
                        )
                    )
                }
            }
        }
    }

    private var stateCard: some View {

        VStack(spacing: 12) {

            if store.loadState == .failed {

                Image(
                    systemName: "wifi.exclamationmark"
                )
                .font(.title)

                Text(settings.t(.loadFailed))
                    .font(.subheadline)
                    .multilineTextAlignment(.center)

                Button(settings.t(.retry)) {

                    Task {
                        await store.refresh()
                    }
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

            QuickAction(
                title: settings.t(.settingsTitle),
                subtitle: settings.t(.settingsSub),
                icon: "gearshape.fill"
            ) {
                open(.settings)
            }

            QuickAction(
                title: settings.t(.aboutTitle),
                subtitle: settings.t(.aboutSub),
                icon: "info.circle.fill"
            ) {
                open(.about)
            }
        }
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

                IconBox(
                    systemName: icon,
                    size: 56
                )

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text(title)
                        .font(
                            .system(
                                size: 18,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .lineLimit(1)

                    Text(
                        settings.countText(count)
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Image(
                    systemName: "chevron.right"
                )
                .font(.footnote.bold())
                .frame(
                    width: 34,
                    height: 34
                )
                .background(
                    Color.primary.opacity(0.08),
                    in: Circle()
                )
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

            VStack(
                alignment: .leading,
                spacing: 12
            ) {

                Image(systemName: icon)
                    .font(.title2)

                Text(title)
                    .font(.headline.bold())

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .padding(18)
            .contentShape(Rectangle())
            .shinnGlass()
        }
        .buttonStyle(.plain)
    }
}