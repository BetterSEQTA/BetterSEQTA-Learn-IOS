import SwiftUI

/// Motion tokens mirroring Android `AppMotion` (Learn naming on iOS).
public enum LearnMotion {
    public static let spatialExpressiveFast = Animation.spring(response: 0.45, dampingFraction: 0.8)
    public static let spatialExpressiveDefault = Animation.spring(response: 0.5, dampingFraction: 0.75, blendDuration: 0)
    public static let spatialExpressiveSlow = Animation.spring(response: 0.65, dampingFraction: 0.85)

    public static let spatialStandardFast = Animation.spring(response: 0.35, dampingFraction: 1)
    public static let spatialStandardDefault = Animation.spring(response: 0.4, dampingFraction: 1)

    public static let effectsFast = Animation.spring(response: 0.35, dampingFraction: 1)
    public static let effectsDefault = Animation.spring(response: 0.45, dampingFraction: 1)

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
