import CoreCommon
import CoreNetworking
import CoreSession
import Domain
import Foundation

public struct StudentRepositoryLive: StudentRepository, Sendable {
    private let sessionProvider: @Sendable () -> SessionData

    public init(sessionProvider: @escaping @Sendable () -> SessionData) {
        self.sessionProvider = sessionProvider
    }

    public func getProfile() async -> AppResult<UserProfile> {
        await safeCall {
            let session = try requireSession()
            let client = SeqtaStudentClient(session: session)
            let (data, _) = try await client.loginProfile()
            let payload = try JSONObjectHelpers.seqtaPayload(from: data)
            guard let profile = SeqtaResponseParsers.parseLoginProfile(
                payload: payload,
                fallbackUserName: sessionProvider().storedUsername
            ) else {
                throw RepositoryError.parseFailed("user profile")
            }
            return profile
        }
    }

    public func getSubjects() async -> AppResult<[Subject]> {
        await safeCall {
            let session = try requireSession()
            let client = SeqtaStudentClient(session: session)
            let (data, _) = try await client.post(.loadSubjects)
            let payload = try JSONObjectHelpers.seqtaPayload(from: data)
            return SeqtaResponseParsers.parseSubjectList(payload: payload)
        }
    }

    public func getCourses() async -> AppResult<[Course]> {
        await safeCall {
            let session = try requireSession()
            let client = SeqtaStudentClient(session: session)
            let (data, _) = try await client.post(.loadCourses)
            let payload = try JSONObjectHelpers.seqtaPayload(from: data)
            return SeqtaResponseParsers.parseCourseList(payload: payload)
        }
    }

    public func getTimetable(from: String?, until: String?) async -> AppResult<[TimetableLesson]> {
        await safeCall {
            let session = try requireSession()
            let client = SeqtaStudentClient(session: session)
            var body: [String: any Sendable] = [:]
            if let from { body["from"] = from }
            if let until { body["until"] = until }
            if let studentId = sessionProvider().resolvedUserId { body["student"] = studentId }
            let (data, _) = try await client.post(.loadTimetable, body: body)
            let payload = try JSONObjectHelpers.seqtaPayload(from: data)
            return SeqtaResponseParsers.parseTimetableLessons(payload: payload)
        }
    }

    public func getUpcomingAssessments() async -> AppResult<[Assessment]> {
        await safeCall {
            let session = try requireSession()
            let client = SeqtaStudentClient(session: session)
            var body: [String: any Sendable] = [:]
            if let studentId = sessionProvider().resolvedUserId { body["student"] = studentId }
            let (data, _) = try await client.post(.listUpcomingAssessments, body: body)
            let payload = try JSONObjectHelpers.seqtaPayload(from: data)
            return SeqtaResponseParsers.parseAssessmentList(payload: payload)
        }
    }

