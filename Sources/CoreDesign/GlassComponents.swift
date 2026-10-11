import SwiftUI

public struct LearnGlassBar<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(.horizontal, LearnTheme.Spacing.md)
            .padding(.vertical, LearnTheme.Spacing.sm)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(LearnTheme.Colors.glassStroke, lineWidth: 1)
            )
    }
}

public struct LearnPressableScale: ViewModifier {
    @Environment(\.learnMotionProfile) private var motionProfile
    @GestureState private var isPressed = false

    private let scale: CGFloat

    public init(scale: CGFloat = 0.97) {
        self.scale = scale
    }

    public func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1)
            .animation(
                LearnMotion.pressAnimation(richAnimations: motionProfile.richAnimations, pressed: isPressed),
                value: isPressed
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in state = true }
            )
    }
}

extension View {
    public func learnPressableScale(_ scale: CGFloat = 0.97) -> some View {
        modifier(LearnPressableScale(scale: scale))
    }
}
