import SwiftUI

// Khagwal-inspired fluid micro-interactions (springs, morphing, inline disclosure).

// MARK: - Morph success timing (copy / save / sync)

public enum LearnMorphSuccessFeedback {
    public static let holdDuration: Duration = .milliseconds(1200)
    public static let successAnimation: Animation = .spring(response: 0.38, dampingFraction: 0.72)
    public static let resetAnimation: Animation = LearnMotion.fluidMorphSpring

    @MainActor
    public static func run(
        richAnimations: Bool,
        setSuccess: @escaping (Bool) -> Void
    ) async {
        withAnimation(successAnimation) { setSuccess(true) }
        if richAnimations {
            try? await Task.sleep(for: holdDuration)
        }
        withAnimation(resetAnimation) { setSuccess(false) }
    }
}

// MARK: - Copy morph (label + symbol replace)

public struct LearnCopyMorphButton: View {
    private let text: String
    private let accessibilityLabel: String

    @State private var copied = false
    @Environment(\.learnMotionProfile) private var motionProfile

    public init(text: String, accessibilityLabel: String = "Copy") {
        self.text = text
        self.accessibilityLabel = accessibilityLabel
    }

    public var body: some View {
        Button {
            guard !text.isEmpty else { return }
            UIPasteboard.general.string = text
            LearnHaptics.selection()
            Task {
                await LearnMorphSuccessFeedback.run(richAnimations: motionProfile.richAnimations) { copied = $0 }
            }
        } label: {
            Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                .font(LearnTypography.rowBody.weight(.medium))
                .contentTransition(.symbolEffect(.replace))
                .foregroundStyle(copied ? Color.green.opacity(0.9) : LearnTheme.Colors.accent)
        }
        .buttonStyle(LearnPressFeedbackStyle(scale: copied ? 0.94 : 0.96))
        .accessibilityLabel(accessibilityLabel)
    }
}

/// Toolbar / inline nav icon — same copy → checkmark choreography as notices.
public struct LearnCopyMorphIconButton: View {
    private let text: String
    private let accessibilityLabel: String

    @State private var copied = false
    @Environment(\.learnMotionProfile) private var motionProfile

    public init(text: String, accessibilityLabel: String = "Copy") {
        self.text = text
        self.accessibilityLabel = accessibilityLabel
    }

    public var body: some View {
        Button {
            guard !text.isEmpty else { return }
            UIPasteboard.general.string = text
            LearnHaptics.selection()
            Task {
                await LearnMorphSuccessFeedback.run(richAnimations: motionProfile.richAnimations) { copied = $0 }
            }
        } label: {
            Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                .font(.body.weight(.semibold))
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 32, height: 32)
                .foregroundStyle(copied ? Color.green.opacity(0.92) : LearnTheme.Colors.accent)
        }
        .buttonStyle(LearnPressFeedbackStyle(scale: copied ? 0.94 : 0.96))
        .accessibilityLabel(accessibilityLabel)
    }
}

/// Inline row: title + morphing copy control (settings, account rows).
public struct LearnCopyMorphRow: View {
    private let title: String
    private let value: String

    public init(title: String, value: String) {
        self.title = title
        self.value = value
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(LearnTypography.rowMeta)
                    .foregroundStyle(LearnTheme.Colors.tertiaryText)
                Text(value)
                    .font(LearnTypography.rowBody)
                    .foregroundStyle(LearnTheme.Colors.primaryText)
                    .textSelection(.enabled)
            }
            Spacer(minLength: 8)
            LearnCopyMorphIconButton(text: value, accessibilityLabel: "Copy \(title)")
        }
    }
}

// MARK: - Morphing icon button (copy / save / confirm)

public enum LearnMorphingIconPhase: Equatable {
    case idle
    case working
    case success
}

public struct LearnMorphingIconButton: View {
    private let systemImage: String
    private let successImage: String
    private let accessibilityLabel: String
    private let action: () async -> Bool

    @State private var phase: LearnMorphingIconPhase = .idle
    @Environment(\.learnMotionProfile) private var motionProfile

    public init(
        systemImage: String,
        successImage: String = "checkmark",
        accessibilityLabel: String,
        action: @escaping () async -> Bool
    ) {
        self.systemImage = systemImage
        self.successImage = successImage
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public var body: some View {
        Button {
            Task { await run() }
        } label: {
            ZStack {
                Image(systemName: imageName)
                    .font(.body.weight(.semibold))
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 32, height: 32)
                    .foregroundStyle(phase == .success ? Color.green.opacity(0.92) : LearnTheme.Colors.accent)
            }
        }
        .buttonStyle(LearnPressFeedbackStyle(scale: phase == .success ? 0.94 : 0.96))
        .accessibilityLabel(accessibilityLabel)
        .disabled(phase == .working)
    }