    public func getAssessmentDetail(
        assessment: Assessment,
        metaclass: Int,
        subjects: [Subject]
    ) async -> AppResult<AssessmentDetail> {
        await safeCall {
            let session = try requireSession()
            let client = SeqtaStudentClient(session: session)
            let studentId = sessionProvider().resolvedUserId ?? 0
            var resolvedMetaclass = AssessmentDetailSupport.resolveMetaclass(
                assessment: assessment,
                metaclass: metaclass,
                subjects: subjects
            )

            if resolvedMetaclass == 0, studentId > 0 {
                let probeBody: [String: any Sendable] = [
                    "assessment": assessment.id,
                    "student": studentId,
                    "metaclass": 0,
                ]
                let (probeData, _) = try await client.post(.getAssessment, body: probeBody)
                let probePayload = try JSONObjectHelpers.seqtaPayload(from: probeData)
                if let object = probePayload as? JSONObject,
                   let value = JSONObjectHelpers.int(object, keys: "metaclass") {
                    resolvedMetaclass = value
                }
            }

            let detailBody: [String: any Sendable] = [
                "assessment": assessment.id,
                "student": studentId,
                "metaclass": resolvedMetaclass,
            ]
            let (detailData, _) = try await client.post(.getAssessment, body: detailBody)
            let detailPayload = try JSONObjectHelpers.seqtaPayload(from: detailData)
            let parsed = SeqtaResponseParsers.parseAssessmentDetail(payload: detailPayload, fallback: assessment)

            let submissionsBody: [String: any Sendable] = [
                "assessment": assessment.id,
                "metaclass": resolvedMetaclass,
                "student": studentId,
            ]
            let (submissionsData, _) = try await client.post(.getSubmissions, body: submissionsBody)
            let submissionsPayload = try JSONObjectHelpers.seqtaPayload(from: submissionsData)
            let submitted = SeqtaResponseParsers.hasSubmissionEntries(payload: submissionsPayload)

            let subject = subjects.first { $0.code == (parsed.subjectCode) }
            let mergedAssessment = Assessment(
                id: assessment.id,
                title: parsed.title,
                subjectCode: parsed.subjectCode,
                dueDate: parsed.dueDate,
                status: parsed.marked
                    ? "MARKS_RELEASED"
                    : (submitted ? "SUBMITTED" : assessment.status),
                grade: parsed.grade,
                percentage: parsed.percentage,
                marked: parsed.marked
            )

            return AssessmentDetail(
                id: assessment.id,
                title: parsed.title,
                description: parsed.description,
                subjectCode: parsed.subjectCode,
                subjectTitle: subject?.title ?? parsed.subjectCode,
                dueDate: parsed.dueDate,
                marked: parsed.marked,
                displayStatus: AssessmentDetailSupport.displayStatus(for: mergedAssessment, submitted: submitted),
                submitted: submitted,
                overallGrade: parsed.grade,
                overallPercentage: parsed.percentage,
                feedbackComment: parsed.feedbackComment,
                expectations: parsed.expectations,
                criteria: parsed.criteria
            )
        }
    }

    public func getPastAssessments() async -> AppResult<[Assessment]> {
        await safeCall {
            let session = try requireSession()
            let client = SeqtaStudentClient(session: session)
            let subjectsData = try await client.post(.loadSubjects)
            let subjectsPayload = try JSONObjectHelpers.seqtaPayload(from: subjectsData.0)
            let subjects = SeqtaResponseParsers.parseSubjectList(payload: subjectsPayload)
            guard let studentId = sessionProvider().resolvedUserId else { return [] }

            var merged: [Int: Assessment] = [:]
            for subject in subjects {
                guard let programme = subject.programme, let metaclass = subject.metaclass else { continue }
                let body: [String: any Sendable] = [
                    "programme": programme,
                    "metaclass": metaclass,
                    "student": studentId,
                ]
                let (data, _) = try await client.post(.listPastAssessments, body: body)
                let payload = try JSONObjectHelpers.seqtaPayload(from: data)
                for assessment in SeqtaResponseParsers.parseAssessmentList(payload: payload) {
                    if merged[assessment.id] == nil {
                        merged[assessment.id] = assessment
                    }
                }
            }
            return Array(merged.values)
        }
    }

    public func getMessages(
        folder: MessageFolder,
        searchValue: String,
        offset: Int,
        limit: Int
    ) async -> AppResult<[MessageSummary]> {
        await safeCall {
            let trimmedSearch = searchValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let apiLabel: String = {
                switch folder {
                case .starred: MessageFolder.inbox.apiLabel
                default: folder.apiLabel
                }
            }()

            let page: [MessageSummary]
            if folder == .sent {
                async let sentPage = fetchMessagePage(
                    label: "sent",
                    searchValue: trimmedSearch,
                    offset: offset,
                    limit: limit
                )
                async let outboxPage = fetchMessagePage(
                    label: "outbox",
                    searchValue: trimmedSearch,
                    offset: offset,
                    limit: limit
                )
                let sent = try await sentPage
                let outbox = try await outboxPage
                var combined = sent + outbox
                combined.sort { ($0.timestamp ?? "") > ($1.timestamp ?? "") }
                page = Array(combined.prefix(limit))
            } else {
                page = try await fetchMessagePage(
                    label: apiLabel,
                    searchValue: trimmedSearch,
                    offset: offset,
                    limit: limit
                )
            }

            if folder == .starred {
                return page.filter(\.starred)
            }
            return page
        }
    }

