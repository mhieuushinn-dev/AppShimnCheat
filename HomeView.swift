import SwiftUI

struct HomeView: View {
    @Binding var route: Route?

    private let packages = [
        PackageItem(id: "ff", name: "Free Fire", subtitle: "Gói miễn phí", count: 2, icon: "gamecontroller.fill"),
        PackageItem(id: "ffmax", name: "Free Fire Max", subtitle: "Gói miễn phí", count: 2, icon: "sparkles"),
        PackageItem(id: "vip", name: "MOD VIP", subtitle: "Kho package", count: 9, icon: "cube.fill")
    ]

    var body: some View {
        ZStack {
            BackgroundView()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    header
                    hero
                    sectionTitle
                    ForEach(packages) { package in
                        PackageCard(item: package) { route = .packages }
                    }
                    quickActions
                    credit
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 28)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 28))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 1) {
                Text("SHINN CHEAT")
                    .font(.system(size: 27, weight: .black, design: .rounded))
                    .tracking(-0.8)
                Text("GAMING CENTER")
                    .font(.system(size: 9, weight: .medium))
                    .tracking(4)
                    .opacity(0.7)
            }

            Spacer()

            Button(action: { route = .support }) {
                Image(systemName: "paperplane.fill")
                    .font(.title3)
                    .frame(width: 48, height: 48)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(.white.opacity(0.22)))
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("APP", systemImage: "crown.fill")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                Spacer()
                Text("FREE")
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(.white.opacity(0.12), in: Capsule())
            }

            Text("SHINN CHEAT")
                .font(.system(size: 37, weight: .black, design: .rounded))
                .tracking(-1)

            Text("LÀ APP VÀ REPO HOÀN TOÀN FREE")
                .font(.system(size: 14, weight: .bold))
                .opacity(0.9)

            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                Text("Không bán key • Không khóa thiết bị")
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 16))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .shinnGlass()
    }

    private var sectionTitle: some View {
        HStack {
            Label("DANH MỤC GÓI", systemImage: "cube.fill")
                .font(.system(size: 20, weight: .black, design: .rounded))
            Spacer()
            Text("FREE 100%")
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.white.opacity(0.12), in: Capsule())
        }
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            QuickAction(title: "Cài Đặt", subtitle: "Tùy chỉnh app", icon: "gearshape.fill") {
                route = .settings
            }
            QuickAction(title: "Giới Thiệu", subtitle: "Thông tin app", icon: "info.circle.fill") {
                route = .about
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
                    .opacity(0.65)
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

struct PackageCard: View {
    let item: PackageItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: item.icon)
                    .font(.system(size: 28))
                    .frame(width: 76, height: 76)
                    .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.18)))

                VStack(alignment: .leading, spacing: 7) {
                    Text(item.name)
                        .font(.system(size: 21, weight: .bold, design: .rounded))
                    HStack(spacing: 6) {
                        Image(systemName: "cube.fill")
                        Text("\(item.count) gói")
                    }
                    .font(.subheadline)
                    .opacity(0.7)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.title3.bold())
                    .frame(width: 48, height: 48)
                    .background(.white.opacity(0.11), in: Circle())
            }
            .foregroundStyle(.white)
            .padding(14)
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
                Text(subtitle).font(.caption).opacity(0.65)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .foregroundStyle(.white)
            .shinnGlass()
        }
        .buttonStyle(.plain)
    }
}

struct BackgroundView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            RadialGradient(
                colors: [.white.opacity(0.10), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 500
            ).ignoresSafeArea()
            RadialGradient(
                colors: [.white.opacity(0.06), .clear],
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 450
            ).ignoresSafeArea()
        }
    }
}
