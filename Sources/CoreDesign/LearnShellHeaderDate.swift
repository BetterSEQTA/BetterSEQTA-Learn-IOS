import SwiftUI

/// Shell top-bar date cluster (weekday + long date).
public struct LearnShellHeaderDate: View {
    public enum Style {
        case standard
        /// Fits inline navigation toolbar between menu and trailing actions.
        case toolbar
    }

    public let date: Date
    public var style: Style = .standard
    public var weekdayFont: Font = LearnTypography.rowTitle
    public var dateFont: Font = LearnTypography.rowMeta
    public var alignment: HorizontalAlignment = .leading

    public init(
        date: Date,
        style: Style = .standard,
        alignment: HorizontalAlignment = .leading
    ) {
        self.date = date
        self.style = style
        self.alignment = alignment
    }

    public var body: some View {
        Group {
            switch style {
            case .standard:
                VStack(alignment: alignment, spacing: 2) {
                    Text(date, format: .dateTime.weekday(.wide))
                        .font(weekdayFont.weight(.semibold))
                        .foregroundStyle(LearnTheme.Colors.primaryText)
                    Text(date, format: .dateTime.month(.wide).day().year())
                        .font(dateFont)
                        .foregroundStyle(LearnTheme.Colors.tertiaryText)
                }
            case .toolbar:
                VStack(alignment: alignment, spacing: 0) {
                    Text(date, format: .dateTime.weekday(.wide))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(LearnTheme.Colors.primaryText)
                    Text(date, format: .dateTime.month(.wide).day().year())
                        .font(.caption)
                        .foregroundStyle(LearnTheme.Colors.tertiaryText)
                }
            }
        }
        .contentTransition(.interpolate)
        .animation(LearnMotion.spatialStandardFast, value: date)
    }
}

/// Single-line shell title for the inline toolbar `principal` slot.
public struct LearnShellToolbarTitle: View {
    private let title: String

    public init(_ title: String) {
        self.title = title
    }

    public var body: some View {
        Text(title)
            .font(LearnTypography.shellTitle)
            .foregroundStyle(LearnTheme.Colors.primaryText)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .contentTransition(.interpolate)
    }
}
