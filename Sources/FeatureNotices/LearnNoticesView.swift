import CoreDesign
import Domain
import SwiftUI

public struct LearnNoticesView: View {
    @State private var viewModel: LearnNoticesViewModel
    @State private var showDatePicker = false
    @State private var selectedNotice: Notice?

    public init(viewModel: LearnNoticesViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            LearnScreenHeader(title: "Notices", subtitle: "Daily school notices and bulletins")

            LearnNoticesDateHeader(
                date: viewModel.selectedDate,
                onPrevious: viewModel.previousDay,
                onNext: viewModel.nextDay,
                onPickDate: { showDatePicker = true }
            )

            if !viewModel.labels.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        LearnNoticeFilterChip(
                            title: "All",
                            isSelected: viewModel.selectedLabelId == nil
                        ) {
                            viewModel.selectedLabelId = nil
                        }
                        ForEach(viewModel.labels) { label in
                            LearnNoticeFilterChip(
                                title: label.title,
                                isSelected: viewModel.selectedLabelId == label.id
                            ) {
                                viewModel.selectedLabelId = label.id
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 8)
            }

            Group {
                if viewModel.isLoading {
                    LearnLoadingState()
                } else if let error = viewModel.errorMessage, viewModel.notices.isEmpty {
                    LearnErrorBanner(message: error) {
                        Task { await viewModel.load() }
                    }
                } else if viewModel.filteredNotices.isEmpty {
                    LearnEmptyState(title: "No notices", message: "Nothing was published for this day.")
                } else {
                    List(viewModel.filteredNotices) { notice in
                        Button {
                            selectedNotice = notice
                        } label: {
                            LearnNoticeRow(notice: notice)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .refreshable { await viewModel.load() }
                }
            }
        }
        .background(LearnTheme.Colors.background)
        .task { await viewModel.load() }
        .sheet(item: $selectedNotice) { notice in
            LearnNoticeDetailSheet(notice: notice)
        }
        .sheet(isPresented: $showDatePicker) {
            LearnNoticesDatePicker(
                date: viewModel.selectedDate,
                onConfirm: { viewModel.selectDate($0); showDatePicker = false },
                onCancel: { showDatePicker = false }
            )
        }
    }
}

private struct LearnNoticesDateHeader: View {
    let date: Date
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onPickDate: () -> Void

    var body: some View {
        HStack {
            Button(action: onPrevious) { Image(systemName: "chevron.left") }
            Spacer()
            Button(action: onPickDate) {
                Text(date, format: .dateTime.weekday(.abbreviated).month().day().year())
                    .font(.headline)
            }
            Spacer()
            Button(action: onNext) { Image(systemName: "chevron.right") }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }
}

private struct LearnNoticeFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor.opacity(0.25) : LearnTheme.Colors.card)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct LearnNoticeRow: View {
    let notice: Notice

    var body: some View {
        LearnGlassCard {
            VStack(alignment: .leading, spacing: 4) {
                if let label = notice.labelTitle {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                }
                Text(notice.title)
                    .font(.headline)
                    .foregroundStyle(LearnTheme.Colors.primaryText)
                if let staff = notice.staff {
                    Text(staff)
                        .font(.caption)
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                }
            }
        }
    }
}

private struct LearnNoticeDetailSheet: View {
    let notice: Notice
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(notice.title)
                        .font(.title2.weight(.semibold))
                    Text(notice.contents)
                        .font(.body)
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                }
                .padding()
            }
            .background(LearnTheme.Colors.background)
            .navigationTitle("Notice")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct LearnNoticesDatePicker: View {
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
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: onCancel) }
                    ToolbarItem(placement: .confirmationAction) { Button("Done") { onConfirm(selection) } }
                }
        }
        .presentationDetents([.medium, .large])
    }
}

extension Notice: Identifiable {
    public var id: String { "\(title)-\(labelId ?? 0)-\(staff ?? "")" }
}

extension NoticeLabel: Identifiable {}
