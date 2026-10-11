import SwiftUI
import UIKit

/// Native-style shell top bar: single material background, leading-aligned title cluster.
public struct LearnShellTopBar: View {
    private let leading: LearnShellTopBarLeading
    private let title: String?
    private let center: () -> AnyView
    private let trailing: () -> AnyView

    public enum LearnShellTopBarLeading {
        case menu(action: () -> Void)
        case back(action: () -> Void)
    }

    public init(
        leading: LearnShellTopBarLeading,
        title: String? = nil,
        @ViewBuilder trailing: @escaping () -> some View = { EmptyView() }
    ) {
        self.leading = leading
        self.title = title
        self.center = { AnyView(EmptyView()) }
        self.trailing = { AnyView(trailing()) }
    }

    public init<Center: View, Trailing: View>(
        leading: LearnShellTopBarLeading,
        @ViewBuilder center: @escaping () -> Center,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.leading = leading
        self.title = nil
        self.center = { AnyView(center()) }
        self.trailing = { AnyView(trailing()) }
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 12) {
            leadingControl
            if let title {
                Text(title)
                    .font(LearnTypography.shellTitle)
                    .foregroundStyle(LearnTheme.Colors.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentTransition(.interpolate)
            } else {
                center()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            trailing()
        }
        .padding(.horizontal, LearnTheme.Spacing.md)
        .padding(.vertical, 8)
        .learnLiquidGlassBar(edge: .top)
        .animation(LearnMotion.spatialStandardFast, value: title)
    }

    @ViewBuilder
    private var leadingControl: some View {
        switch leading {
        case .menu(let action):
            Button(action: action) {
                Image(systemName: "line.3.horizontal")
                    .font(.body.weight(.semibold))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(LearnPressFeedbackStyle(scale: 0.92))
            .accessibilityLabel("Open menu")
        case .back(let action):
            Button(action: action) {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(LearnPressFeedbackStyle(scale: 0.92))
            .accessibilityLabel("Back")
        }
    }
}

public struct LearnShellBottomBar: View {
    @Binding var selectedTab: Int
    let tabs: [(title: String, systemImage: String, badge: Int?)]
    let onSelect: (Int) -> Void

    public init(
        selectedTab: Binding<Int>,
        tabs: [(title: String, systemImage: String, badge: Int?)],
        onSelect: @escaping (Int) -> Void
    ) {
        _selectedTab = selectedTab
        self.tabs = tabs
        self.onSelect = onSelect
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                let selected = selectedTab == index
                let distance = abs(index - selectedTab)
                let dockScale: CGFloat = selected ? 1.1 : (distance == 1 ? 1.04 : 1.0)
                Button {
                    LearnHaptics.selection()
                    withAnimation(LearnMotion.drawerSpring) {
                        onSelect(index)
                    }
                } label: {
                    VStack(spacing: 4) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: tab.systemImage)
                                .font(.system(size: 20, weight: selected ? .semibold : .regular))
                                .symbolVariant(selected ? .fill : .none)
                                .frame(height: 24)
                                .scaleEffect(dockScale)
                            if let badge = tab.badge, badge > 0 {
                                Text("\(min(badge, 99))")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color.red, in: Capsule())
                                    .offset(x: 10, y: -6)
                            }
                        }
                        Text(tab.title)
                            .font(.caption2.weight(selected ? .semibold : .regular))
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(selected ? LearnTheme.Colors.accent : LearnTheme.Colors.secondaryText)
                    .animation(LearnMotion.drawerSpring, value: selectedTab)
                    .sensoryFeedback(.selection, trigger: selected)
                }
                .buttonStyle(LearnPressFeedbackStyle(scale: 0.94))
            }
        }
        .padding(.horizontal, 6)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .learnLiquidGlassBar(edge: .bottom)
    }
}

public enum LearnHaptics {
    @MainActor
    public static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    @MainActor
    public static func lightImpact() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
