import Domain
import Foundation
import Observation

@MainActor
@Observable
public final class LearnAssessmentDetailViewModel {
    public var detail: AssessmentDetail?
    public var isLoading = false
    public var errorMessage: String?

    private let repository: StudentRepository
    private let assessment: Assessment
    private let metaclass: Int
    private let subjects: [Subject]

    public init(
        repository: StudentRepository,
        assessment: Assessment,
        metaclass: Int,
        subjects: [Subject]
    ) {
        self.repository = repository
        self.assessment = assessment
        self.metaclass = metaclass
        self.subjects = subjects
    }

    public func load() async {
        guard !isLoading else { return }
        let cacheKey = StudentCacheKey.assessmentDetail(assessmentId: assessment.id).storageKey
        if let cached: AssessmentDetail = await repository.cachedValue(cacheKey) {
            detail = cached
        }
        isLoading = detail == nil
        errorMessage = nil
        defer { isLoading = false }

        switch await repository.getAssessmentDetail(
            assessment: assessment,
            metaclass: metaclass,
            subjects: subjects
        ) {
        case .success(let value):
            detail = value
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
}
