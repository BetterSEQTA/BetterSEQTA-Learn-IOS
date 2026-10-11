import Domain
import Foundation
import Observation

@MainActor
@Observable
public final class LearnTimetableViewModel {
    public var selectedDate = Calendar.current.startOfDay(for: Date())
    public var lessons: [TimetableLesson] = []
    public var isLoading = false
    public var isRefreshing = false
    public var errorMessage: String?

    private let repository: StudentRepository
    private let calendar = Calendar.current

    public init(repository: StudentRepository) {
        self.repository = repository
    }

    public func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        await fetchDay()
    }

    public func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        await fetchDay()
    }

    public func previousDay() {
        selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        Task { await fetchDay() }
    }

    public func nextDay() {
        selectedDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        Task { await fetchDay() }
    }

    public func selectDate(_ date: Date) {
        selectedDate = calendar.startOfDay(for: date)
        Task { await fetchDay() }
    }

    private func fetchDay() async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let day = formatter.string(from: selectedDate)
        let result = await repository.getTimetable(from: day, until: day)
        switch result {
        case .success(let items):
            lessons = items.filter { $0.date == day }
            errorMessage = nil
        case .failure(let error):
            errorMessage = error.localizedDescription
            lessons = []
        }
    }
}
