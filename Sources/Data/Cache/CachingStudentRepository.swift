import CoreCommon
import CoreSession
import Domain
import Foundation

public struct CachingStudentRepository: StudentRepository, Sendable {
    private let live: StudentRepositoryLive
    private let database: StudentLocalDatabase
    private let sessionProvider: @Sendable () -> SessionData
    private let refreshTasks = RefreshTaskRegistry()

    init(
        live: StudentRepositoryLive,
        database: StudentLocalDatabase,
        sessionProvider: @escaping @Sendable () -> SessionData
    ) {
        self.live = live
        self.database = database
        self.sessionProvider = sessionProvider
    }

    public func readCachedJSON(storageKey: String) async -> Data? {
        let scope = cacheScope()
        return await database.loadData(scope: scope, key: storageKey)
    }

    public func clearPersistentCache() async {
        let scope = cacheScope()
        await database.clear(scope: scope)
    }

    public func getProfile() async -> AppResult<UserProfile> {
        await cachedFetch(key: .profile) { await live.getProfile() }
    }

    public func getSubjects() async -> AppResult<[Subject]> {
        await cachedFetch(key: .subjects) { await live.getSubjects() }
    }

    public func getCourses() async -> AppResult<[Course]> {
        await cachedFetch(key: .courses) { await live.getCourses() }
    }

    public func getCourseContent(programme: Int, metaclass: Int) async -> AppResult<CourseContent> {
        await cachedFetch(key: .courseContent(programme: programme, metaclass: metaclass)) {
            await live.getCourseContent(programme: programme, metaclass: metaclass)
        }
    }

    public func getCourseDocumentThemes() async -> AppResult<[CourseDocumentTheme]> {
        await cachedFetch(key: .courseThemes) { await live.getCourseDocumentThemes() }
    }

    public func getTimetable(from: String?, until: String?) async -> AppResult<[TimetableLesson]> {
        await cachedFetch(key: .timetable(from: from, until: until)) {
            await live.getTimetable(from: from, until: until)
        }
    }

    public func getUpcomingAssessments() async -> AppResult<[Assessment]> {
        await cachedFetch(key: .assessmentsUpcoming) { await live.getUpcomingAssessments() }
    }

    public func getPastAssessments() async -> AppResult<[Assessment]> {
        await cachedFetch(key: .assessmentsPast) { await live.getPastAssessments() }
    }

    public func getAssessmentDetail(
        assessment: Assessment,
        metaclass: Int,
        subjects: [Subject]
    ) async -> AppResult<AssessmentDetail> {
        await cachedFetch(key: .assessmentDetail(assessmentId: assessment.id)) {
            await live.getAssessmentDetail(assessment: assessment, metaclass: metaclass, subjects: subjects)
        }
    }

    public func getMessages(
        folder: MessageFolder,
        searchValue: String,
        offset: Int,
        limit: Int
    ) async -> AppResult<[MessageSummary]> {
        let key = StudentCacheKey.messages(folder: folder.rawValue, search: searchValue, offset: offset)
        if offset == 0 {
            return await cachedFetch(key: key) {
                await live.getMessages(folder: folder, searchValue: searchValue, offset: offset, limit: limit)
            }
        }
        return await live.getMessages(folder: folder, searchValue: searchValue, offset: offset, limit: limit)
    }

    public func getMessageDetail(id: Int) async -> AppResult<MessageDetail> {
        await cachedFetch(key: .messageDetail(id: id)) { await live.getMessageDetail(id: id) }
    }

    public func setMessagesRead(ids: [Int], read: Bool) async -> AppResult<Void> {
        let result = await live.setMessagesRead(ids: ids, read: read)
        if case .success = result {
            await invalidateMessageCaches()
        }
        return result
    }

    public func setMessagesStarred(ids: [Int], starred: Bool) async -> AppResult<Void> {
        let result = await live.setMessagesStarred(ids: ids, starred: starred)
        if case .success = result {
            await invalidateMessageCaches()
        }
        return result
    }

