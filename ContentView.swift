import SwiftUI
import CryptoKit

enum UserRole: String, CaseIterable, Identifiable {
    case owner, admin, member
    var id: String { rawValue }

    var title: String {
        switch self {
        case .owner: return "Owner"
        case .admin: return "Admin"
        case .member: return "Member"
        }
    }

    var icon: String {
        switch self {
        case .owner: return "crown.fill"
        case .admin: return "checkmark.shield.fill"
        case .member: return "person.fill"
        }
    }

    var needsPassword: Bool { self != .member }
}

final class Session: ObservableObject {
    @Published var role: UserRole?

    // SHA256 của mật khẩu Owner/Admin
    private static let passwordHash = "a43535812161a1aec35c04f0b6ea63bb4880d581f3d15df9ba7e68befe6b472e"

    func verify(_ input: String) -> Bool {
        let digest = SHA256.hash(data: Data(input.utf8))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return hex == Session.passwordHash
    }
}

struct ContentView: View {
    @StateObject private var session = Session()
    @State private var path: [Route] = []

    var body: some View {
        Group {
            if session.role == nil {
                RoleGateView()
            } else {
                NavigationStack(path: $path) {
                    HomeView(open: { path.append($0) })
                        .navigationDestination(for: Route.self) { route in
                            switch route {
                            case .packages(let category):
                                PackagesView(initialCategory: category)
                            case .detail(let id):
                                PackageDetailView(packageID: id)
                            case .settings:
                                SettingsView()
                            case .about:
                                AboutView()
                            case .support:
                                SupportView()
                            }
                        }
                }
                .tint(.primary)
            }
        }
        .environmentObject(session)
        .animation(.easeInOut(duration: 0.25), value: session.role)
    }
}

// MARK: - Chọn vai trò

struct RoleGateView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var session: Session
    @State private var pending: UserRole?
    @State private var password = ""
    @State private var attempts = 0
    @State private var closing = false
    @FocusState private var focused: Bool

    private var isVI: Bool { settings.language == .vi }

    var body: some View {
        ZStack {
            BackgroundView()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    Spacer(minLength: 40)

                    Image(systemName: "crown.fill")
                        .font(.system(size: 46))

                    VStack(spacing: 6) {
                        Text("SHINN CHEAT")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .tracking(-0.8)
                        Text(isVI ? "Chọn vai trò để kích hoạt" : "Choose a role to activate")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 12) {
                        ForEach(UserRole.allCases) { role in
                            roleCard(role)
                        }
                    }
                    .padding(.top, 8)

                    if let role = pending {
                        passwordCard(role)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private func roleCard(_ role: UserRole) -> some View {
        Button(action: { select(role) }) {
            HStack(spacing: 16) {
                IconBox(systemName: role.icon, size: 52)

                Text(role.title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))

                Spacer(minLength: 0)
            }
            .padding(14)
            .contentShape(Rectangle())
            .shinnGlass()
        }
        .buttonStyle(.plain)
    }

    private func passwordCard(_ role: UserRole) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label((isVI ? "Mật khẩu " : "Password for ") + role.title, systemImage: "lock.fill")
                .font(.headline)

            SecureField(isVI ? "Nhập mật khẩu" : "Enter password", text: $password)
                .focused($focused)
                .keyboardType(.numberPad)
                .padding(14)
                .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .onSubmit { submit() }
                .disabled(closing)

            if closing {
                Text(isVI ? "Sai 3 lần. Ứng dụng sẽ tự đóng." : "3 wrong attempts. The app will close.")
                    .font(.footnote.bold())
                    .foregroundStyle(.red)
            } else if attempts > 0 {
                Text((isVI ? "Sai mật khẩu " : "Wrong password ") + "(\(attempts)/3)")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            HStack(spacing: 10) {
                Button(action: cancel) {
                    Text(isVI ? "Hủy" : "Cancel")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: submit) {
                    Text(isVI ? "Xác nhận" : "Confirm")
                        .font(.system(size: 15, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.primary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .foregroundStyle(Color(.systemBackground))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .shinnGlass()
    }

    private func select(_ role: UserRole) {
        if closing { return }
        if role.needsPassword {
            pending = role
            password = ""
            DispatchQueue.main.async { focused = true }
        } else {
            session.role = role
        }
    }

    private func cancel() {
        if closing { return }
        pending = nil
        password = ""
        focused = false
    }

    private func submit() {
        guard let role = pending, !closing else { return }
        if session.verify(password) {
            session.role = role
            pending = nil
            password = ""
            attempts = 0
        } else {
            attempts += 1
            password = ""
            if attempts >= 3 {
                closing = true
                focused = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    exit(0)
                }
            }
        }
    }
}
