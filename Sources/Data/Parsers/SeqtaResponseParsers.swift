import Domain
import Foundation

private let timetableExtraItemKeys = [
    "support", "supportLessons", "supportSessions", "supports",
    "alternates", "additionalItems", "extra",
]

public enum SeqtaResponseParsers {
    public static func parseLoginProfile(payload: Any?, fallbackUserName: String? = nil) -> UserProfile? {
        guard let root = payload as? JSONObject else { return nil }
        let profileObject = JSONObjectHelpers.nestedObject(root, keys: "user", "student", "person", "profile") ?? root
        guard let id = JSONObjectHelpers.int(profileObject, keys: "id", "userID", "userId", "student", "person") else {
            return nil
        }
        let userName = JSONObjectHelpers.string(profileObject, keys: "userName", "username", "userCode", "email")
            ?? fallbackUserName
            ?? JSONObjectHelpers.string(profileObject, keys: "displayName", "name")
        guard let userName else { return nil }
        return UserProfile(
            id: id,
            userName: userName,
            displayName: JSONObjectHelpers.string(profileObject, keys: "displayName", "name", "userDesc"),
            userDesc: JSONObjectHelpers.string(profileObject, keys: "userDesc", "description")
        )
    }

    public static func parseSubjectList(payload: Any?) -> [Subject] {
        let folders = collectSubjectFolders(payload: payload)
        let active = folders.filter(JSONObjectHelpers.isActiveFolder)
        let source = active.isEmpty ? Array(folders.prefix(1)) : active
        let nested = source.flatMap { folder in
            (JSONObjectHelpers.array(folder, keys: "subjects") ?? []).compactMap(parseSubjectRow)
        }
        if !nested.isEmpty { return nested }
        if let object = payload as? JSONObject,
           let items = JSONObjectHelpers.array(object, keys: "items") {
            let flat = items.compactMap(parseSubjectRow)
            if !flat.isEmpty { return flat }
        }
        return folders.compactMap(parseSubjectRow)
    }

    public static func parseAssessmentList(payload: Any?) -> [Assessment] {
        collectAssessmentRows(payload: payload).compactMap(parseAssessmentRow)
    }

    public struct AssessmentDetailFields: Sendable {
        public let title: String
        public let description: String?
        public let subjectCode: String
        public let dueDate: String?
        public let marked: Bool
        public let grade: String?
        public let percentage: Int?
        public let feedbackComment: String?
        public let expectations: [String]
        public let criteria: [AssessmentCriterion]
        public let resolvedMetaclass: Int?
        public let availableGrades: [String]
        public let fileSubmissionEnabled: Bool
    }

    public static func parseAssessmentDetail(payload: Any?, fallback: Assessment) -> AssessmentDetailFields {
        let root = payload as? JSONObject ?? [:]
        let title = JSONObjectHelpers.string(root, keys: "title", "name", "label") ?? fallback.title
        let description = JSONObjectHelpers.string(root, keys: "description")
        let subjectCode = JSONObjectHelpers.string(root, keys: "code", "subjectCode", "subject") ?? fallback.subjectCode
        let dueDate = JSONObjectHelpers.string(root, keys: "due", "dueDate", "due_date") ?? fallback.dueDate
        let criteria = (JSONObjectHelpers.array(root, keys: "criteria") ?? []).compactMap(parseAssessmentCriterion)
        let grade = extractGrade(root) ?? criteria.compactMap(\.grade).first ?? fallback.grade
        let percentage = extractPercentage(root) ?? criteria.compactMap(\.percentage).first ?? fallback.percentage
        let marked = extractMarked(root) || grade != nil || percentage != nil || fallback.marked
        let feedbackComment = JSONObjectHelpers.nestedObject(root, keys: "engagement")
            .flatMap { JSONObjectHelpers.string($0, keys: "feedbackComment", "comment") }
            .flatMap { $0.isEmpty ? nil : $0 }
        let expectations = (JSONObjectHelpers.array(root, keys: "expectations", "checklist") ?? [])
            .compactMap { element -> String? in
                guard let object = element as? JSONObject else { return nil }
                return JSONObjectHelpers.string(object, keys: "name", "label", "title")
            }
        let resolvedMetaclass = JSONObjectHelpers.int(root, keys: "metaclass")
        let availableGrades = parseAvailableGrades(root)
        let submissionSettings = JSONObjectHelpers.nestedObject(root, keys: "submissionSettings")
        let fileSubmissionEnabled = JSONObjectHelpers.bool(submissionSettings ?? [:], key: "fileSubmissionEnabled") ?? false
        return AssessmentDetailFields(
            title: title,
            description: description,
            subjectCode: subjectCode,
            dueDate: dueDate,
            marked: marked,
            grade: grade,
            percentage: percentage,
            feedbackComment: feedbackComment,
            expectations: expectations,
            criteria: criteria,
            resolvedMetaclass: resolvedMetaclass,
            availableGrades: availableGrades,
            fileSubmissionEnabled: fileSubmissionEnabled
        )
    }

