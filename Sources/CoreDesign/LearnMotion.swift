import SwiftUI

/// Motion tokens tuned for critically damped UI (damping 1.0) per
/// [Apple Motion HIG](https://developer.apple.com/design/human-interface-guidelines/motion)
/// and fluid-interface guidance: fast response, interruptible springs, no gratuitous bounce on chrome.
public enum LearnMotion {
    public static let spatialExpressiveFast = Animation.spring(response: 0.45, dampingFraction: 0.8)
    public static let spatialExpressiveDefault = Animation.spring(response: 0.5, dampingFraction: 0.75, blendDuration: 0)
    public static let spatialExpressiveSlow = Animation.spring(response: 0.65, dampingFraction: 0.85)

    public static let spatialStandardFast = Animation.spring(response: 0.35, dampingFraction: 1)
    public static let spatialStandardDefault = Animation.spring(response: 0.4, dampingFraction: 1)

    public static let effectsFast = Animation.spring(response: 0.35, dampingFraction: 1)
    public static let effectsDefault = Animation.spring(response: 0.45, dampingFraction: 1)

    /// Sidebar / sheet (WWDC fluid interfaces: slight bounce, fast settle).
    public static let drawerSpring = Animation.spring(response: 0.3, dampingFraction: 0.86)

    /// Container morph / island expand (~stiffness 300, light overshoot).
    public static let fluidMorphSpring = Animation.spring(response: 0.42, dampingFraction: 0.72)
    /// Tab pill glide with slight squeeze settle.
    public static let liquidTabSpring = Animation.spring(response: 0.38, dampingFraction: 0.78)

    public static var screenSlide: Animation { spatialStandardDefault }
    public static var screenFadeIn: Animation { effectsFast }
    public static var screenFadeOut: Animation { effectsDefault }

    public static func pressAnimation(richAnimations: Bool, pressed: Bool) -> Animation {
        guard richAnimations else { return .linear(duration: 0) }
        return pressed ? spatialStandardFast : spatialStandardDefault
    }

    public static func entranceAnimation(profile: LearnMotionProfile) -> Animation {
        guard profile.richAnimations, profile.staggeredEntrances else {
            return .linear(duration: 0)
        }
        return spatialExpressiveDefault
    }

    public static func overlayFadeAnimation(richAnimations: Bool) -> Animation {
        richAnimations ? effectsDefault : .linear(duration: 0)
    }

    public static func progressAnimation(profile: LearnMotionProfile) -> Animation {
        profile.richAnimations ? effectsDefault : .linear(duration: 0)
    }

    public static func directionalSlide(
        direction: LearnDayNavigationDirection,
        richAnimations: Bool
    ) -> AnyTransition {
        guard richAnimations else {
            return .opacity
        }
        switch direction {
        case .forward:
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        case .backward:
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        }
    }

    public static func tabSlide(
        forward: Bool,
        richAnimations: Bool
    ) -> AnyTransition {
        directionalSlide(
            direction: forward ? .forward : .backward,
            richAnimations: richAnimations
        )
    }

    public static func overlaySlide(
        richAnimations: Bool
    ) -> AnyTransition {
        guard richAnimations else { return .opacity }
        return .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        )
    }

    public static func weekSlide(
        direction: LearnDayNavigationDirection,
        richAnimations: Bool
    ) -> AnyTransition {
        directionalSlide(direction: direction, richAnimations: richAnimations)
    }

    /// Resets a `TabView` page index without animating the snap-back (week pager).
    @MainActor
    public static func withoutAnimation(_ updates: () -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction, updates)
    }
}

public struct LearnDirectionalContent<Content: View>: View {
    private let identity: AnyHashable
    private let direction: LearnDayNavigationDirection
    private let content: Content
    @Environment(\.learnMotionProfile) private var motionProfile

    public init(
        identity: some Hashable,
        direction: LearnDayNavigationDirection,
        @ViewBuilder content: () -> Content
    ) {
        self.identity = AnyHashable(identity)
        self.direction = direction
        self.content = content()
    }

    public var body: some View {
        content
            .id(identity)
            .transition(
                LearnMotion.directionalSlide(
                    direction: direction,
                    richAnimations: motionProfile.richAnimations
                )
            )
    }
}

public struct LearnMotionProfile: Equatable, Sendable {
    public var richAnimations: Bool
    public var staggeredEntrances: Bool

    public init(richAnimations: Bool = true, staggeredEntrances: Bool = true) {
        self.richAnimations = richAnimations
        self.staggeredEntrances = staggeredEntrances
    }

    public static func current(reduceMotion: Bool) -> LearnMotionProfile {
        LearnMotionProfile(richAnimations: !reduceMotion, staggeredEntrances: !reduceMotion)
    }
}

private struct LearnMotionProfileKey: EnvironmentKey {
    static let defaultValue = LearnMotionProfile()
}

extension EnvironmentValues {
    public var learnMotionProfile: LearnMotionProfile {
        get { self[LearnMotionProfileKey.self] }
        set { self[LearnMotionProfileKey.self] = newValue }
    }
}
