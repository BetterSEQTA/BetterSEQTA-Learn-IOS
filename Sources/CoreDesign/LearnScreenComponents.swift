import SwiftUI

public struct LearnScreenHeader: View {
    private let title: String
    private let subtitle: String?

    public init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(LearnTheme.Colors.primaryText)
            if let subtitle {
                Text(subtitle)
                    .font(.title3)
                    .foregroundStyle(LearnTheme.Colors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, LearnLayout.horizontalPadding)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
}

public struct LearnEmptyState: View {
    private let title: String
    private let message: String
    private let systemImage: String

    public init(title: String, message: String, systemImage: String = "tray") {
        self.title = title
        self.message = message
        self.systemImage = systemImage
    }

    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 36))
                .foregroundStyle(LearnTheme.Colors.secondaryText.opacity(0.7))
                .symbolEffect(.pulse, options: .repeating.speed(0.35))
            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(LearnTheme.Colors.primaryText)
            Text(message)
                .font(LearnTypography.rowBody)
                .multilineTextAlignment(.center)
                .foregroundStyle(LearnTheme.Colors.secondaryText)
                .frame(maxWidth: 300)
                .learnReadableBody()
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

public struct LearnLoadingState: View {
    private let preset: LearnSkeletonPreset

    public init(preset: LearnSkeletonPreset = .list(rows: 6)) {
        self.preset = preset
    }

    public var body: some View {
        LearnSkeletonView(preset: preset)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }
}

public struct LearnErrorBanner: View {
    private let message: String
    private let retry: (() -> Void)?

    public init(message: String, retry: (() -> Void)? = nil) {
        self.message = message
        self.retry = retry
    }

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundStyle(Color.orange.opacity(0.9))
            Text(message)
                .font(LearnTypography.rowBody)
                .multilineTextAlignment(.center)
                .foregroundStyle(LearnTheme.Colors.secondaryText)
                .frame(maxWidth: 320)
                .learnReadableBody()
            if let retry {
                LearnMorphingTextButton(title: "Try again", action: retry)
                    .frame(maxWidth: 220)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

public struct LearnListRowButton<Label: View>: View {
    private let action: () -> Void
    private let label: Label

    public init(action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.action = action
        self.label = label()
    }

    public var body: some View {
        Button(action: {
            LearnHaptics.selection()
            action()
        }) {
            label
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(LearnPressFeedbackStyle(scale: 0.99))
    }
}