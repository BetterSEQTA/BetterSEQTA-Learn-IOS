import SwiftUI

/// Tokens aligned with iOS grouped layout + [BetterSEQTA+](https://github.com/BetterSEQTA/BetterSEQTA-Plus) accent on controls only.
public enum LearnTheme {
    public static let accentName = "LearnAccent"
    /// Inset grouped cards (HIG layout).
    public static let cardCornerRadius: CGFloat = 10
    public static let controlCornerRadius: CGFloat = 8

    public struct Colors {
        /// Primary screen canvas — flat neutral (no brand tint).
        public static let background = Color(red: 0.11, green: 0.11, blue: 0.12)
        /// Sidebar / elevated surfaces.
        public static let elevatedBackground = Color(red: 0.14, green: 0.14, blue: 0.15)
        /// Grouped list & home sections (`secondarySystemGroupedBackground` feel).
        public static let groupedFill = Color(red: 0.17, green: 0.17, blue: 0.18)
        public static let card = groupedFill
        public static let primaryText = Color.white.opacity(0.96)
        public static let secondaryText = Color.white.opacity(0.72)
        public static let tertiaryText = Color.white.opacity(0.52)
        public static let separator = Color.white.opacity(0.12)
        public static let glassStroke = separator
        /// BetterSEQTA indigo — interactive emphasis only.
        public static let accent = Color(red: 0.388, green: 0.400, blue: 0.945)
    }

    public struct Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
    }
}

public struct LearnScreenBackground: View {
    public init() {}

    public var body: some View {
        LearnTheme.Colors.background
            .ignoresSafeArea()
    }
}

public struct LearnGlassCard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(LearnTheme.Spacing.md)
            .learnGroupedGlass()
    }
}

public struct LearnPrimaryButtonStyle: ButtonStyle {
    @Environment(\.learnMotionProfile) private var motionProfile
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, LearnTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: LearnTheme.controlCornerRadius, style: .continuous)
                    .fill(isEnabled ? LearnTheme.Colors.accent : LearnTheme.Colors.accent.opacity(0.4))
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(
                LearnMotion.pressAnimation(richAnimations: motionProfile.richAnimations, pressed: configuration.isPressed),
                value: configuration.isPressed
            )
    }
}
