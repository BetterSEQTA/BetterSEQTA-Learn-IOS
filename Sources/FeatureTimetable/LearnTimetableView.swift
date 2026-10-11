import CoreDesign
import Domain
import SwiftUI

public struct LearnTimetableView: View {
    @State private var viewModel: LearnTimetableViewModel
    @State private var showDatePicker = false

    public init(viewModel: LearnTimetableViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            LearnTimetableDateHeader(
                date: viewModel.selectedDate,
                onPrevious: viewModel.previousDay,
                onNext: viewModel.nextDay,
                onPickDate: { showDatePicker = true }
            )

            Group {
                if viewModel.isLoading {
                    LearnLoadingState()
                } else if let error = viewModel.errorMessage {
                    LearnErrorBanner(message: error) {
                        Task { await viewModel.refresh() }
                    }
                } else if viewModel.lessons.isEmpty {
                    LearnEmptyState(title: "No lessons", message: "No lessons found for this day.")
                } else {
                    List(viewModel.lessons) { lesson in
                        LearnGlassCard {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(lesson.subjectCode)
                                    .font(.headline)
                                    .foregroundStyle(LearnTheme.Colors.primaryText)
                                Text(lesson.title)
                                    .font(.subheadline)
                                    .foregroundStyle(LearnTheme.Colors.secondaryText)
                                if let room = lesson.room {
                                    Text(room)
                                        .font(.caption)
                                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                                }
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .refreshable { await viewModel.refresh() }
                }
            }
        }
        .background(LearnTheme.Colors.background)
        .task { await viewModel.load() }
        .sheet(isPresented: $showDatePicker) {
            LearnDatePickerSheet(date: viewModel.selectedDate) { picked in
                viewModel.selectDate(picked)
                showDatePicker = false
            } onCancel: {
                showDatePicker = false
            }
        }
    }
}

private struct LearnTimetableDateHeader: View {
    let date: Date
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onPickDate: () -> Void

    var body: some View {
        HStack {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Button(action: onPickDate) {
                Text(date, format: .dateTime.weekday(.wide).month().day().year())
                    .font(.headline)
                    .foregroundStyle(LearnTheme.Colors.primaryText)
            }
            Spacer()
            Button(action: onNext) {
                Image(systemName: "chevron.right")
            }
        }
        .buttonStyle(.plain)
        .padding()
    }
}

private struct LearnDatePickerSheet: View {
    @State private var selection: Date
    let onConfirm: (Date) -> Void
    let onCancel: () -> Void

    init(date: Date, onConfirm: @escaping (Date) -> Void, onCancel: @escaping () -> Void) {
        _selection = State(initialValue: date)
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationStack {
            DatePicker("Date", selection: $selection, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
                .navigationTitle("Select date")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", action: onCancel)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { onConfirm(selection) }
                    }
                }
        }
        .presentationDetents([.medium, .large])
    }
}

extension TimetableLesson: Identifiable {}