    public func getMessageDetail(id: Int) async -> AppResult<MessageDetail> {
        await safeCall {
            let session = try requireSession()
            let client = SeqtaStudentClient(session: session)
            let body: [String: any Sendable] = [
                "action": "message",
                "id": id,
            ]
            let (data, _) = try await client.post(.loadMessages, body: body)
            let payload = try JSONObjectHelpers.seqtaPayload(from: data)
            guard let detail = SeqtaResponseParsers.parseMessageDetail(payload: payload, messageId: id) else {
                throw RepositoryError.parseFailed("message detail")
            }
            return detail
        }
    }

    public func setMessagesRead(ids: [Int], read: Bool) async -> AppResult<Void> {
        await safeCall {
            guard !ids.isEmpty else { return }
            let session = try requireSession()
            let client = SeqtaStudentClient(session: session)
            let body: [String: any Sendable] = [
                "mode": "x-read",
                "read": read,
                "items": ids,
            ]
            _ = try await client.post(.saveMessage, body: body)
        }
    }

    public func setMessagesStarred(ids: [Int], starred: Bool) async -> AppResult<Void> {
        await safeCall {
            guard !ids.isEmpty else { return }
            let session = try requireSession()
            let client = SeqtaStudentClient(session: session)
            let body: [String: any Sendable] = [
                "mode": "x-star",
                "starred": starred,
                "items": ids,
            ]
            _ = try await client.post(.saveMessage, body: body)
        }
    }

    public func moveMessagesToLabel(ids: [Int], label: String) async -> AppResult<Void> {
        await safeCall {
            guard !ids.isEmpty else { return }
            let session = try requireSession()
            let client = SeqtaStudentClient(session: session)
            let body: [String: any Sendable] = [
                "mode": "x-label",
                "label": label,
                "items": ids,
            ]
            _ = try await client.post(.saveMessage, body: body)
        }
    }

    public func downloadMessageAttachment(uuid: String) async -> AppResult<Data> {
        await safeCall {
            let session = try requireSession()
            let client = SeqtaStudentClient(session: session)
            let (data, response) = try await client.downloadMessageFile(uuid: uuid)
            guard (200 ... 299).contains(response.statusCode) else {
                throw RepositoryError.networkFailed("HTTP \(response.statusCode)")
            }
            guard !data.isEmpty else {
                throw RepositoryError.networkFailed("Empty attachment body")
            }
            return data
        }
    }

    private func fetchMessagePage(
        label: String,
        searchValue: String,
        offset: Int,
        limit: Int
    ) async throws -> [MessageSummary] {
        let session = try requireSession()
        let client = SeqtaStudentClient(session: session)
        let body: [String: any Sendable] = [
            "searchValue": searchValue,
            "sortBy": "date",
            "sortOrder": "desc",
            "action": "list",
            "label": label,
            "offset": offset,
            "limit": limit,
        ]
        let (data, _) = try await client.post(.loadMessages, body: body)
        let payload = try JSONObjectHelpers.seqtaPayload(from: data)
        return SeqtaResponseParsers.parseMessageList(payload: payload)
    }

    public func loadMessageRecipients(mode: String) async -> AppResult<[MessageRecipient]> {
        await safeCall {
            let session = try requireSession()
            let client = SeqtaStudentClient(session: session)
            let (data, _) = try await client.post(.loadMessagePeople, body: ["mode": mode])
            let payload = try JSONObjectHelpers.seqtaPayload(from: data)
            return SeqtaResponseParsers.parseMessageRecipients(payload: payload, isStaff: mode == "staff")
        }
    }

    public func uploadMessageComposeFile(filename: String, data: Data) async -> AppResult<MessageComposeAttachment> {
        await safeCall {
            guard !data.isEmpty else {
                throw RepositoryError.networkFailed("Empty file")
            }
            let session = try requireSession()
            let client = SeqtaStudentClient(session: session)
            let (responseData, response) = try await client.uploadComposeFile(
                filename: filename,
                fileData: data
            )
            guard (200 ... 299).contains(response.statusCode) else {
                throw RepositoryError.networkFailed("HTTP \(response.statusCode)")
            }
            guard let attachment = SeqtaResponseParsers.parseUploadedMessageFile(data: responseData) else {
                throw RepositoryError.networkFailed("Could not parse upload response")
            }
            return attachment
        }
    }

