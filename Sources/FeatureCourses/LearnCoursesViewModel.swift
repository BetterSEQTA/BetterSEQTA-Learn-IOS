import Domain
import Foundation
import Observation

@MainActor
@Observable
public final class LearnCoursesViewModel {
    public var subjects: [Subject] = []
    public var isLoading = false
    public var errorMessage: String?

    private let repository: StudentRepository
    private var courseCache: [Int: CourseContent] = [:]
    private var courseLoadTasks: [Int: Task<CourseContent?, Never>] = [:]

    public init(repository: StudentRepository) {
        self.repository = repository
    }

    public func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        switch await repository.getSubjects() {
        case .success(let value):
            subjects = value
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    public func cachedCourse(for subject: Subject) -> CourseContent? {
        courseCache[subject.id]
    }

    public func loadCourse(for subject: Subject) async -> CourseContent? {
        if let cached = courseCache[subject.id] { return cached }
        if let existing = courseLoadTasks[subject.id] {
            return await existing.value
        }

        let task = Task<CourseContent?, Never> {
            guard let programme = subject.programme, let metaclass = subject.metaclass else {
                return nil
            }
            switch await repository.getCourseContent(programme: programme, metaclass: metaclass) {
            case .success(let content):
                courseCache[subject.id] = content
                return content
            case .failure:
                return nil
            }
        }
        courseLoadTasks[subject.id] = task
        let result = await task.value
        courseLoadTasks[subject.id] = nil
        return result
    }
}
