import SwiftUI

public struct FluidLoadingBarView: View {
    @Environment(\.learnMotionProfile) private var motionProfile

    private let progress: Double
    private let phaseText: String

    public init(progress: Double, phaseText: String) {
        self.progress = progress
        self.phaseText = phaseText
    }

    public var body: some View {
        let clamped = min(max(progress, 0), 1)
        VStack(alignment: .leading, spacing: 8) {
            Text(phaseText)
                .font(.subheadline)
                .foregroundStyle(LearnTheme.Colors.secondaryText)
                .id(phaseText)
                .transition(.opacity.combined(with: .move(edge: .bottom)))

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.39, green: 0.40, blue: 0.95),
                                    Color(red: 0.23, green: 0.51, blue: 0.96),
                                    Color(red: 0.02, green: 0.71, blue: 0.83),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * clamped)
                        .animation(LearnMotion.progressAnimation(profile: motionProfile), value: clamped)
                }
            }
            .frame(height: 6)
            .padding(.top, 6)
        }
        .padding(.vertical, 6)
        .animation(LearnMotion.effectsDefault, value: phaseText)
    }
}
