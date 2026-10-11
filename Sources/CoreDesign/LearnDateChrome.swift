import SwiftUI

/// Shared day navigation chrome (timetable, notices, home sections).
public struct LearnDateChrome: View {
    private let date: Date
    private let titleStyle: TitleStyle
    private let onPrevious: () -> Void
    private let onNext: () -> Void
    private let onPickDate: () -> Void

    public enum TitleStyle {
        case compact
        case prominent
    }

    public init(
        date: Date,
        titleStyle: TitleStyle = .compact,
        onPrevious: @escaping () -> Void,
        onNext: @escaping () -> Void,
        onPickDate: @escaping () -> Void
    ) {
        self.date = date
        self.titleStyle = titleStyle
        self.onPrevious = onPrevious
        self.onNext = onNext
        self.onPickDate = onPickDate
    }

    public var body: some View {
        HStack(spacing: 8) {
            chromeButton(systemName: "chevron.left", action: onPrevious)
            Spacer(minLength: 4)
            Button(action: onPickDate) {
                Group {
                    switch titleStyle {
                    case .compact:
                        Text(date, format: .dateTime.weekday(.abbreviated).month().day().year())
                            .font(.headline)
                    case .prominent:
                        VStack(spacing: 2) {
                            Text(date, format: .dateTime.weekday(.wide))
                                .font(.title3.weight(.semibold))
                            Text(date, format: .dateTime.month(.wide).day().year())
                                .font(.subheadline)
                                .foregroundStyle(LearnTheme.Colors.secondaryText)
                        }
                    }
                }
                .foregroundStyle(LearnTheme.Colors.primaryText)
                .contentTransition(.interpolate)
            }
            .buttonStyle(.plain)
            Spacer(minLength: 4)
            chromeButton(systemName: "chevron.right", action: onNext)
        }
        .padding(.horizontal, LearnLayout.horizontalPadding)
        .padding(.vertical, 8)
    }

    private func chromeButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button {
            LearnHaptics.selection()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.body.weight(.semibold))
                .frame(width: 36, height: 36)
        }
        .buttonStyle(LearnPressFeedbackStyle(scale: 0.92))
    }
}

public struct LearnGraphicalDateSheet: View {
    @State private var selection: Date
    private let onConfirm: (Date) -> Void
    private let onCancel: () -> Void

    public init(
        date: Date,
        onConfirm: @escaping (Date) -> Void,
        onCancel: @escaping () -> Void
    ) {
        _selection = State(initialValue: date)
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    public var body: some View {
        NavigationStack {
            DatePicker("Date", selection: $selection, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    LearnSheetToolbar(
                        title: "Select date",
                        onCancel: onCancel,
                        onDone: { onConfirm(selection) }
                    )
                }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .learnLiquidGlassSheetBackground()
    }
}
