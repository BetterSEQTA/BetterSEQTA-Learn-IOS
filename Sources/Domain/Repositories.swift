import CoreCommon
import Foundation

@MainActor
public protocol AuthRepository: AnyObject {
    func loginWithQr(deeplink: String) async -> AppResult<SessionData>
    func loginWithConnect(deeplink: String) async -> AppResult<SessionData>
    func loginWithCredentials(baseUrl: String, username: String, password: String) async -> AppResult<SessionData>
    func loginWithWebSession(baseUrl: String, jsessionId: String) async -> AppResult<SessionData>
    func validateHeartbeat() async -> AppResult<Void>
    func logout() async
    func currentSession() -> SessionData
}

public protocol StudentRepository: Sendable {
    func getProfile() async -> AppResult<UserProfile>
    func getSubjects() async -> AppResult<[Subject]>
    func getCourses() async -> AppResult<[Course]>
    func getCourseContent(programme: Int, metaclass: Int) async -> AppResult<CourseContent>
    func getTimetable(from: String?, until: String?) async -> AppResult<[TimetableLesson]>
    func getUpcomingAssessments() async -> AppResult<[Assessment]>
    func getPastAssessments() async -> AppResult<[Assessment]>
    func getAssessmentDetail(
        assessment: Assessment,
        metaclass: Int,
        subjects: [Subject]
    ) async -> AppResult<AssessmentDetail>
    func getMessages(
        folder: MessageFolder,
        searchValue: String,
        offset: Int,
        limit: Int
    ) async -> AppResult<[MessageSummary]>
    func getMessageDetail(id: Int) async -> AppResult<MessageDetail>
    func setMessagesRead(ids: [Int], read: Bool) async -> AppResult<Void>
    func setMessagesStarred(ids: [Int], starred: Bool) async -> AppResult<Void>
    func moveMessagesToLabel(ids: [Int], label: String) async -> AppResult<Void>
    func downloadMessageAttachment(uuid: String) async -> AppResult<Data>
    func loadMessageRecipients(mode: String) async -> AppResult<[MessageRecipient]>
    func uploadMessageComposeFile(filename: String, data: Data) async -> AppResult<MessageComposeAttachment>
    func sendMessage(
        subject: String,
        contents: String,
        recipients: [MessageRecipient],
        blind: Bool,
        fileIds: [Int]
    ) async -> AppResult<Int>
    func getPortals() async -> AppResult<[Portal]>
    func getNoticeLabels() async -> AppResult<[NoticeLabel]>
    func getNotices(date: String) async -> AppResult<[Notice]>
    func sendHeartbeat() async -> AppResult<Void>
}

@MainActor
public protocol CalendarSyncRepository: AnyObject {
    func authorizationStatus() -> CalendarSyncAuthorizationStatus
    func requestAccess() async -> CalendarSyncAuthorizationStatus
    func loadPreferences() -> CalendarSyncPreferences
    func savePreferences(_ preferences: CalendarSyncPreferences)
    func availableCalendars() -> [CalendarSyncCalendarOption]
    func syncNow() async -> AppResult<CalendarSyncSummary>
    /// Removes events previously created by BetterSEQTA Learn calendar sync.
    func removeSyncedEvents() async -> AppResult<Int>
}
