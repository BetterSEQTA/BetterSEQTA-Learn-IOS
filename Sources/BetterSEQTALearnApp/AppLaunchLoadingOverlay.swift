import CoreDesign
import SwiftUI

struct AppLaunchLoadingOverlay: View {
    let visible: Bool
    let versionName: String
    var onDismissed: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dismissed = false

    private var motionProfile: LearnMotionProfile {
        LearnMotionProfile.current(reduceMotion: reduceMotion)
    }

    var body: some View {
        if visible && !dismissed {
            ZStack {
                LearnTheme.Colors.background.ignoresSafeArea()
                VStack(spacing: 16) {
                    FluidLoadingBarView(progress: 0.4, phaseText: "Preparing your dashboard…")
                        .padding(.horizontal, 32)
                    Text("BetterSEQTA Learn")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(LearnTheme.Colors.primaryText)
                    Text("Loading your home screen")
                        .font(.subheadline)
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                    Text(versionName)
                        .font(.caption2)
                        .foregroundStyle(LearnTheme.Colors.secondaryText.opacity(0.8))
                }
            }
            .transition(.opacity)
            .onChange(of: visible) { _, isVisible in
                if !isVisible {
                    withAnimation(LearnMotion.overlayFadeAnimation(richAnimations: motionProfile.richAnimations)) {
                        dismissed = true
                    }
                    onDismissed?()
                }
            }
        }
    }
}