    private var imageName: String {
        switch phase {
        case .idle: systemImage
        case .working: systemImage
        case .success: successImage
        }
    }

    private func run() async {
        guard phase == .idle else { return }
        LearnHaptics.lightImpact()
        withAnimation(LearnMotion.spatialStandardFast) { phase = .working }
        let ok = await action()
        guard ok else {
            withAnimation(LearnMorphSuccessFeedback.resetAnimation) { phase = .idle }
            return
        }
        LearnHaptics.selection()
        withAnimation(LearnMorphSuccessFeedback.successAnimation) { phase = .success }
        try? await Task.sleep(for: motionProfile.richAnimations ? LearnMorphSuccessFeedback.holdDuration : .zero)
        withAnimation(LearnMorphSuccessFeedback.resetAnimation) { phase = .idle }
    }
}

/// Text button that morphs label to “Done” with the same spring as copy feedback.
public struct LearnMorphingTextButton: View {
    private let title: String
    private let successTitle: String
    private let action: () -> Void

    @State private var succeeded = false
    @Environment(\.learnMotionProfile) private var motionProfile

    public init(
        title: String,
        successTitle: String = "Done",
        action: @escaping () -> Void
    ) {
        self.title = title
        self.successTitle = successTitle
        self.action = action
    }

    public var body: some View {
        Button {
            action()
            LearnHaptics.selection()
            Task {
                await LearnMorphSuccessFeedback.run(richAnimations: motionProfile.richAnimations) {
                    succeeded = $0
                }
            }
        } label: {
            Text(succeeded ? successTitle : title)
                .font(LearnTypography.rowBody.weight(.semibold))
                .contentTransition(.interpolate)
                .foregroundStyle(succeeded ? Color.green.opacity(0.92) : LearnTheme.Colors.accent)
        }
        .buttonStyle(LearnPressFeedbackStyle(scale: 0.96))
    }
}

/// Brief checkmark flash after a one-shot action (restore, refresh, etc.).
public struct LearnMorphingActionIconButton: View {
    private let idleImage: String
    private let successImage: String
    private let tint: Color
    private let accessibilityLabel: String
    private let action: () async -> Bool

    @State private var succeeded = false
    @Environment(\.learnMotionProfile) private var motionProfile

    public init(
        idleImage: String,
        successImage: String = "checkmark.circle.fill",
        tint: Color = LearnTheme.Colors.accent,
        accessibilityLabel: String,
        action: @escaping () async -> Bool
    ) {
        self.idleImage = idleImage
        self.successImage = successImage
        self.tint = tint
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public var body: some View {
        Button {
            Task {
                let ok = await action()
                guard ok else { return }
                LearnHaptics.selection()
                await LearnMorphSuccessFeedback.run(richAnimations: motionProfile.richAnimations) {
                    succeeded = $0
                }
            }
        } label: {
            Image(systemName: succeeded ? successImage : idleImage)
                .font(.body.weight(.semibold))
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 32, height: 32)
                .foregroundStyle(succeeded ? Color.green.opacity(0.92) : tint)
        }
        .buttonStyle(LearnPressFeedbackStyle(scale: 0.96))
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - Inline delete confirmation (expand pill)

public struct LearnInlineDeleteConfirm: View {
    private let label: String
    private let onConfirm: () -> Void

    @State private var armed = false
    @State private var shakePhase: CGFloat = 0
    @Namespace private var pill
    @Environment(\.learnMotionProfile) private var motionProfile

    public init(label: String = "Delete", onConfirm: @escaping () -> Void) {
        self.label = label
        self.onConfirm = onConfirm
    }

    public var body: some View {
        HStack(spacing: armed ? 8 : 0) {
            if armed {
                Text("Confirm?")
                    .font(LearnTypography.rowMeta.weight(.semibold))
                    .foregroundStyle(Color.red.opacity(0.9))
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
                Button("Cancel") {
                    LearnHaptics.selection()
                    withAnimation(LearnMotion.fluidMorphSpring) { armed = false }
                }
                .font(LearnTypography.rowBody.weight(.medium))
                .foregroundStyle(LearnTheme.Colors.primaryText)
                .transition(.move(edge: .leading).combined(with: .opacity))
                Button("Delete") {
                    LearnHaptics.lightImpact()
                    onConfirm()
                    withAnimation(LearnMotion.fluidMorphSpring) { armed = false }
                }
                .font(LearnTypography.rowBody.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.92), in: Capsule())
                .transition(.scale(scale: 0.94).combined(with: .opacity))
            } else {
                Button {
                    LearnHaptics.selection()
                    withAnimation(LearnMotion.fluidMorphSpring) { armed = true }
                    runTrashShake()
                } label: {
                    Image(systemName: "trash")
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(shakePhase))
                }
                .foregroundStyle(.red)
                .learnPressFeedback(scale: 0.96)
            }
        }
        .padding(.horizontal, armed ? 10 : 0)
        .padding(.vertical, armed ? 6 : 0)
        .background {
            if armed {
                Capsule()
                    .fill(Color.red.opacity(0.12))
                    .matchedGeometryEffect(id: "pill", in: pill)
            }
        }
        .animation(LearnMotion.fluidMorphSpring, value: armed)
        .accessibilityLabel(armed ? "Confirm delete" : label)
    }

