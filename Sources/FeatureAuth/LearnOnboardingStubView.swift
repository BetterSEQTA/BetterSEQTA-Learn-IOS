import CoreDesign
import SwiftUI

/// First-run welcome carousel + optional school URL (stored locally for sign-in).
public struct LearnOnboardingStubView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var loginViewModel = LoginViewModel()
    @State private var step = 0
    @State private var schoolUrl = ""

    private let onContinue: () -> Void
    private let pageCount = 3

    private var motionProfile: LearnMotionProfile {
        LearnMotionProfile.current(reduceMotion: reduceMotion)
    }

    public init(onContinue: @escaping () -> Void) {
        self.onContinue = onContinue
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: LearnTheme.Spacing.lg) {
                header
                stepIndicator
                LearnGlassCard {
                    VStack(alignment: .leading, spacing: LearnTheme.Spacing.md) {
                        pager
                        stepControls
                    }
                }
                .animation(LearnMotion.entranceAnimation(profile: motionProfile), value: step)
            }
            .padding(LearnTheme.Spacing.md)
        }
        .background(LearnTheme.Colors.background.ignoresSafeArea())
        .environment(\.learnMotionProfile, motionProfile)
        .onAppear {
            let remembered = loginViewModel.rememberedSchoolUrl
            if schoolUrl.isEmpty, !remembered.isEmpty {
                schoolUrl = remembered
            }
        }
    }

    private var header: some View {
        VStack(spacing: LearnTheme.Spacing.sm) {
            Image(systemName: stepIcon)
                .font(.system(size: 56))
                .foregroundStyle(LearnTheme.Colors.accent)
                .symbolEffect(.bounce, value: step)
                .accessibilityHidden(true)
            Text("BetterSEQTA Learn")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(LearnTheme.Colors.primaryText)
            Text("Your SEQTA day — timetable, tasks, and messages in one place.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(LearnTheme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, LearnTheme.Spacing.md)
    }

    private var stepIcon: String {
        switch step {
        case 0: "calendar"
        case 1: "person.badge.key.fill"
        default: "link"
        }
    }

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0 ..< pageCount, id: \.self) { index in
                Circle()
                    .fill(
                        index == step
                            ? LearnTheme.Colors.accent
                            : LearnTheme.Colors.secondaryText.opacity(0.35)
                    )
                    .frame(width: index == step ? 10 : 8, height: index == step ? 10 : 8)
                    .accessibilityLabel("Step \(index + 1) of \(pageCount)")
            }
        }
        .animation(LearnMotion.entranceAnimation(profile: motionProfile), value: step)
    }

    private var pager: some View {
        TabView(selection: $step) {
            onboardingPage(
                tag: 0,
                title: "Stay on top of school",
                detail: "See today’s lessons, notices, and upcoming assessments from the home screen."
            )
            onboardingPage(
                tag: 1,
                title: "Sign in your way",
                detail: "Use your school web login, saved credentials, or a QR / connect link from your school."
            )
            schoolUrlPage
                .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(minHeight: step == 2 ? 220 : 140)
        .animation(LearnMotion.entranceAnimation(profile: motionProfile), value: step)
    }

    private func onboardingPage(tag: Int, title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: LearnTheme.Spacing.sm) {
            Text(title)
                .font(.headline)
                .foregroundStyle(LearnTheme.Colors.primaryText)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(LearnTheme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tag(tag)
    }

    private var schoolUrlPage: some View {
        VStack(alignment: .leading, spacing: LearnTheme.Spacing.sm) {
            Text("Remember your school")
                .font(.headline)
                .foregroundStyle(LearnTheme.Colors.primaryText)
            Text("Add your school SEQTA address once — stored on this device only to speed up sign-in.")
                .font(.subheadline)
                .foregroundStyle(LearnTheme.Colors.secondaryText)
            UrlEntryView(
                title: "School SEQTA URL",
                text: $schoolUrl
            )
            Text("You can change this later from the sign-in screen.")
                .font(.caption)
                .foregroundStyle(LearnTheme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stepControls: some View {
        HStack(spacing: LearnTheme.Spacing.md) {
            if step > 0 {
                Button("Back") {
                    withAnimation(LearnMotion.entranceAnimation(profile: motionProfile)) {
                        step -= 1
                    }
                }
                .foregroundStyle(LearnTheme.Colors.secondaryText)
            }
            Spacer()
            if step < pageCount - 1 {
                Button("Next") {
                    withAnimation(LearnMotion.entranceAnimation(profile: motionProfile)) {
                        step += 1
                    }
                }
                .buttonStyle(LearnPrimaryButtonStyle())
            } else {
                Button("Get started", action: continueTapped)
                    .buttonStyle(LearnPrimaryButtonStyle())
            }
        }
    }

    private func continueTapped() {
        let trimmed = schoolUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            loginViewModel.rememberSchoolUrl(trimmed)
        }
        onContinue()
    }
}