    public static func parseAssessmentSubmissions(payload: Any?) -> [AssessmentSubmissionFile] {
        let rows: [Any]
        if let array = payload as? [Any] {
            rows = array
        } else if let object = payload as? JSONObject {
            rows = JSONObjectHelpers.array(object, keys: "items", "files", "submissions") ?? []
        } else {
            return []
        }
        return rows.compactMap { element in
            guard let row = element as? JSONObject else { return nil }
            return parseAssessmentSubmissionRow(row)
        }
    }

    public static func hasSubmissionEntries(payload: Any?) -> Bool {
        switch payload {
        case let object as JSONObject:
            return !object.isEmpty
        case let array as [Any]:
            return !array.isEmpty
        default:
            return false
        }
    }

    public static func parseMessageRecipients(payload: Any?, isStaff: Bool) -> [MessageRecipient] {
        let array: [Any]
        if let root = payload as? [Any] {
            array = root
        } else if let object = payload as? JSONObject {
            array = JSONObjectHelpers.array(object, keys: "items") ?? []
        } else {
            array = []
        }
        return array.compactMap { element in
            guard let row = element as? JSONObject else { return nil }
            guard let id = JSONObjectHelpers.int(row, keys: "id") else { return nil }
            let first = JSONObjectHelpers.string(row, keys: "firstname")
            let surname = JSONObjectHelpers.string(row, keys: "surname")
            let joined = [first, surname].compactMap { $0 }.joined(separator: " ").trimmingCharacters(in: .whitespaces)
            let displayName = JSONObjectHelpers.string(row, keys: "xx_display") ?? (joined.isEmpty ? nil : joined)
            guard let displayName else { return nil }
            let year = JSONObjectHelpers.string(row, keys: "year")
            let roll = JSONObjectHelpers.string(row, keys: "rollgroup")
            let meta = [year, roll].compactMap { $0 }.joined(separator: " · ")
            return MessageRecipient(
                id: id,
                displayName: displayName,
                isStaff: isStaff,
                meta: meta.isEmpty ? nil : meta
            )
        }
    }

    public static func parseSentMessageId(payload: Any?) -> Int {
        guard let object = payload as? JSONObject else { return 0 }
        return JSONObjectHelpers.int(object, keys: "id") ?? 0
    }

    public static func parseUploadedMessageFile(data: Data) -> MessageComposeAttachment? {
        guard let rootAny = try? JSONObjectHelpers.object(from: data),
              let root = rootAny as? JSONObject else {
            return nil
        }
        if let status = JSONObjectHelpers.string(root, keys: "status"), status != "200" {
            return nil
        }
        let payload = root["payload"] ?? root
        guard let object = payload as? JSONObject,
              let id = JSONObjectHelpers.int(object, keys: "id", "fileId") else {
            return nil
        }
        let filename = JSONObjectHelpers.string(object, keys: "filename", "name") ?? "attachment"
        let size = JSONObjectHelpers.int(object, keys: "size")
        return MessageComposeAttachment(id: id, filename: filename, byteCount: size)
    }

    public static func parseTimetableLessons(payload: Any?) -> [TimetableLesson] {
        collectTimetableRows(payload: payload).enumerated().compactMap { index, row in
            parseTimetableRow(row, index: index)
        }
    }

    public static func parsePortalList(payload: Any?) -> [Portal] {
        collectPortalRows(payload: payload)
            .compactMap(parsePortalRow)
            .sorted { $0.priority < $1.priority }
            .map(\.portal)
    }

