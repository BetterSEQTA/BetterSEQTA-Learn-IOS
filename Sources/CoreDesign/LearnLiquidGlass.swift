import SwiftUI

/// Liquid Glass helpers aligned with
/// [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass).
public enum LearnLiquidGlass {}

extension View {
    @ViewBuilder
    private func applyGlass(in shape: some InsettableShape) -> some View {
        background { shape.fill(.clear) }
            .glassEffect(.regular, in: shape)
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

    /// Shell top/bottom bars — full-width Liquid Glass band (avoid opaque toolbar backgrounds here).
    public func learnChromeGlass(edge: VerticalEdge) -> some View {
        background {
            Rectangle()
                .fill(.clear)
                .glassEffect(.regular, in: Rectangle())
                .ignoresSafeArea(edges: edge == .top ? .top : .bottom)
        }
        .overlay(alignment: edge == .top ? .bottom : .top) {
            LearnSeparatorHairline()
        }
    }

    public func learnLiquidGlassBar(edge: VerticalEdge) -> some View {
        learnChromeGlass(edge: edge)
    }

    /// Shell header chrome — flat bar + hairline (no Liquid Glass).
    public func learnShellHeaderBackground() -> some View {
        background {
            LearnTheme.Colors.background
        }
        .overlay(alignment: .bottom) {
            LearnSeparatorHairline()
        }
    }

    /// Drawer / sidebar surface — use instead of `.ultraThinMaterial` so system glass lensing applies.
    public func learnSidebarGlass() -> some View {
        background {
            Rectangle()
                .fill(.clear)
                .glassEffect(.regular, in: Rectangle())
                .ignoresSafeArea()
        }
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

    /// Floating nav control (menu, back, toolbar actions) with interactive glass.
    public func learnNavGlassControl<ID: Hashable & Sendable>(id: ID, in namespace: Namespace.ID) -> some View {
        buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: .circle)
            .glassEffectID(id, in: namespace)
    }

    /// Selected tab dock pill in the shell bottom bar.
    public func learnTabDockGlass(selected: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        return glassEffect(
            selected
                ? .regular.tint(LearnTheme.Colors.accent.opacity(0.35)).interactive()
                : .identity,
            in: shape
        )
    }
}

/// Shared sampling region for morphing glass nav controls (see `GlassEffectContainer`).
public struct LearnGlassNavChrome<Content: View>: View {
    private let spacing: CGFloat
    private let content: Content

    public init(spacing: CGFloat = 12, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        GlassEffectContainer(spacing: spacing) {
            content
        }
    }
}

public struct LearnSeparatorHairline: View {
    public init() {}

    public var body: some View {
        Rectangle()
            .fill(LearnTheme.Colors.separator)
            .frame(height: 0.333)
    }
}
