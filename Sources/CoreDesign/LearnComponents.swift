import SwiftUI

// MARK: - Section header

public struct LearnSectionHeader: View {
    private let title: String
    private let subtitle: String?
    private let actionLabel: String?
    private let onAction: (() -> Void)?
    private let trailing: (() -> AnyView)?

    public init(
        title: String,
        subtitle: String? = nil,
        actionLabel: String? = nil,
        onAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.actionLabel = actionLabel
        self.onAction = onAction
        self.trailing = nil
    }

    public init<Trailing: View>(
        title: String,
        subtitle: String? = nil,
        actionLabel: String? = nil,
        onAction: (() -> Void)? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.actionLabel = actionLabel
        self.onAction = onAction
        self.trailing = { AnyView(trailing()) }
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(LearnTypography.sectionTitle)
                    .foregroundStyle(LearnTheme.Colors.primaryText)
                    .learnReadableTitle()
                if let subtitle {
                    Text(subtitle)
                        .font(LearnTypography.sectionSubtitle)
                        .foregroundStyle(LearnTheme.Colors.tertiaryText)
                }
            }
            Spacer(minLength: 8)
            if let trailing {
                trailing()
            }
            if let actionLabel, let onAction {
                Button(actionLabel) {
                    LearnHaptics.selection()
                    onAction()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(LearnTheme.Colors.accent)
                .learnPressFeedback(scale: 0.96)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - List row

public struct LearnListRow: View {
    private let accent: Color
    private let title: String
    private let subtitle: String?
    private let detail: String?
    private let footnote: String?
    private let showsChevron: Bool

    public init(
        accent: Color,
        title: String,
        subtitle: String? = nil,
        detail: String? = nil,
        footnote: String? = nil,
        showsChevron: Bool = false
    ) {
        self.accent = accent
        self.title = title
        self.subtitle = subtitle
        self.detail = detail
        self.footnote = footnote
        self.showsChevron = showsChevron
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(accent)
                .frame(width: 3)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 5) {
                if let subtitle {
                    Text(subtitle)
                        .font(LearnTypography.rowMeta)
                        .foregroundStyle(accent.opacity(0.92))
                        .textCase(.uppercase)
                }
                Text(title)
                    .font(LearnTypography.rowTitle)
                    .foregroundStyle(LearnTheme.Colors.primaryText)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .learnReadableTitle()
                if let detail {
                    Text(detail)
                        .font(LearnTypography.rowBody)
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                        .learnReadableBody()
                }
                if let footnote {
                    Text(footnote)
                        .font(LearnTypography.caption)
                        .foregroundStyle(LearnTheme.Colors.tertiaryText)
                }
            }
            Spacer(minLength: 0)
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(LearnTheme.Colors.secondaryText.opacity(0.7))
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

// MARK: - Search

public struct LearnSearchField: View {
    @Binding private var text: String
    private let placeholder: String
    private let compact: Bool
    private let onChange: (() -> Void)?

    @FocusState private var focused: Bool
    @Environment(\.learnMotionProfile) private var motionProfile

    public init(
        text: Binding<String>,
        placeholder: String = "Search",
        compact: Bool = true,
        onChange: (() -> Void)? = nil
    ) {
        _text = text
        self.placeholder = placeholder
        self.compact = compact
        self.onChange = onChange
    }

    public var body: some View {
        HStack(spacing: compact ? 8 : 10) {
            Image(systemName: "magnifyingglass")
                .font(compact ? .subheadline : .body)
                .foregroundStyle(focused ? LearnTheme.Colors.accent : LearnTheme.Colors.secondaryText)
            TextField(placeholder, text: $text)
                .font(compact ? .subheadline : .body)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focused)
                .onChange(of: text) { _, _ in onChange?() }
            if focused || !text.isEmpty {
                if !text.isEmpty {
                    Button {
                        text = ""
                        onChange?()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(LearnTheme.Colors.secondaryText)
                    }
                    .learnPressFeedback(scale: 0.9)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(.horizontal, focused ? (compact ? 14 : 16) : (compact ? 12 : 14))
        .padding(.vertical, focused ? (compact ? 9 : 12) : (compact ? 7 : 10))
        .scaleEffect(focused && motionProfile.richAnimations && !compact ? 1.02 : 1, anchor: .leading)
        .learnGlassInsetField()
        .animation(LearnMotion.spatialStandardDefault, value: focused)
    }
}

// MARK: - Status chip

public struct LearnStatusChip: View {
    private let title: String
    private let tint: Color

    public init(_ title: String, tint: Color) {
        self.title = title
        self.tint = tint
    }

    public var body: some View {
        Text(title)
            .font(LearnTypography.chip)
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.18), in: Capsule())
    }
}

// MARK: - Sheet toolbar

public struct LearnSheetToolbar: ToolbarContent {
    private let title: String
    private let onCancel: () -> Void
    private let onDone: () -> Void
    private let doneLabel: String

    public init(
        title: String,
        doneLabel: String = "Done",
        onCancel: @escaping () -> Void,
        onDone: @escaping () -> Void
    ) {
        self.title = title
        self.doneLabel = doneLabel
        self.onCancel = onCancel
        self.onDone = onDone
    }

    public var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(title)
                .font(.headline)
        }
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel", action: onCancel)
        }
        ToolbarItem(placement: .confirmationAction) {
            Button(doneLabel) {
                LearnHaptics.lightImpact()
                onDone()
            }
            .fontWeight(.semibold)
        }
    }
}

// MARK: - Grouped glass section wrapper

/// Inset grouped list row surface (Settings-style).
public struct LearnGlassListRowBackground: View {
    public init() {}

    public var body: some View {
        RoundedRectangle(cornerRadius: LearnTheme.controlCornerRadius, style: .continuous)
            .fill(LearnTheme.Colors.groupedFill.opacity(0.55))
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: LearnTheme.controlCornerRadius, style: .continuous))
    }
}

extension View {
    public func learnInsetSettingsList() -> some View {
        scrollContentBackground(.hidden)
            .background { LearnScreenBackground() }
    }
}

public struct LearnGlassGroupedSection<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 0) {
            content
        }
        .padding(.vertical, LearnTheme.Spacing.xs)
        .learnGroupedGlass()
    }
}
