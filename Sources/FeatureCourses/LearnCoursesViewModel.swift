import Domain
import Foundation
import Observation

@MainActor
@Observable
public final class LearnCoursesViewModel {
    public var subjects: [Subject] = []
    public var courses: [Course] = []
    public var isLoading = false
    public var errorMessage: String?
    public var selectedSubject: Subject?

    private let repository: StudentRepository

    public init(repository: StudentRepository) {
        self.repository = repository
    }

    public func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        async let subjectsResult = repository.getSubjects()
        async let coursesResult = repository.getCourses()
        let subjectsResponse = await subjectsResult
        let coursesResponse = await coursesResult

        switch subjectsResponse {
        case .success(let value):
            subjects = value
        case .failure(let error):
            errorMessage = error.localizedDescription
        }

        if case .success(let value) = coursesResponse {
            courses = value
        }
    }

    public func courses(for subject: Subject) -> [Course] {
        courses.filter { $0.subjectCode == subject.code }
    }
}
