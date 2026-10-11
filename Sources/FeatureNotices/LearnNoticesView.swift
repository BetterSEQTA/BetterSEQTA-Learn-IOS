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
            LearnDateChrome(
                date: viewModel.selectedDate,
                onPrevious: viewModel.previousDay,
                onNext: viewModel.nextDay,
                onPickDate: { showDatePicker = true }
            )

            if !viewModel.labels.isEmpty {
                LearnNoticesLabelSegments(
                    labels: viewModel.labels,
                    selectedLabelId: viewModel.selectedLabelId,
                    onSelect: { viewModel.selectedLabelId = $0 }
                )
                .padding(.bottom, 8)
            }

            Group {
                if viewModel.isLoading {
                    LearnLoadingState(preset: .noticeList(rows: 7))
                } else if let error = viewModel.errorMessage, viewModel.notices.isEmpty {
                    LearnErrorBanner(message: error) {
                        Task { await viewModel.load() }
                    }
                } else if viewModel.filteredNotices.isEmpty {
                    LearnEmptyState(title: "No notices", message: "Nothing was published for this day.")
                } else {
                    List {
                        ForEach(Array(viewModel.filteredNotices.enumerated()), id: \.element.id) { index, notice in
                            Button {
                                LearnHaptics.lightImpact()
                                selectedNotice = notice
                            } label: {
                                LearnNoticeRow(notice: notice)
                            }
                            .learnRowPress()
                            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                            .listRowBackground(Color.clear)
                            .learnListEntrance(index: index)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .refreshable { await viewModel.load() }
                }
            }
        }
        .background { LearnScreenBackground() }
        .task { await viewModel.load() }
        .sheet(item: $selectedNotice) { notice in
            LearnNoticeDetailView(notice: notice)
        }
        .sheet(isPresented: $showDatePicker) {
            LearnGraphicalDateSheet(
                date: viewModel.selectedDate,
                onConfirm: { viewModel.selectDate($0); showDatePicker = false },
                onCancel: { showDatePicker = false }
            )
        }
        .learnShellNavigationDepth(0)
    }
}

private struct NoticeLabelFilter: Hashable {
    let id: Int?
}

private struct LearnNoticesLabelSegments: View {
    let labels: [NoticeLabel]
    let selectedLabelId: Int?
    let onSelect: (Int?) -> Void

    private var items: [(NoticeLabelFilter, String)] {
        var list: [(NoticeLabelFilter, String)] = [(NoticeLabelFilter(id: nil), "All")]
        list += labels.map { (NoticeLabelFilter(id: $0.id), $0.title) }
        return list
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LearnUnderlineSegmentBar(
                items: items.map { ($0.0, $0.1) },
                selection: NoticeLabelFilter(id: selectedLabelId),
                density: .compact,
                style: .discrete,
                onSelect: { onSelect($0.id) }
            )
            .frame(minWidth: UIScreen.main.bounds.width - 32)
        }
        .padding(.horizontal, LearnLayout.horizontalPadding)
    }
}

private struct LearnNoticeRow: View {
    let notice: Notice

    var body: some View {
        LearnListRow(
            accent: LearnSubjectColour.parse(notice.colour),
            title: notice.title,
            subtitle: notice.labelTitle,
            detail: notice.contentPreview(maxLength: 120),
            footnote: notice.staff
        )
    }
}

extension Notice: Identifiable {
    public var id: String { "\(title)-\(labelId ?? 0)-\(staff ?? "")" }
}

extension NoticeLabel: Identifiable {}
