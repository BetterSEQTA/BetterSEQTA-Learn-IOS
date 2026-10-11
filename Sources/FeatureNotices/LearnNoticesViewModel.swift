import Domain
import Foundation
import Observation

@MainActor
@Observable
public final class LearnNoticesViewModel {
    public var selectedDate = Calendar.current.startOfDay(for: Date())
    public var labels: [NoticeLabel] = []
    public var notices: [Notice] = []
    public var selectedLabelId: Int?
    public var isLoading = false
    public var errorMessage: String?

    private let repository: StudentRepository
    private let calendar = Calendar.current

    public init(repository: StudentRepository) {
        self.repository = repository
    }

    public var filteredNotices: [Notice] {
        guard let labelId = selectedLabelId else { return notices }
        return notices.filter { $0.labelId == labelId }
    }

    public func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        async let labelsResult = repository.getNoticeLabels()
        async let noticesResult = repository.getNotices(date: formattedDate(selectedDate))
        let labelsResponse = await labelsResult
        let noticesResponse = await noticesResult

        switch labelsResponse {
        case .success(let value):
            labels = value
        case .failure:
            break
        }

        switch noticesResponse {
        case .success(let value):
            notices = value
        case .failure(let error):
            errorMessage = error.localizedDescription
            notices = []
        }
    }

    public func previousDay() {
        selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        Task { await loadNoticesOnly() }
    }

    public func nextDay() {
        selectedDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        Task { await loadNoticesOnly() }
    }

    public func selectDate(_ date: Date) {
        selectedDate = calendar.startOfDay(for: date)
        Task { await loadNoticesOnly() }
    }

    private func loadNoticesOnly() async {
        switch await repository.getNotices(date: formattedDate(selectedDate)) {
        case .success(let value):
            notices = value
            errorMessage = nil
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
