import SwiftUI

public enum LearnLiquidGlass {}

extension View {
    @ViewBuilder
    private func applyGlass(in shape: some InsettableShape) -> some View {
        if #available(iOS 26.0, *) {
            background { shape.fill(.clear) }
                .glassEffect(.regular, in: shape)
        } else {
            background(.ultraThinMaterial, in: shape)
        }
    }

    /// Grouped list / home section container.
    public func learnGroupedGlass(cornerRadius: CGFloat = LearnTheme.cardCornerRadius) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return clipShape(shape)
            .applyGlass(in: shape)
            .overlay(shape.strokeBorder(LearnTheme.Colors.glassStroke.opacity(0.42), lineWidth: 1))
    }

    public func learnGroupedSurface(cornerRadius: CGFloat = LearnTheme.cardCornerRadius) -> some View {
        learnGroupedGlass(cornerRadius: cornerRadius)
    }

    public func learnGlassInsetField() -> some View {
        let shape = RoundedRectangle(cornerRadius: LearnTheme.controlCornerRadius, style: .continuous)
        return applyGlass(in: shape)
            .overlay(shape.strokeBorder(LearnTheme.Colors.glassStroke.opacity(0.25), lineWidth: 1))
    }

    /// Shell top/bottom bars — full-width glass band with hairline edge.
    public func learnChromeGlass(edge: VerticalEdge) -> some View {
        background {
            Rectangle()
                .fill(.clear)
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: edge == .top ? .top : .bottom)
        }
        .overlay(alignment: edge == .top ? .bottom : .top) {
            LearnSeparatorHairline()
        }
    }

    public func learnLiquidGlassBar(edge: VerticalEdge) -> some View {
        learnChromeGlass(edge: edge)
    }

    public func learnLiquidGlassSheetBackground() -> some View {
        background {
            LearnTheme.Colors.background
                .ignoresSafeArea()
        }
    }

    public func learnLiquidGlassPanel(cornerRadius: CGFloat = LearnTheme.cardCornerRadius) -> some View {
        learnGroupedGlass(cornerRadius: cornerRadius)
    }

    @ViewBuilder
    public func learnComposeMaterial(cornerRadius: CGFloat = 10) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        applyGlass(in: shape)
            .overlay(shape.strokeBorder(LearnTheme.Colors.glassStroke.opacity(0.3), lineWidth: 1))
    }
}

public struct LearnSeparatorHairline: View {
    public init() {}

    public var body: some View {
        Rectangle()
            .fill(LearnTheme.Colors.separator)
            .frame(height: 1 / UIScreen.main.scale)
    }
}
