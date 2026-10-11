import SwiftUI

public enum LearnLayout {
    public static let readableMaxWidth: CGFloat = 640
    public static let horizontalPadding: CGFloat = 20
}

public struct LearnReadableWidthModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .frame(maxWidth: LearnLayout.readableMaxWidth)
            .frame(maxWidth: .infinity)
    }
}

extension View {
    public func learnReadableWidth() -> some View {
        modifier(LearnReadableWidthModifier())
    }
}

/// Section content separated by dividers only — no grey grouped box.
public struct LearnGroupedSection<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

public struct LearnGroupedDivider: View {
    public init() {}

    public var body: some View {
        LearnSeparatorHairline()
            .padding(.leading, LearnTheme.Spacing.md)
    }
}
