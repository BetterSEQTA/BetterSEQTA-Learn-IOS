import SwiftUI
import UIKit

// MARK: - Shell top bar

/// Shell header: menu or back · centered title · trailing actions (no Liquid Glass).
public struct LearnShellTopBar: View {
    private let leading: LearnShellTopBarLeading
    private let title: String?
    private let center: () -> AnyView
    private let trailing: () -> AnyView
    private let morphAnimationValue: AnyHashable

    public enum LearnShellTopBarLeading {
        case menu(action: () -> Void)
        case back(action: () -> Void)
    }

    public init(
        leading: LearnShellTopBarLeading,
        title: String? = nil,
        morphAnimationValue: AnyHashable = "static",
        @ViewBuilder trailing: @escaping () -> some View = { EmptyView() }
    ) {
        self.leading = leading
        self.title = title
        self.morphAnimationValue = morphAnimationValue
        self.center = { AnyView(EmptyView()) }
        self.trailing = { AnyView(trailing()) }
    }

    public init<Center: View, Trailing: View>(
        leading: LearnShellTopBarLeading,
        morphAnimationValue: AnyHashable = "static",
        @ViewBuilder center: @escaping () -> Center,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.leading = leading
        self.title = nil
        self.morphAnimationValue = morphAnimationValue
        self.center = { AnyView(center()) }
        self.trailing = { AnyView(trailing()) }
    }

    public var body: some View {
        ZStack {
            HStack(alignment: .center, spacing: 8) {
                leadingControl
                Spacer(minLength: 8)
                HStack(spacing: 4) {
                    trailing()
                }
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
            .padding(.horizontal, LearnTheme.Spacing.md)
            .padding(.vertical, 8)

            headerContent
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 72)
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity)
        .learnShellHeaderBackground()
        .animation(LearnMotion.spatialStandardFast, value: morphAnimationValue)
        .animation(LearnMotion.spatialStandardFast, value: title)
    }

    @ViewBuilder
    private var headerContent: some View {
        if let title {
            Text(title)
                .font(LearnTypography.shellTitle)
                .foregroundStyle(LearnTheme.Colors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .multilineTextAlignment(.center)
                .contentTransition(.interpolate)
        } else {
            center()
        }
    }

    @ViewBuilder
    private var leadingControl: some View {
        switch leading {
        case .menu(let action):
            shellBarIconButton(systemName: "line.3.horizontal", label: "Open menu", action: action)
        case .back(let action):
            shellBarIconButton(systemName: "chevron.left", label: "Back", action: action)
        }
    }

    private func shellBarIconButton(systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.body.weight(.semibold))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(LearnPressFeedbackStyle(scale: 0.92))
        .accessibilityLabel(label)
    }
}

extension View {
    /// Shell toolbar action styling (tap target + press feedback).
    public func learnShellTopBarAction<ID: Hashable & Sendable>(
        _ id: ID,
        shape: LearnToolbarMorphShape = .circle
    ) -> some View {
        modifier(LearnShellTopBarActionModifier(shape: shape))
    }
}

public enum LearnToolbarMorphShape: Sendable {
    case circle
    case capsule
}

private struct LearnShellTopBarActionModifier: ViewModifier {
    let shape: LearnToolbarMorphShape

    func body(content: Content) -> some View {
        content
            .buttonStyle(LearnPressFeedbackStyle(scale: 0.92))
            .modifier(ShellTopBarActionFrame(shape: shape))
    }
}

private struct ShellTopBarActionFrame: ViewModifier {
    let shape: LearnToolbarMorphShape

    func body(content: Content) -> some View {
        switch shape {
        case .circle:
            content.frame(minWidth: 44, minHeight: 44)
        case .capsule:
            content
        }
    }
}

/// Custom floating tab dock (optional). **Main shell uses system `TabView` for the floating Liquid Glass tab bar.**
public struct LearnShellBottomBar: View {
    @Namespace private var glassNamespace
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
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 0) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                    let selected = selectedTab == index
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
                        .padding(.vertical, 8)
                        .padding(.horizontal, 6)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(selected ? LearnTheme.Colors.accent : LearnTheme.Colors.secondaryText)
                        .learnTabDockGlass(selected: selected)
                    }
                    .buttonStyle(.plain)
                    .glassEffectID("tab-\(index)", in: glassNamespace)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: Capsule())
        .padding(.horizontal, LearnLayout.horizontalPadding)
        .padding(.bottom, 6)
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
