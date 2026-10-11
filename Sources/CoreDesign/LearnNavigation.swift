import Foundation
import SwiftUI

public enum LearnDayNavigationDirection: Sendable, Equatable {
    case forward
    case backward
}

/// When depth is greater than zero, the main shell hides its top bar so pushed screens use a single inline chrome row.
/// Aligns with [Motion HIG](https://developer.apple.com/design/human-interface-guidelines/motion): one continuous navigation surface.
public struct LearnShellChromeDepthKey: PreferenceKey {
    public static let defaultValue: Int = 0

    public static func reduce(value: inout Int, nextValue: () -> Int) {
        value = max(value, nextValue())
    }
}

extension View {
    /// Report nested navigation depth (0 = root tab, 1+ = detail).
    public func learnShellNavigationDepth(_ depth: Int) -> some View {
        preference(key: LearnShellChromeDepthKey.self, value: depth)
    }
}

/// Back + title row used when the shell top bar is suppressed.
public struct LearnInlineNavBar<Trailing: View>: View {
    private let title: String
    private let trailing: Trailing
    @Environment(\.dismiss) private var dismiss

    public init(
        title: String,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: 10) {
            Button {
                LearnHaptics.lightImpact()
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(LearnPressFeedbackStyle(scale: 0.92))
            .accessibilityLabel("Back")

            Text(title)
                .font(LearnTypography.rowTitle)
                .foregroundStyle(LearnTheme.Colors.primaryText)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            trailing
        }
        .padding(.horizontal, LearnLayout.horizontalPadding)
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            LearnSeparatorHairline()
        }
    }
}