    private func runTrashShake() {
        guard motionProfile.richAnimations else { return }
        let steps: [CGFloat] = [-10, 10, -7, 7, -3, 0]
        for (index, angle) in steps.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.045) {
                withAnimation(LearnMotion.spatialStandardFast) { shakePhase = angle }
            }
        }
    }
}

/// Inline second-step confirmation (log out, reset, etc.) without a modal.
public struct LearnInlineDestructiveConfirm: View {
    private let idleTitle: String
    private let confirmTitle: String
    private let systemImage: String
    private let onConfirm: () -> Void

    @State private var armed = false

    public init(
        idleTitle: String,
        confirmTitle: String = "Confirm",
        systemImage: String = "rectangle.portrait.and.arrow.right",
        onConfirm: @escaping () -> Void
    ) {
        self.idleTitle = idleTitle
        self.confirmTitle = confirmTitle
        self.systemImage = systemImage
        self.onConfirm = onConfirm
    }

    public var body: some View {
        HStack(spacing: armed ? 10 : 0) {
            if armed {
                Button("Cancel", role: .cancel) {
                    LearnHaptics.selection()
                    withAnimation(LearnMotion.fluidMorphSpring) { armed = false }
                }
                .font(LearnTypography.rowBody.weight(.medium))
                Button(confirmTitle, role: .destructive) {
                    LearnHaptics.lightImpact()
                    onConfirm()
                    withAnimation(LearnMotion.fluidMorphSpring) { armed = false }
                }
                .font(LearnTypography.rowBody.weight(.semibold))
            } else {
                Button(idleTitle, systemImage: systemImage) {
                    LearnHaptics.selection()
                    withAnimation(LearnMotion.fluidMorphSpring) { armed = true }
                }
                .foregroundStyle(.red)
            }
        }
        .animation(LearnMotion.fluidMorphSpring, value: armed)
        .accessibilityLabel(armed ? "Confirm \(idleTitle.lowercased())" : idleTitle)
    }
}

/// Master toggle that unfolds dependent controls (switch disclosure).
public struct LearnSwitchDisclosure<Content: View>: View {
    private let title: String
    @Binding private var isOn: Bool
    private let content: Content

    public init(
        _ title: String,
        isOn: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        _isOn = isOn
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Toggle(title, isOn: $isOn)
                .onChange(of: isOn) { _, on in
                    if on { LearnHaptics.selection() }
                }
            if isOn {
                content
                    .padding(.top, 8)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity
                        )
                    )
            }
        }
        .animation(LearnMotion.spatialStandardDefault, value: isOn)
    }
}

// MARK: - Timed undo bar

public struct LearnTimedUndoBar: View {
    let message: String
    let duration: TimeInterval
    let onUndo: () -> Void
    let onComplete: () -> Void

    @State private var progress: CGFloat = 1
    @Environment(\.learnMotionProfile) private var motionProfile

    public init(
        message: String,
        duration: TimeInterval = 5,
        onUndo: @escaping () -> Void,
        onComplete: @escaping () -> Void
    ) {
        self.message = message
        self.duration = duration
        self.onUndo = onUndo
        self.onComplete = onComplete
    }

