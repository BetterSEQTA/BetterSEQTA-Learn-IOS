import SwiftUI

public enum LearnTheme {
    public static let accentName = "LearnAccent"
    public static let cardCornerRadius: CGFloat = 16
    public static let controlCornerRadius: CGFloat = 12

    public struct Colors {
        public static let background = Color(red: 0.06, green: 0.07, blue: 0.10)
        public static let card = Color.white.opacity(0.08)
        public static let primaryText = Color.white
        public static let secondaryText = Color.white.opacity(0.72)
        public static let glassStroke = Color.white.opacity(0.12)
        public static let accent = Color(red: 0.39, green: 0.40, blue: 0.95)
    }

    public struct Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
    }
}

public struct LearnGlassCard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(LearnTheme.Spacing.md)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: LearnTheme.cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LearnTheme.cardCornerRadius, style: .continuous)
                    .strokeBorder(LearnTheme.Colors.glassStroke, lineWidth: 1)
            )
    }
}

public struct LearnPrimaryButtonStyle: ButtonStyle {
    @Environment(\.learnMotionProfile) private var motionProfile
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(LearnTheme.Colors.primaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, LearnTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: LearnTheme.controlCornerRadius, style: .continuous)
                    .fill(isEnabled ? LearnTheme.Colors.accent : LearnTheme.Colors.accent.opacity(0.4))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(
                LearnMotion.pressAnimation(richAnimations: motionProfile.richAnimations, pressed: configuration.isPressed),
                value: configuration.isPressed
            )
    }
}