    public static func parseNoticeLabelList(payload: Any?) -> [NoticeLabel] {
        collectNoticeRows(payload: payload).compactMap(parseNoticeLabelRow)
    }

    public static func parseNoticeList(payload: Any?) -> [Notice] {
        collectNoticeRows(payload: payload).compactMap(parseNoticeRow)
    }

    public static func parseCourseList(payload: Any?) -> [Course] {
        collectCourseRows(payload: payload).compactMap(parseCourseRow)
    }

    public static func parseCourseContent(payload: Any?) -> CourseContent? {
        let unwrapped = JSONObjectHelpers.unwrapSeqtaValue(payload)
        return LearnCourseDocumentParser.parseCoursePayload(unwrapped)
    }

    public static func parseCourseDocumentThemes(payload: Any?) -> [CourseDocumentTheme] {
        LearnCourseThemesParser.parseThemeCatalog(JSONObjectHelpers.unwrapSeqtaValue(payload))
    }

    public static func parseMessageList(payload: Any?) -> [MessageSummary] {
        collectMessageRows(payload: payload).compactMap(parseMessageRow)
    }

    public static func parseMessageDetail(payload: Any?, messageId: Int) -> MessageDetail? {
        guard let object = payload as? JSONObject else { return nil }
        let root = (object["message"] as? JSONObject) ?? object
        let html = JSONObjectHelpers.string(root, keys: "contents", "content", "body", "html")
            ?? JSONObjectHelpers.string(object, keys: "contents", "content", "body", "html")
            ?? ""
        let attachments = parseMessageAttachments(payload: root)
        let read = messageReadFlag(root)
        let starred = messageStarredFlag(root)
        return MessageDetail(
            id: messageId,
            htmlBody: html,
            attachments: attachments,
            read: read,
            starred: starred
        )
    }

    public static func parseMessageAttachments(payload: JSONObject) -> [MessageAttachment] {
        guard let files = JSONObjectHelpers.array(payload, keys: "files") else { return [] }
        return files.compactMap(parseMessageAttachmentRow)
    }

    // MARK: - Private

    private struct ParsedPortal {
        let portal: Portal
        let priority: Int
    }

    private static func collectSubjectFolders(payload: Any?) -> [JSONObject] {
        if let array = payload as? [JSONObject] { return array }
        guard let object = payload as? JSONObject else { return [] }
        if let items = JSONObjectHelpers.array(object, keys: "items", "folders", "subjects"), !items.isEmpty {
            return items
        }
        if object["subjects"] != nil { return [object] }
        return []
    }

    private static func parseSubjectRow(_ row: JSONObject) -> Subject? {
        guard let code = JSONObjectHelpers.string(row, keys: "code") else { return nil }
        let title = JSONObjectHelpers.string(row, keys: "title", "description", "name") ?? code
        let id = JSONObjectHelpers.int(row, keys: "id", "metaclass", "classunit", "programme") ?? code.hashValue
        return Subject(
            id: id,
            code: code,
            title: title,
            colour: JSONObjectHelpers.string(row, keys: "colour", "color", "icon"),
            programme: JSONObjectHelpers.int(row, keys: "programme", "programmeID", "programmeId"),
            metaclass: JSONObjectHelpers.int(row, keys: "metaclass", "metaclassID", "metaclassId", "classunit")
        )
    }

    private static func collectPortalRows(payload: Any?) -> [JSONObject] {
        if let array = payload as? [JSONObject] { return array }
        guard let object = payload as? JSONObject else { return [] }
        if let items = JSONObjectHelpers.array(object, keys: "items", "portals") { return items }
        if JSONObjectHelpers.int(object, keys: "id") != nil { return [object] }
        return []
    }

