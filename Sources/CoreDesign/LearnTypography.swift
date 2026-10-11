import SwiftUI

/// Semantic type scale for consistent hierarchy and legibility (dark canvas).
public enum LearnTypography {
    public static let screenTitle = Font.largeTitle.weight(.bold)
    public static let shellTitle = Font.title3.weight(.bold)
    public static let sectionTitle = Font.title3.weight(.semibold)
    public static let sectionSubtitle = Font.subheadline
    public static let rowTitle = Font.body.weight(.semibold)
    public static let rowBody = Font.subheadline
    public static let rowMeta = Font.caption.weight(.medium)
    public static let caption = Font.caption
    public static let chip = Font.caption.weight(.semibold)

    public static let bodyLineSpacing: CGFloat = 3
    public static let titleLineSpacing: CGFloat = 2
}

extension View {
    /// Multi-line body copy with comfortable leading.
    public func learnReadableBody() -> some View {
        lineSpacing(LearnTypography.bodyLineSpacing)
            .fixedSize(horizontal: false, vertical: true)
    }

    public func learnReadableTitle() -> some View {
        lineSpacing(LearnTypography.titleLineSpacing)
    }
}
