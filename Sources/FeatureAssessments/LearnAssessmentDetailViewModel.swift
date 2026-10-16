import CoreDesign
import Domain
import Foundation
import Observation

@MainActor
@Observable
public final class LearnAssessmentDetailViewModel {
    public var detail: AssessmentDetail?
    public var isLoading = false
    public var errorMessage: String?
    public var selectedTab: LearnAssessmentDetailTab = .overview
    public var downloadingSubmissionUUID: String?
    public var submissionErrorMessage: String?

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

    public var visibleTabs: [LearnAssessmentDetailTab] {
        var tabs: [LearnAssessmentDetailTab] = [.overview, .details]
        if detail?.fileSubmissionEnabled == true {
            tabs.append(.submissions)
        }
        return tabs
    }

    public func load() async {
        guard !isLoading else { return }
        let cacheKey = StudentCacheKey.assessmentDetail(assessmentId: assessment.id).storageKey
        if let cached: AssessmentDetail = await repository.cachedValue(cacheKey) {
            detail = cached
            applyDefaultTab()
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
            applyDefaultTab()
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    public func downloadSubmission(_ file: AssessmentSubmissionFile) async {
        guard let uuid = file.uuid else { return }
        guard downloadingSubmissionUUID == nil else { return }
        downloadingSubmissionUUID = uuid
        submissionErrorMessage = nil
        defer { downloadingSubmissionUUID = nil }

        switch await repository.downloadAssessmentSubmissionFile(uuid: uuid) {
        case .success(let data):
            let opened = LearnSeqtaFilePresenter.present(
                data: data,
                filename: file.filename,
                mimetype: file.mimeType
            )
            if !opened {
                submissionErrorMessage = "Could not open file"
            }
        case .failure:
            submissionErrorMessage = "Could not download file"
        }
    }

    private func applyDefaultTab() {
        guard let detail else { return }
        let hasGrade = detail.marked
            && (detail.overallGrade != nil
                || detail.overallPercentage != nil
                || detail.criteria.first?.grade != nil
                || detail.criteria.first?.percentage != nil)
        if hasGrade {
            selectedTab = .details
        } else if !visibleTabs.contains(selectedTab) {
            selectedTab = .overview
        }
    }
}