    private static func parsePortalRow(_ row: JSONObject) -> ParsedPortal? {
        guard let id = JSONObjectHelpers.int(row, keys: "id") else { return nil }
        let title = JSONObjectHelpers.string(row, keys: "label", "title", "name") ?? "Portal"
        let url = JSONObjectHelpers.string(row, keys: "url")
        let priority = JSONObjectHelpers.int(row, keys: "priority") ?? Int.max
        let isPower = JSONObjectHelpers.string(row, keys: "is_power_portal") == "true"
        let inherit = JSONObjectHelpers.string(row, keys: "inherit_styles") == "true"
        return ParsedPortal(
            portal: Portal(
                id: id,
                title: title,
                url: url?.isEmpty == true ? nil : url,
                uuid: JSONObjectHelpers.string(row, keys: "uuid"),
                isPowerPortal: isPower,
                inheritStyles: inherit
            ),
            priority: priority
        )
    }

    private static func collectNoticeRows(payload: Any?) -> [JSONObject] {
        if let array = payload as? [JSONObject] { return array }
        guard let object = payload as? JSONObject else { return [] }
        return JSONObjectHelpers.array(object, keys: "items", "notices") ?? []
    }

    private static func parseNoticeLabelRow(_ row: JSONObject) -> NoticeLabel? {
        guard let id = JSONObjectHelpers.int(row, keys: "id", "label") else { return nil }
        guard let title = JSONObjectHelpers.string(row, keys: "title", "label_title", "name") else { return nil }
        return NoticeLabel(id: id, title: title, colour: JSONObjectHelpers.string(row, keys: "colour", "color"))
    }

    private static func parseNoticeRow(_ row: JSONObject) -> Notice? {
        guard let title = JSONObjectHelpers.string(row, keys: "title") else { return nil }
        let contents =
            JSONObjectHelpers.string(row, keys: "contents", "content", "body", "html")
            ?? ""
        return Notice(
            title: title,
            labelTitle: JSONObjectHelpers.string(row, keys: "label_title", "labelTitle"),
            labelId: JSONObjectHelpers.int(row, keys: "label", "label_id", "labelId"),
            colour: JSONObjectHelpers.string(row, keys: "colour", "color"),
            staff: JSONObjectHelpers.string(row, keys: "staff", "author"),
            contents: contents
        )
    }

    private static func collectAssessmentRows(payload: Any?) -> [JSONObject] {
        if let array = payload as? [JSONObject] { return array }
        guard let object = payload as? JSONObject else { return [] }
        var rows: [JSONObject] = []
        for key in ["pending", "tasks", "items", "assessments", "data"] {
            rows.append(contentsOf: JSONObjectHelpers.array(object, keys: key) ?? [])
        }
        if let syllabus = object["syllabus"] as? [JSONObject] {
            for section in syllabus {
                rows.append(contentsOf: JSONObjectHelpers.array(section, keys: "assessments") ?? [])
            }
        }
        if !rows.isEmpty { return rows }
        if JSONObjectHelpers.int(object, keys: "id") != nil { return [object] }
        return []
    }

    private static func collectCourseRows(payload: Any?) -> [JSONObject] {
        if let array = payload as? [JSONObject] { return array }
        guard let object = payload as? JSONObject else { return [] }
        return JSONObjectHelpers.array(object, keys: "items", "courses") ?? []
    }

    private static func parseCourseRow(_ row: JSONObject) -> Course? {
        guard let id = JSONObjectHelpers.int(row, keys: "id") else { return nil }
        guard let title = JSONObjectHelpers.string(row, keys: "title", "name") else { return nil }
        let subjectCode = JSONObjectHelpers.string(row, keys: "subjectCode", "code", "subject") ?? title
        return Course(
            id: id,
            title: title,
            subjectCode: subjectCode,
            colour: JSONObjectHelpers.string(row, keys: "colour", "color")
        )
    }

    private static func collectMessageRows(payload: Any?) -> [JSONObject] {
        if let array = payload as? [JSONObject] { return array }
        guard let object = payload as? JSONObject else { return [] }
        if let messages = JSONObjectHelpers.array(object, keys: "messages"), !messages.isEmpty {
            return messages
        }
        return JSONObjectHelpers.array(object, keys: "items", "messages") ?? []
    }

