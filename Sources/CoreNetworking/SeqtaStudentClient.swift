import CoreSession
import Foundation

/// Student API transport (paths mirror Android `SeqtaStudentApi`).
public struct SeqtaStudentClient: Sendable {
    public let session: LearnSession

    public init(session: LearnSession) {
        self.session = session
    }

    public enum StudentPath: String, Sendable {
        case login = "/seqta/student/login"
        case heartbeat = "/seqta/student/heartbeat"
        case loadSubjects = "/seqta/student/load/subjects"
        case loadCourses = "/seqta/student/load/courses"
        case loadTimetable = "/seqta/student/load/timetable"
        case listUpcomingAssessments = "/seqta/student/assessment/list/upcoming"
        case listPastAssessments = "/seqta/student/assessment/list/past"
        case getAssessment = "/seqta/student/assessment/get"
        case getSubmissions = "/seqta/student/assessment/submissions/get"
        case loadMessages = "/seqta/student/load/message"
        case saveMessage = "/seqta/student/save/message"
        case loadMessagePeople = "/seqta/student/load/message/people"
        case loadPortals = "/seqta/student/load/portals"
        case loadNotices = "/seqta/student/load/notices"
    }

    public func post(
        _ path: StudentPath,
        body: [String: any Sendable] = [:]
    ) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await learnSeqtaPOST(session: session, path: path.rawValue, body: body)
        try SeqtaStudentResponseValidation.validate(data: data, response: response)
        return (data, response)
    }

    public func heartbeat() async throws -> (Data, HTTPURLResponse) {
        try await post(.heartbeat, body: ["heartbeat": true])
    }

    public func loginProfile() async throws -> (Data, HTTPURLResponse) {
        try await post(.login, body: [:])
    }

    public func downloadStudentFile(type: String, uuid: String) async throws -> (Data, HTTPURLResponse) {
        try await learnSeqtaGET(
            session: session,
            path: "/seqta/student/load/file",
            queryItems: [
                URLQueryItem(name: "type", value: type),
                URLQueryItem(name: "file", value: uuid),
            ]
        )
    }

    public func downloadMessageFile(uuid: String) async throws -> (Data, HTTPURLResponse) {
        try await downloadStudentFile(type: "message", uuid: uuid)
    }

    /// Course overview (`cf`) and module resource blocks (Android `buildSeqtaFileUrl` default).
    public func downloadCourseResourceFile(uuid: String) async throws -> (Data, HTTPURLResponse) {
        try await downloadStudentFile(type: "resource", uuid: uuid)
    }

    public func downloadAssessmentSubmissionFile(uuid: String) async throws -> (Data, HTTPURLResponse) {
        try await downloadStudentFile(type: "submission", uuid: uuid)
    }

    public func uploadComposeFile(filename: String, fileData: Data) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await learnSeqtaUploadFile(
            session: session,
            filename: filename,
            fileData: fileData
        )
        try SeqtaStudentResponseValidation.validate(data: data, response: response)
        return (data, response)
    }
}