    public func sendMessage(
        subject: String,
        contents: String,
        recipients: [MessageRecipient],
        blind: Bool,
        fileIds: [Int] = []
    ) async -> AppResult<Int> {
        await safeCall {
            let session = try requireSession()
            let client = SeqtaStudentClient(session: session)
            let participants: [[String: any Sendable]] = recipients.map { recipient in
                var row: [String: any Sendable] = ["id": recipient.id]
                if recipient.isStaff {
                    row["staff"] = true
                } else {
                    row["student"] = true
                }
                return row
            }
            let body: [String: any Sendable] = [
                "subject": subject,
                "contents": contents,
                "blind": blind,
                "files": fileIds,
                "participants": participants,
            ]
            let (data, _) = try await client.post(.saveMessage, body: body)
            let payload = try JSONObjectHelpers.seqtaPayload(from: data)
            return SeqtaResponseParsers.parseSentMessageId(payload: payload)
        }
    }

    public func getPortals() async -> AppResult<[Portal]> {
        await safeCall {
            let session = try requireSession()
            let client = SeqtaStudentClient(session: session)
            let (data, _) = try await client.post(.loadPortals)
            let payload = try JSONObjectHelpers.seqtaPayload(from: data)
            return SeqtaResponseParsers.parsePortalList(payload: payload)
        }
    }

    public func getNoticeLabels() async -> AppResult<[NoticeLabel]> {
        await safeCall {
            let session = try requireSession()
            let client = SeqtaStudentClient(session: session)
            let (data, _) = try await client.post(.loadNotices, body: ["mode": "labels"])
            let payload = try JSONObjectHelpers.seqtaPayload(from: data)
            return SeqtaResponseParsers.parseNoticeLabelList(payload: payload)
        }
    }

    public func getNotices(date: String) async -> AppResult<[Notice]> {
        await safeCall {
            let session = try requireSession()
            let client = SeqtaStudentClient(session: session)
            let (data, _) = try await client.post(.loadNotices, body: ["date": date])
            let payload = try JSONObjectHelpers.seqtaPayload(from: data)
            return SeqtaResponseParsers.parseNoticeList(payload: payload)
        }
    }

    public func sendHeartbeat() async -> AppResult<Void> {
        await safeCall {
            let session = try requireSession()
            let client = SeqtaStudentClient(session: session)
            _ = try await client.heartbeat()
        }
    }

    // MARK: - Helpers

    private enum RepositoryError: Error {
        case notAuthenticated
        case parseFailed(String)
        case notImplemented
        case networkFailed(String)
    }

    private func requireSession() throws -> LearnSession {
        let data = sessionProvider()
        guard let session = LearnSession(sessionData: data) else {
            throw RepositoryError.notAuthenticated
        }
        return session
    }

    private func safeCall<T>(_ block: () async throws -> T) async -> AppResult<T> {
        do {
            return .success(try await block())
        } catch RepositoryError.notAuthenticated {
            return .failure(.auth(message: "Not authenticated"))
        } catch RepositoryError.notImplemented {
            return .failure(.network(message: "Not implemented"))
        } catch RepositoryError.networkFailed(let message) {
            return .failure(.network(message: message))
        } catch let error as SeqtaStudentTransportError {
            switch error {
            case .sessionExpired:
                LearnSessionExpiryNotifier.post()
                return .failure(.sessionExpired)
            case let .httpStatus(code):
                return .failure(.network(message: "HTTP \(code)"))
            case .invalidResponse:
                return .failure(.network(message: "Invalid response"))
            }
        } catch {
            return .failure(.network(message: error.localizedDescription))
        }
    }

    private func notImplemented<T>() async -> AppResult<T> {
        .failure(.network(message: "Not implemented"))
    }
}