    private static func parseMessageRow(_ row: JSONObject) -> MessageSummary? {
        guard let id = JSONObjectHelpers.int(row, keys: "messageID", "messageId", "id") else { return nil }
        guard let title = JSONObjectHelpers.string(row, keys: "subject", "title") else { return nil }
        let read = JSONObjectHelpers.bool(row, key: "read")
        let unreadExplicit = JSONObjectHelpers.bool(row, key: "unread")
        let unread: Bool
        if let unreadExplicit {
            unread = unreadExplicit
        } else if let read {
            unread = !read
        } else {
            unread = false
        }
        let subtitle = JSONObjectHelpers.string(row, keys: "preview", "subtitle")
            ?? JSONObjectHelpers.string(row, keys: "sender")
        let starred = messageStarredFlag(row)
        let files = JSONObjectHelpers.array(row, keys: "files")
        let hasAttachments = (files?.isEmpty == false)
            || (JSONObjectHelpers.bool(row, key: "attachments") == true)
            || ((JSONObjectHelpers.int(row, keys: "attachmentCount") ?? 0) > 0)
        return MessageSummary(
            id: id,
            title: title,
            subtitle: subtitle,
            timestamp: JSONObjectHelpers.string(row, keys: "date", "timestamp", "sent"),
            unread: unread,
            starred: starred,
            hasAttachments: hasAttachments
        )
    }

    private static func parseMessageAttachmentRow(_ row: JSONObject) -> MessageAttachment? {
        guard let id = JSONObjectHelpers.int(row, keys: "id") else { return nil }
        guard let uuid = JSONObjectHelpers.string(row, keys: "uuid", "context_uuid") else { return nil }
        return MessageAttachment(
            id: id,
            filename: JSONObjectHelpers.string(row, keys: "filename") ?? "attachment",
            mimetype: JSONObjectHelpers.string(row, keys: "mimetype") ?? "",
            size: JSONObjectHelpers.string(row, keys: "size") ?? "0",
            uuid: uuid
        )
    }

    private static func messageReadFlag(_ row: JSONObject) -> Bool {
        if let read = JSONObjectHelpers.bool(row, key: "read") { return read }
        if let unread = JSONObjectHelpers.bool(row, key: "unread") { return !unread }
        return true
    }

    private static func messageStarredFlag(_ row: JSONObject) -> Bool {
        JSONObjectHelpers.bool(row, key: "starred") ?? false
    }

    private static func criterionResults(_ row: JSONObject) -> JSONObject? {
        guard let criteria = JSONObjectHelpers.array(row, keys: "criteria"),
              let first = criteria.first else { return nil }
        return JSONObjectHelpers.nestedObject(first, keys: "results")
    }

    private static func parseAssessmentCriterion(_ row: JSONObject) -> AssessmentCriterion? {
        guard let name = JSONObjectHelpers.string(row, keys: "name", "label") else { return nil }
        let results = JSONObjectHelpers.nestedObject(row, keys: "results")
        let availableGrades = parseAvailableGrades(row)
        return AssessmentCriterion(
            id: JSONObjectHelpers.int(row, keys: "id"),
            name: name,
            description: JSONObjectHelpers.string(row, keys: "description"),
            grade: JSONObjectHelpers.string(results ?? [:], keys: "grade") ?? JSONObjectHelpers.string(row, keys: "grade"),
            percentage: JSONObjectHelpers.int(results ?? [:], keys: "percentage") ?? JSONObjectHelpers.int(row, keys: "percentage"),
            availableGrades: availableGrades,
            rubric: parseAssessmentRubric(row),
            rubricScores: parseRubricScores(row)
        )
    }

    private static func parseAvailableGrades(_ row: JSONObject) -> [String] {
        guard let raw = JSONObjectHelpers.array(row, keys: "availableGrades") else { return [] }
        return raw.compactMap { element in
            if let string = element as? String { return string }
            if let object = element as? JSONObject {
                return JSONObjectHelpers.string(object, keys: "grade", "label", "name")
            }
            return nil
        }
    }

