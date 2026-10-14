import CoreDesign
import Domain
import Foundation
import Observation

@MainActor
@Observable
public final class LearnCoursesViewModel {
    public var subjects: [Subject] = []
    public var isLoading = false
    public var errorMessage: String?
    public var downloadingCourseFileUUID: String?
    public var courseFileErrorMessage: String?

    private let repository: StudentRepository
    private var courseCache: [Int: CourseContent] = [:]
    private var courseLoadTasks: [Int: Task<CourseContent?, Never>] = [:]
    public var documentThemes: [CourseDocumentTheme] = []
    private var themesLoadTask: Task<Void, Never>?
    nonisolated(unsafe) private var cacheListenerTask: Task<Void, Never>?

    public init(repository: StudentRepository) {
        self.repository = repository
        cacheListenerTask = StudentCacheUpdateListener.start(prefixes: ["subjects", "courseContent.", "courseThemes"]) {
            [weak self] in
            await self?.hydrateFromCache()
        }
    }

    deinit {
        cacheListenerTask?.cancel()
    }

    private func hydrateFromCache() async {
        if let cached: [Subject] = await repository.cachedValue(StudentCacheKey.subjects.storageKey) {
            subjects = cached
            for subject in cached {
                guard let programme = subject.programme, let metaclass = subject.metaclass else { continue }
                let key = StudentCacheKey.courseContent(programme: programme, metaclass: metaclass).storageKey
                if let content: CourseContent = await repository.cachedValue(key) {
                    courseCache[subject.id] = content
                }
            }
        }
        if let themes: [CourseDocumentTheme] = await repository.cachedValue(StudentCacheKey.courseThemes.storageKey) {
            documentThemes = themes
        }
    }

    public func load() async {
        guard !isLoading else { return }
        await hydrateFromCache()
        isLoading = subjects.isEmpty
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

    func ensureDocumentThemesLoaded() async {
        if !documentThemes.isEmpty { return }
        if let themesLoadTask {
            await themesLoadTask.value
            return
        }
        let task = Task {
            switch await repository.getCourseDocumentThemes() {
            case .success(let themes):
                documentThemes = themes
            case .failure:
                break
            }
        }
        themesLoadTask = task
        await task.value
        themesLoadTask = nil
    }

    func resolvedTheme(for content: CourseContent, subjectCode: String) -> ResolvedCourseTheme {
        LearnCourseThemeStyle.resolve(
            content: content,
            catalog: documentThemes,
            subjectAccent: LearnSubjectColour.parse(subjectCode)
        )
    }

    public func loadCourse(for subject: Subject) async -> CourseContent? {
        await ensureDocumentThemesLoaded()
        await hydrateFromCache()
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

    public func openCourseFile(_ file: CourseResourceFile) async {
        guard downloadingCourseFileUUID == nil else { return }
        downloadingCourseFileUUID = file.uuid
        courseFileErrorMessage = nil
        defer { downloadingCourseFileUUID = nil }

        switch await repository.downloadCourseResourceFile(uuid: file.uuid) {
        case .success(let data):
            let opened = LearnSeqtaFilePresenter.present(
                data: data,
                filename: file.filename,
                mimetype: file.mimetype
            )
            if !opened {
                courseFileErrorMessage = "Could not open file"
            }
        case .failure:
            courseFileErrorMessage = "Could not download file"
        }
    }

    public func clearCourseFileError() {
        courseFileErrorMessage = nil
    }
}
