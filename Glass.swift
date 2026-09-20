import SwiftUI

struct GlassCardModifier: ViewModifier {
    var radius: CGFloat = 22

    func body(content: Content) -> some View {
        content
            .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
            )
    }
}

extension View {
    func shinnGlass(radius: CGFloat = 22) -> some View {
        modifier(GlassCardModifier(radius: radius))
    }
}

struct BackgroundView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
            RadialGradient(
                colors: [Color.primary.opacity(0.09), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 500
            )
            RadialGradient(
                colors: [Color.primary.opacity(0.05), .clear],
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 450
            )
        }
        .ignoresSafeArea()
    }
}

struct IconBox: View {
    let systemName: String
    var size: CGFloat = 56

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.42, weight: .semibold))
            .frame(width: size, height: size)
            .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: size * 0.3, style: .continuous))
    }
}

struct Pill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.primary.opacity(0.1), in: Capsule())
    }
}
