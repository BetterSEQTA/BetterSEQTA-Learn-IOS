import SwiftUI

/// Press feedback and light motion (inspired by polished interaction catalogs).
public struct LearnPressFeedbackStyle: ButtonStyle {
    @Environment(\.learnMotionProfile) private var motionProfile
    private let scale: CGFloat

    public init(scale: CGFloat = 0.96) {
        self.scale = scale
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(
                LearnMotion.pressAnimation(
                    richAnimations: motionProfile.richAnimations,
                    pressed: configuration.isPressed
                ),
                value: configuration.isPressed
            )
    }
}

public struct LearnStaggeredAppear: ViewModifier {
    let index: Int
    let baseDelay: Double
    @State private var visible = false
    @Environment(\.learnMotionProfile) private var motionProfile

    public init(index: Int, baseDelay: Double = 0.04) {
        self.index = index
        self.baseDelay = baseDelay
    }

    public func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 8)
            .onAppear {
                guard motionProfile.richAnimations else {
                    visible = true
                    return
                }
                withAnimation(
                    LearnMotion.spatialExpressiveFast.delay(Double(index) * baseDelay)
                ) {
                    visible = true
                }
            }
    }
}

extension View {
    public func learnStaggeredAppear(index: Int, baseDelay: Double = 0.04) -> some View {
        modifier(LearnStaggeredAppear(index: index, baseDelay: baseDelay))
    }

    public func learnListEntrance(index: Int) -> some View {
        learnStaggeredAppear(index: index, baseDelay: 0.03)
    }

    public func learnPressFeedback(scale: CGFloat = 0.96) -> some View {
        buttonStyle(LearnPressFeedbackStyle(scale: scale))
    }

    public func learnRowPress(scale: CGFloat = 0.99) -> some View {
        buttonStyle(LearnPressFeedbackStyle(scale: scale))
    }

    @ViewBuilder
    public func learnHeaderScrollFade() -> some View {
        if #available(iOS 17.0, *) {
            scrollTransition(.interactive) { content, phase in
                content
                    .opacity(phase.isIdentity ? 1 : 0.92)
                    .offset(y: phase.isIdentity ? 0 : 6)
            }
        } else {
            self
        }
    }

    /// Inline toast anchored to the bottom of the host (elastic bounce, no system banner).
    public func learnInlineToast(
        message: Binding<String?>,
        duration: TimeInterval = 2.4
    ) -> some View {
        overlay(alignment: .bottom) {
            if let text = message.wrappedValue {
                Text(text)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(LearnTheme.Colors.primaryText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .learnGroupedGlass(cornerRadius: 14)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            withAnimation(LearnMotion.spatialStandardDefault) {
                                if message.wrappedValue == text {
                                    message.wrappedValue = nil
                                }
                            }
                        }
                    }
            }
        }
        .animation(LearnMotion.spatialExpressiveFast, value: message.wrappedValue)
    }

    /// Top chrome pill that grows with scroll progress (pair with `LearnScrollOffsetReporter`).
    public func learnScrollIslandChrome(title: String, progress: CGFloat) -> some View {
        overlay(alignment: .top) {
            if progress > 0.02 {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Text("\(Int(progress * 100))%")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(maxWidth: 112 + progress * 148)
                .learnGroupedGlass(cornerRadius: 22 - progress * 6)
                .padding(.top, 6)
                .scaleEffect(0.94 + progress * 0.06)
                .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .animation(LearnMotion.fluidMorphSpring, value: progress > 0.02)
    }
}

/// Place at the top of scroll content; wire `onPreferenceChange(LearnScrollOffsetKey.self)`.
public struct LearnScrollOffsetReporter: View {
    public init() {}

    public var body: some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: LearnScrollOffsetKey.self,
                value: proxy.frame(in: .named("learnScroll")).minY
            )
        }
        .frame(height: 0)
    }
}

public enum LearnScrollOffsetKey: PreferenceKey {
    public static let defaultValue: CGFloat = 0
    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

public func learnScrollProgress(from offsetY: CGFloat, span: CGFloat = 400) -> CGFloat {
    min(max(-offsetY / span, 0), 1)
}