    private static func parseAssessmentRubric(_ row: JSONObject) -> AssessmentRubric? {
        guard let rubricObject = JSONObjectHelpers.nestedObject(row, keys: "rubric") else { return nil }
        let lineRows = JSONObjectHelpers.array(rubricObject, keys: "lines") ?? []
        let lines: [AssessmentRubricLine] = lineRows.compactMap { element in
            guard let lineRow = element as? JSONObject,
                  let id = JSONObjectHelpers.int(lineRow, keys: "id") else { return nil }
            if JSONObjectHelpers.bool(lineRow, key: "deleted") == true { return nil }
            let descriptorRows = JSONObjectHelpers.array(lineRow, keys: "descriptors") ?? []
            let descriptors: [AssessmentRubricDescriptor] = descriptorRows.compactMap { descriptorElement in
                guard let descriptorRow = descriptorElement as? JSONObject,
                      let descriptorId = JSONObjectHelpers.int(descriptorRow, keys: "id") else { return nil }
                return AssessmentRubricDescriptor(
                    id: descriptorId,
                    score: JSONObjectHelpers.int(descriptorRow, keys: "score"),
                    grade: JSONObjectHelpers.string(descriptorRow, keys: "grade"),
                    content: JSONObjectHelpers.string(descriptorRow, keys: "content")
                )
            }
            return AssessmentRubricLine(
                id: id,
                title: JSONObjectHelpers.string(lineRow, keys: "title"),
                content: JSONObjectHelpers.string(lineRow, keys: "content"),
                weight: JSONObjectHelpers.int(lineRow, keys: "weight"),
                descriptors: descriptors
            )
        }
        guard !lines.isEmpty else { return nil }
        return AssessmentRubric(lines: lines)
    }

    private static func parseRubricScores(_ row: JSONObject) -> [String: AssessmentRubricScore] {
        guard let scoreObject = row["rubricScore"] as? JSONObject else { return [:] }
        var scores: [String: AssessmentRubricScore] = [:]
        for (key, value) in scoreObject {
            guard let entry = value as? JSONObject,
                  let descriptorId = JSONObjectHelpers.int(entry, keys: "id") else { continue }
            scores[key] = AssessmentRubricScore(
                descriptorId: descriptorId,
                grade: JSONObjectHelpers.string(entry, keys: "grade"),
                score: JSONObjectHelpers.int(entry, keys: "score"),
                content: JSONObjectHelpers.string(entry, keys: "content")
            )
        }
        return scores
    }

    private static func parseAssessmentSubmissionRow(_ row: JSONObject) -> AssessmentSubmissionFile? {
        let fileId = JSONObjectHelpers.int(row, keys: "id", "userfile", "fileId")
        let filename = JSONObjectHelpers.string(row, keys: "filename", "name") ?? "File"
        let mimeType = JSONObjectHelpers.string(row, keys: "mimetype", "mimeType") ?? "application/octet-stream"
        let sizeBytes = JSONObjectHelpers.int(row, keys: "size")
            ?? Int(JSONObjectHelpers.string(row, keys: "size") ?? "")
        let uuid = JSONObjectHelpers.string(row, keys: "uuid")
        let createdDate = JSONObjectHelpers.string(row, keys: "created_date", "createdDate")
        let isStaff = JSONObjectHelpers.bool(row, key: "staff") ?? false
        let resolvedId = fileId ?? uuid.map { abs($0.hashValue) }
        guard let id = resolvedId else { return nil }
        return AssessmentSubmissionFile(
            id: id,
            filename: filename,
            mimeType: mimeType,
            sizeBytes: sizeBytes,
            uuid: uuid,
            createdDate: createdDate,
            isStaff: isStaff
        )
    }

    private static func parseAssessmentRow(_ row: JSONObject) -> Assessment? {
        guard let id = JSONObjectHelpers.int(row, keys: "id", "assessmentId", "assessmentID") else { return nil }
        guard let subjectCode = JSONObjectHelpers.string(row, keys: "code", "subjectCode")
            ?? JSONObjectHelpers.string(row, keys: "subject") else { return nil }
        let title = JSONObjectHelpers.string(row, keys: "title", "name", "label") ?? "Assessment"
        let dueDate = JSONObjectHelpers.string(row, keys: "due", "dueDate", "due_date", "deadline", "date")
        let grade = extractGrade(row)
        let percentage = extractPercentage(row)
        let marked = extractMarked(row)
        var status = JSONObjectHelpers.string(row, keys: "status", "state")
        if let raw = status, raw.uppercased() == "OVERDUE", marked || grade != nil || percentage != nil {
            status = nil
        }
        if status == nil, marked { status = "MARKS_RELEASED" }
        return Assessment(
            id: id,
            title: title,
            subjectCode: subjectCode,
            dueDate: dueDate,
            status: status,
            grade: grade,
            percentage: percentage,
            marked: marked
        )
    }