    public var body: some View {
        HStack(spacing: 12) {
            Text(message)
                .font(.subheadline)
                .foregroundStyle(LearnTheme.Colors.primaryText)
            Spacer(minLength: 8)
            Button("Undo") {
                LearnHaptics.selection()
                onUndo()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(LearnTheme.Colors.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(LearnTheme.Colors.groupedFill.opacity(0.6))
                    Capsule()
                        .fill(LearnTheme.Colors.accent.opacity(0.25))
                        .frame(width: geo.size.width * progress)
                }
            }
        }
        .clipShape(Capsule())
        .learnGroupedGlass(cornerRadius: 20)
        .onAppear { startTimer() }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func startTimer() {
        guard motionProfile.richAnimations else {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { onComplete() }
            return
        }
        withAnimation(.linear(duration: duration)) { progress = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { onComplete() }
    }
}

// MARK: - Progressive disclosure (inline reflow)

public struct LearnProgressiveDisclosure<Label: View, Content: View>: View {
    @Binding private var isExpanded: Bool
    private let label: Label
    private let content: Content

    public init(
        isExpanded: Binding<Bool>,
        @ViewBuilder label: () -> Label,
        @ViewBuilder content: () -> Content
    ) {
        _isExpanded = isExpanded
        self.label = label()
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                LearnHaptics.selection()
                withAnimation(LearnMotion.spatialStandardDefault) { isExpanded.toggle() }
            } label: {
                HStack {
                    label
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(LearnPressFeedbackStyle(scale: 0.99))

            if isExpanded {
                content
                    .padding(.top, 10)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity
                        )
                    )
            }
        }
        .clipped()
    }
}

// MARK: - Split card disclosure (seam opens)

public struct LearnSplitCardDisclosure<Summary: View, Detail: View>: View {
    @Binding private var isOpen: Bool
    private let summary: Summary
    private let detail: Detail

    public init(
        isOpen: Binding<Bool>,
        @ViewBuilder summary: () -> Summary,
        @ViewBuilder detail: () -> Detail
    ) {
        _isOpen = isOpen
        self.summary = summary()
        self.detail = detail()
    }

    public var body: some View {
        VStack(spacing: 0) {
            summary
                .learnGroupedGlass()
                .offset(y: isOpen ? -3 : 0)
                .zIndex(1)
            if isOpen {
                LearnSeparatorHairline()
                    .padding(.vertical, 4)
                    .transition(.opacity)
                detail
                    .learnGroupedGlass()
                    .scaleEffect(y: isOpen ? 1 : 0.94, anchor: .top)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onTapGesture {
            LearnHaptics.lightImpact()
            withAnimation(LearnMotion.fluidMorphSpring) { isOpen.toggle() }
        }
    }
}

// MARK: - Stateful capsule button

public struct LearnStatefulCapsuleButton: View {
    public enum Phase { case idle, loading, success }

    let title: String
    let successTitle: String
    let isEnabled: Bool
    let action: () async -> Bool

    @State private var phase: Phase = .idle
    @Environment(\.learnMotionProfile) private var motionProfile

    public init(
        title: String,
        successTitle: String = "Done",
        isEnabled: Bool = true,
        action: @escaping () async -> Bool
    ) {
        self.title = title
        self.successTitle = successTitle
        self.isEnabled = isEnabled
        self.action = action
    }

    public var body: some View {
        Button {
            Task { await perform() }
        } label: {
            HStack(spacing: 8) {
                if phase == .loading {
                    ProgressView().controlSize(.small)
                }
                Text(label)
                    .contentTransition(.interpolate)
            }
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, LearnTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: LearnTheme.controlCornerRadius, style: .continuous)
                    .fill(backgroundColor)
            )
            .scaleEffect(phase == .success ? 1.02 : 1)
        }
        .buttonStyle(LearnPressFeedbackStyle(scale: 0.97))
        .disabled(!isEnabled || phase == .loading)
        .animation(LearnMotion.spatialStandardDefault, value: phase)
    }

    private var label: String {
        switch phase {
        case .idle: title
        case .loading: title
        case .success: successTitle
        }
    }

    private var backgroundColor: Color {
        switch phase {
        case .success: Color.green.opacity(0.85)
        default: isEnabled ? LearnTheme.Colors.accent : LearnTheme.Colors.accent.opacity(0.4)
        }
    }

    private func perform() async {
        guard phase == .idle else { return }
        LearnHaptics.lightImpact()
        withAnimation(LearnMotion.spatialStandardFast) { phase = .loading }
        let ok = await action()
        withAnimation(LearnMotion.spatialExpressiveFast) { phase = ok ? .success : .idle }
        if ok { LearnHaptics.selection() }
        try? await Task.sleep(for: .milliseconds(motionProfile.richAnimations ? 700 : 0))
        withAnimation(LearnMotion.spatialStandardDefault) { phase = .idle }
    }
}

