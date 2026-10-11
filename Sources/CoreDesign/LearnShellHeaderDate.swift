import SwiftUI

/// Shell top-bar date cluster (weekday + long date).
public struct LearnShellHeaderDate: View {
    public let date: Date
    public var weekdayFont: Font = LearnTypography.rowTitle
    public var dateFont: Font = LearnTypography.rowMeta
    public var alignment: HorizontalAlignment = .leading

    public init(date: Date) {
        self.date = date
    }

    public var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(date, format: .dateTime.weekday(.wide))
                .font(weekdayFont.weight(.semibold))
                .foregroundStyle(LearnTheme.Colors.primaryText)
            Text(date, format: .dateTime.month(.wide).day().year())
                .font(dateFont)
                .foregroundStyle(LearnTheme.Colors.tertiaryText)
        }
        .contentTransition(.interpolate)
        .animation(LearnMotion.spatialStandardFast, value: date)
    }
}