    public func moveMessagesToLabel(ids: [Int], label: String) async -> AppResult<Void> {
        let result = await live.moveMessagesToLabel(ids: ids, label: label)
        if case .success = result {
            await invalidateMessageCaches()
        }
        return result
    }

    public func downloadMessageAttachment(uuid: String) async -> AppResult<Data> {
        await live.downloadMessageAttachment(uuid: uuid)
    }

    public func downloadCourseResourceFile(uuid: String) async -> AppResult<Data> {
        await live.downloadCourseResourceFile(uuid: uuid)
    }

    public func loadMessageRecipients(mode: String) async -> AppResult<[MessageRecipient]> {
        await live.loadMessageRecipients(mode: mode)
    }

    public func uploadMessageComposeFile(filename: String, data: Data) async -> AppResult<MessageComposeAttachment> {
        await live.uploadMessageComposeFile(filename: filename, data: data)
    }

    public func sendMessage(
        subject: String,
        contents: String,
        recipients: [MessageRecipient],
        blind: Bool,
        fileIds: [Int]
    ) async -> AppResult<Int> {
        let result = await live.sendMessage(
            subject: subject,
            contents: contents,
            recipients: recipients,
            blind: blind,
            fileIds: fileIds
        )
        if case .success = result {
            await invalidateMessageCaches()
        }
        return result
    }

    public func getPortals() async -> AppResult<[Portal]> {
        await cachedFetch(key: .portals) { await live.getPortals() }
    }

    public func getNoticeLabels() async -> AppResult<[NoticeLabel]> {
        await cachedFetch(key: .noticeLabels) { await live.getNoticeLabels() }
    }

    public func getNotices(date: String) async -> AppResult<[Notice]> {
        await cachedFetch(key: .notices(date: date)) { await live.getNotices(date: date) }
    }

    public func sendHeartbeat() async -> AppResult<Void> {
        await live.sendHeartbeat()
    }

    // MARK: - Cache helpers

    private func cacheScope() -> String {
        StudentCacheScope.storageScope(for: sessionProvider())
    }

    private func cachedFetch<T: Codable & Sendable>(
        key: StudentCacheKey,
        fetch: @escaping @Sendable () async -> AppResult<T>
    ) async -> AppResult<T> {
        let scope = cacheScope()
        let storageKey = key.storageKey
        let cachedData = await database.loadData(scope: scope, key: storageKey)
        let cachedValue: T? = cachedData.flatMap { try? JSONDecoder().decode(T.self, from: $0) }

        if cachedValue != nil {
            scheduleRefresh(storageKey: storageKey, scope: scope, fetch: fetch)
            return .success(cachedValue!)
        }

        let fresh = await fetch()
        if case let .success(value) = fresh, let data = encode(value) {
            await database.save(scope: scope, key: storageKey, data: data)
        }
        return fresh
    }

    private func scheduleRefresh<T: Codable & Sendable>(
        storageKey: String,
        scope: String,
        fetch: @escaping @Sendable () async -> AppResult<T>
    ) {
        Task {
            let shouldRun = await refreshTasks.markStarted(storageKey)
            guard shouldRun else { return }
            let fresh = await fetch()
            if case let .success(value) = fresh, let data = encode(value) {
                await database.save(scope: scope, key: storageKey, data: data)
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .studentDataCacheDidUpdate,
                        object: nil,
                        userInfo: ["key": storageKey]
                    )
                }
            }
            await refreshTasks.markFinished(storageKey)
        }
    }

    private func encode<T: Encodable>(_ value: T) -> Data? {
        try? JSONEncoder().encode(value)
    }

    private func invalidateMessageCaches() async {
        let scope = cacheScope()
        await database.removeKeys(matchingPrefix: "messages.", scope: scope)
    }

}

/// Prevents duplicate in-flight background refreshes for the same cache key.
private actor RefreshTaskRegistry {
    private var inFlight: Set<String> = []

    func markStarted(_ key: String) -> Bool {
        if inFlight.contains(key) { return false }
        inFlight.insert(key)
        return true
    }

    func markFinished(_ key: String) {
        inFlight.remove(key)
    }
}
