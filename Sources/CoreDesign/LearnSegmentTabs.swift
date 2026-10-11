import SwiftUI

private struct LearnSegmentBoundsKey<Item: Hashable>: PreferenceKey {
    static var defaultValue: [Item: Anchor<CGRect>] { [:] }

    static func reduce(value: inout [Item: Anchor<CGRect>], nextValue: () -> [Item: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

/// Segment control density (chrome height).
public enum LearnSegmentBarDensity: Sendable {
    case regular
    case compact
}

/// Fluid pill highlight vs crisp underline-only (discrete) switching.
public enum LearnSegmentBarStyle: Sendable {
    case fluid
    case discrete
}

/// Text + sliding accent underline. [HIG Layout](https://developer.apple.com/design/human-interface-guidelines/layout).
public struct LearnUnderlineSegmentBar<Item: Hashable>: View {
    private let items: [(item: Item, title: String)]
    private let selection: Item
    private let density: LearnSegmentBarDensity
    private let style: LearnSegmentBarStyle
    private let onSelect: (Item) -> Void

    public init(
        items: [(item: Item, title: String)],
        selection: Item,
        density: LearnSegmentBarDensity = .compact,
        style: LearnSegmentBarStyle = .discrete,
        onSelect: @escaping (Item) -> Void
    ) {
        self.items = items
        self.selection = selection
        self.density = density
        self.style = style
        self.onSelect = onSelect
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, entry in
                segment(entry.title, item: entry.item)
                    .frame(maxWidth: .infinity)
            }
        }
        .backgroundPreferenceValue(LearnSegmentBoundsKey<Item>.self, alignment: .center) { anchors in
            segmentIndicator(anchors: anchors)
        }
    }

    @ViewBuilder
    private func segmentIndicator(anchors: [Item: Anchor<CGRect>]) -> some View {
        GeometryReader { proxy in
            if let anchor = anchors[selection] {
                let rect = proxy[anchor]
                let corner = min(LearnTheme.controlCornerRadius + 4, rect.height / 2)
                if style == .fluid {
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .fill(LearnTheme.Colors.accent.opacity(0.16))
                        .overlay(
                            RoundedRectangle(cornerRadius: corner, style: .continuous)
                                .strokeBorder(LearnTheme.Colors.accent.opacity(0.22), lineWidth: 1)
                        )
                        .frame(width: rect.width + 6, height: rect.height + 2)
                        .position(x: rect.midX, y: rect.midY)
                        .animation(LearnMotion.liquidTabSpring, value: selection)
                }
                Capsule()
                    .fill(LearnTheme.Colors.accent)
                    .frame(width: max(20, rect.width * 0.55), height: underlineHeight)
                    .position(x: rect.midX, y: rect.maxY - underlineHeight / 2)
                    .animation(LearnMotion.liquidTabSpring, value: selection)
            }
        }
        .allowsHitTesting(false)
    }

    private var labelFont: Font {
        switch density {
        case .regular: LearnTypography.rowBody.weight(.medium)
        case .compact: LearnTypography.chip
        }
    }

    private var stackSpacing: CGFloat {
        density == .compact ? 4 : 8
    }

    private var topPadding: CGFloat {
        density == .compact ? 2 : 4
    }

    private var underlineHeight: CGFloat {
        density == .compact ? 2 : 3
    }

    private func segment(_ title: String, item: Item) -> some View {
        let selected = selection == item
        return Button {
            guard selection != item else { return }
            LearnHaptics.selection()
            withAnimation(LearnMotion.liquidTabSpring) {
                onSelect(item)
            }
        } label: {
            VStack(spacing: stackSpacing) {
                Text(title)
                    .font(selected ? labelFont.weight(.semibold) : labelFont)
                    .foregroundStyle(selected ? LearnTheme.Colors.primaryText : LearnTheme.Colors.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .padding(.horizontal, density == .compact ? 4 : 6)
                Color.clear.frame(height: underlineHeight + 2)
            }
            .padding(.top, topPadding)
            .padding(.bottom, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .anchorPreference(key: LearnSegmentBoundsKey<Item>.self, value: .bounds) { [item: $0] }
    }
}
