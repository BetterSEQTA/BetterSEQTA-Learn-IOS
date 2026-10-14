import Domain
import Foundation
import Observation

public enum LearnAssessmentsTab: String, CaseIterable, Sendable {
    case upcoming = "Upcoming"
    case past = "Past"
    case bySubject = "By subject"
}

@MainActor
@Observable
public final class LearnAssessmentsViewModel {
    public var selectedTab: LearnAssessmentsTab = .upcoming
    public var upcoming: [Assessment] = []
    public var past: [Assessment] = []
    public var subjects: [Subject] = []
    public var isLoading = false
    public var isRefreshing = false
    public var errorMessage: String?
    public var assessmentToOpen: Assessment?

    private let repository: StudentRepository
    nonisolated(unsafe) private var cacheListenerTask: Task<Void, Never>?

    public init(repository: StudentRepository) {
        self.repository = repository
        cacheListenerTask = StudentCacheUpdateListener.start(prefixes: ["assessments.", "subjects"]) { [weak self] in
            await self?.hydrateFromCache()
        }
    }

    deinit {
        cacheListenerTask?.cancel()
    }

    private func hydrateFromCache() async {
        if let cached: [Assessment] = await repository.cachedValue(StudentCacheKey.assessmentsUpcoming.storageKey) {
            upcoming = cached
        }
        if let cached: [Assessment] = await repository.cachedValue(StudentCacheKey.assessmentsPast.storageKey) {
            past = cached
        }
        if let cached: [Subject] = await repository.cachedValue(StudentCacheKey.subjects.storageKey) {
            subjects = cached
        }
    }

    public var visibleItems: [Assessment] {
        switch selectedTab {
        case .upcoming: upcoming
        case .past: past
        case .bySubject: []
        }
    }

    public var subjectGroups: [(subjectCode: String, items: [Assessment])] {
        let merged = upcoming + past.filter { pastItem in
            !upcoming.contains(where: { $0.id == pastItem.id })
        }
        let grouped = Dictionary(grouping: merged, by: \.subjectCode)
        return grouped.keys.sorted().map { code in
            let items = grouped[code] ?? []
            return (code, items.sorted { ($0.dueDate ?? "") < ($1.dueDate ?? "") })
        }
    }

    public func openAssessment(_ assessment: Assessment) {
        assessmentToOpen = assessment
        if past.contains(where: { $0.id == assessment.id }) {
            selectedTab = .past
        } else {
            selectedTab = .upcoming
        }
    }

    public func consumeAssessmentToOpen() -> Assessment? {
        let value = assessmentToOpen
        assessmentToOpen = nil
        return value
    }

    public func load() async {
        guard !isLoading else { return }
        await hydrateFromCache()
        isLoading = upcoming.isEmpty && past.isEmpty && subjects.isEmpty
        errorMessage = nil
        defer { isLoading = false }

        async let upcomingResult = repository.getUpcomingAssessments()
        async let pastResult = repository.getPastAssessments()
        async let subjectsResult = repository.getSubjects()
        let upcomingResponse = await upcomingResult
        let pastResponse = await pastResult
        let subjectsResponse = await subjectsResult

        switch upcomingResponse {
        case .success(let value):
            upcoming = value
        case .failure(let error):
            errorMessage = error.localizedDescription
        }

        if case .success(let value) = pastResponse {
            past = value
        }

        if case .success(let value) = subjectsResponse {
            subjects = value
        }
    }

    public func metaclass(for assessment: Assessment) -> Int {
        subjects.first { $0.code == assessment.subjectCode }?.metaclass ?? 0
    }

    public func detailViewModel(for assessment: Assessment) -> LearnAssessmentDetailViewModel {
        LearnAssessmentDetailViewModel(
            repository: repository,
            assessment: assessment,
            metaclass: metaclass(for: assessment),
            subjects: subjects
        )
    }

    public func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        await load()
    }
}