// MARK: - Fluid pagination pill

public struct LearnFluidPageIndicator: View {
    let count: Int
    let index: Int

    public init(count: Int, index: Int) {
        self.count = count
        self.index = index
    }

    public var body: some View {
        HStack(spacing: 6) {
            ForEach(0 ..< count, id: \.self) { i in
                let active = i == index
                Capsule()
                    .fill(active ? LearnTheme.Colors.accent : LearnTheme.Colors.separator)
                    .frame(width: active ? 14 : 5, height: 4)
            }
        }
        .animation(LearnMotion.spatialStandardDefault, value: index)
    }
}

// MARK: - Pop stepper (tumbler digits)

public struct LearnPopStepper: View {
    @Binding private var value: Int
    private let range: ClosedRange<Int>

    public init(value: Binding<Int>, range: ClosedRange<Int>) {
        _value = value
        self.range = range
    }

    public var body: some View {
        HStack(spacing: 12) {
            stepButton(systemImage: "minus", enabled: value > range.lowerBound) {
                value = max(range.lowerBound, value - 1)
            }
            Text("\(value)")
                .font(.title3.weight(.semibold).monospacedDigit())
                .frame(minWidth: 36)
                .contentTransition(.numericText())
                .animation(LearnMotion.spatialExpressiveFast, value: value)
            stepButton(systemImage: "plus", enabled: value < range.upperBound) {
                value = min(range.upperBound, value + 1)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .learnGroupedGlass(cornerRadius: 14)
    }

    private func stepButton(systemImage: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            LearnHaptics.selection()
            withAnimation(LearnMotion.spatialStandardDefault) { action() }
        } label: {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .frame(width: 28, height: 28)
        }
        .buttonStyle(LearnPressFeedbackStyle(scale: 0.9))
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.35)
    }
}

// MARK: - Split capsule (primary + menu)

public struct LearnSplitCapsuleButton: View {
    private let primaryTitle: String
    private let onPrimary: () -> Void
    private let onMenu: () -> Void

    @State private var separated = false

    public init(primaryTitle: String, onPrimary: @escaping () -> Void, onMenu: @escaping () -> Void) {
        self.primaryTitle = primaryTitle
        self.onPrimary = onPrimary
        self.onMenu = onMenu
    }

    public var body: some View {
        HStack(spacing: separated ? 8 : 0) {
            Button(primaryTitle, action: onPrimary)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(LearnTheme.Colors.accent, in: Capsule())
                .learnPressFeedback(scale: 0.97)

            if separated {
                Button {
                    onMenu()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(LearnTheme.Colors.primaryText)
                        .frame(width: 32, height: 32)
                        .learnGroupedGlass(cornerRadius: 16)
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                Button {
                    LearnHaptics.selection()
                    withAnimation(LearnMotion.spatialExpressiveFast) { separated = true }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                        .background(LearnTheme.Colors.accent.opacity(0.85), in: Capsule())
                }
            }
        }
        .animation(LearnMotion.spatialStandardDefault, value: separated)
    }
}

// MARK: - Morphing filter chips (discovery bar)

public struct LearnMorphingFilterChips: View {
    private let chips: [String]
    @Binding private var selection: String?
    private let defaultChip: String?

    public init(chips: [String], selection: Binding<String?>, defaultChip: String? = nil) {
        self.chips = chips
        _selection = selection
        self.defaultChip = defaultChip
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(chips.enumerated()), id: \.offset) { index, chip in
                    let active = isActive(chip)
                    Button {
                        LearnHaptics.selection()
                        withAnimation(LearnMotion.spatialStandardDefault) {
                            if active {
                                selection = defaultChip
                            } else {
                                selection = chip == defaultChip ? defaultChip : chip
                            }
                        }
                    } label: {
                        Text(chip)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                active
                                    ? LearnTheme.Colors.accent.opacity(0.22)
                                    : LearnTheme.Colors.groupedFill.opacity(0.5),
                                in: Capsule()
                            )
                    }
                    .learnPressFeedback(scale: 0.96)
                    .learnStaggeredAppear(index: index, baseDelay: 0.03)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func isActive(_ chip: String) -> Bool {
        if let defaultChip, selection == nil || selection == defaultChip {
            return chip == defaultChip
        }
        return selection == chip
    }
}