    private static func extractGrade(_ row: JSONObject) -> String? {
        if let grade = JSONObjectHelpers.string(row, keys: "grade", "finalGrade", "letterGrade", "mark") {
            return grade
        }
        if let results = row["results"] as? JSONObject {
            if let grade = JSONObjectHelpers.string(results, keys: "grade", "letterGrade", "mark") { return grade }
        }
        if let criterion = criterionResults(row) {
            if let grade = JSONObjectHelpers.string(criterion, keys: "grade") { return grade }
        }
        if let criteria = JSONObjectHelpers.array(row, keys: "criteria"),
           let first = criteria.first,
           let grade = JSONObjectHelpers.string(first, keys: "grade") {
            return grade
        }
        return nil
    }

    private static func extractPercentage(_ row: JSONObject) -> Int? {
        if let value = JSONObjectHelpers.int(row, keys: "percentage", "percent", "score") { return value }
        if let results = row["results"] as? JSONObject {
            if let value = JSONObjectHelpers.int(results, keys: "percentage", "percent", "score") { return value }
        }
        if let criterion = criterionResults(row) {
            if let value = JSONObjectHelpers.int(criterion, keys: "percentage", "percent", "score") { return value }
        }
        if let criteria = JSONObjectHelpers.array(row, keys: "criteria"),
           let first = criteria.first,
           let value = JSONObjectHelpers.int(first, keys: "percentage") {
            return value
        }
        return nil
    }

    private static func extractMarked(_ row: JSONObject) -> Bool {
        let status = JSONObjectHelpers.string(row, keys: "status", "state") ?? ""
        let hasResults = extractGrade(row) != nil || extractPercentage(row) != nil
        if let graded = JSONObjectHelpers.bool(row, key: "graded"), graded { return true }
        if let marked = JSONObjectHelpers.bool(row, key: "marked"), marked { return true }
        if status.uppercased() == "MARKS_RELEASED" { return true }
        if status.localizedCaseInsensitiveContains("mark") || status.localizedCaseInsensitiveContains("release") {
            return true
        }
        if hasResults { return true }
        if let results = row["results"] as? JSONObject {
            if JSONObjectHelpers.bool(results, key: "graded") == true { return true }
            if JSONObjectHelpers.bool(results, key: "marked") == true { return true }
        }
        return false
    }

    private static func collectTimetableRows(payload: Any?) -> [JSONObject] {
        guard let object = payload as? JSONObject else { return [] }
        var out: [JSONObject] = []
        out.append(contentsOf: JSONObjectHelpers.array(object, keys: "items") ?? [])
        for key in timetableExtraItemKeys {
            out.append(contentsOf: JSONObjectHelpers.array(object, keys: key) ?? [])
        }
        return out
    }

    private static func parseTimetableRow(_ row: JSONObject, index: Int) -> TimetableLesson? {
        guard let dateRaw = JSONObjectHelpers.string(row, keys: "date") else { return nil }
        let date = String(dateRaw.prefix(10))
        let fromTime = JSONObjectHelpers.string(row, keys: "from")
        let untilTime = JSONObjectHelpers.string(row, keys: "until")
        guard fromTime != nil, untilTime != nil else { return nil }
        let subjectCode = JSONObjectHelpers.string(row, keys: "code", "subjectCode", "subject")
            ?? JSONObjectHelpers.string(row, keys: "description").map { String($0.prefix(32)) }
            ?? "—"
        let title = JSONObjectHelpers.string(row, keys: "description", "title", "name", "label") ?? subjectCode
        let room = JSONObjectHelpers.string(row, keys: "room", "room_code", "location", "venue")
        let teacher = JSONObjectHelpers.string(row, keys: "staff", "teacher", "staffName", "employee")
        let id = JSONObjectHelpers.string(row, keys: "uid", "id")
            ?? [date, subjectCode, String(index)].joined(separator: "-")
        return TimetableLesson(
            id: id,
            date: date,
            fromTime: fromTime,
            untilTime: untilTime,
            subjectCode: subjectCode,
            title: title,
            room: room,
            teacherName: teacher,
            colour: nil
        )
    }

}
