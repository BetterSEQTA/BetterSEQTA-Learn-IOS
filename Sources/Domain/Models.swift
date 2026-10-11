import Foundation

public struct UserProfile: Sendable, Equatable, Codable {
    public let id: Int
    public let userName: String
    public let displayName: String?
    public let userDesc: String?

    public init(id: Int, userName: String, displayName: String?, userDesc: String?) {
        self.id = id
        self.userName = userName
        self.displayName = displayName
        self.userDesc = userDesc
    }
}

public struct Subject: Sendable, Equatable, Hashable, Identifiable, Codable {
    public let id: Int
    public let code: String
    public let title: String
    public let colour: String?
    public let programme: Int?
    public let metaclass: Int?

    public init(
        id: Int,
        code: String,
        title: String,
        colour: String?,
        programme: Int? = nil,
        metaclass: Int? = nil
    ) {
        self.id = id
        self.code = code
        self.title = title
        self.colour = colour
        self.programme = programme
        self.metaclass = metaclass
    }
}

public struct Course: Sendable, Equatable, Identifiable, Codable {
    public let id: Int
    public let title: String
    public let subjectCode: String
    public let colour: String?

    public init(id: Int, title: String, subjectCode: String, colour: String?) {
        self.id = id
        self.title = title
        self.subjectCode = subjectCode
        self.colour = colour
    }
}

public struct TimetableLesson: Sendable, Equatable, Codable {
    public let id: String
    public let date: String
    public let fromTime: String?
    public let untilTime: String?
    public let subjectCode: String
    public let title: String
    public let room: String?
    public let colour: String?

    public init(
        id: String,
        date: String,
        fromTime: String? = nil,
        untilTime: String? = nil,
        subjectCode: String,
        title: String,
        room: String?,
        colour: String?
    ) {
        self.id = id
        self.date = date
        self.fromTime = fromTime
        self.untilTime = untilTime
        self.subjectCode = subjectCode
        self.title = title
        self.room = room
        self.colour = colour
    }
}

public struct Assessment: Sendable, Equatable, Hashable, Codable {
    public let id: Int
    public let title: String
    public let subjectCode: String
    public let dueDate: String?
    public let status: String?
    public let grade: String?
    public let percentage: Int?
    public let marked: Bool

    public init(
        id: Int,
        title: String,
        subjectCode: String,
        dueDate: String?,
        status: String?,
        grade: String? = nil,
        percentage: Int? = nil,
        marked: Bool = false
    ) {
        self.id = id
        self.title = title
        self.subjectCode = subjectCode
        self.dueDate = dueDate
        self.status = status
        self.grade = grade
        self.percentage = percentage
        self.marked = marked
    }
}

public extension Assessment {
    func listDisplayStatus() -> AssessmentDisplayStatus {
        if marked || grade != nil || percentage != nil { return .marked }
        if status?.uppercased() == "SUBMITTED" { return .submitted }
        guard let due = Self.parseListDueDate(dueDate) else { return .upcoming }
        let today = Calendar.current.startOfDay(for: Date())
        let dueDay = Calendar.current.startOfDay(for: due)
        let days = Calendar.current.dateComponents([.day], from: today, to: dueDay).day ?? 0
        if days < 0 { return .overdue }
        if days <= 7 { return .dueSoon }
        return .upcoming
    }

    private static func parseListDueDate(_ raw: String?) -> Date? {
        guard let raw, !raw.isEmpty else { return nil }
        let normalized = raw.replacingOccurrences(of: " ", with: "T").prefix(10)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: String(normalized))
    }
}

public struct MessageSummary: Sendable, Equatable, Codable {
    public let id: Int
    public let title: String
    public let subtitle: String?
    public let timestamp: String?
    public let unread: Bool
    public let starred: Bool
    public let hasAttachments: Bool

    public init(
        id: Int,
        title: String,
        subtitle: String?,
        timestamp: String?,
        unread: Bool,
        starred: Bool = false,
        hasAttachments: Bool = false
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.timestamp = timestamp
        self.unread = unread
        self.starred = starred
        self.hasAttachments = hasAttachments
    }
}

public struct MessageAttachment: Sendable, Equatable, Identifiable {
    public let id: Int
    public let filename: String
    public let mimetype: String
    public let size: String
    public let uuid: String

    public init(id: Int, filename: String, mimetype: String, size: String, uuid: String) {
        self.id = id
        self.filename = filename
        self.mimetype = mimetype
        self.size = size
        self.uuid = uuid
    }
}

public struct MessageDetail: Sendable, Equatable {
    public let id: Int
    public let htmlBody: String
    public let attachments: [MessageAttachment]
    public let read: Bool
    public let starred: Bool

    public init(
        id: Int,
        htmlBody: String,
        attachments: [MessageAttachment] = [],
        read: Bool = true,
        starred: Bool = false
    ) {
        self.id = id
        self.htmlBody = htmlBody
        self.attachments = attachments
        self.read = read
        self.starred = starred
    }
}

public enum MessageFolder: String, CaseIterable, Sendable, Identifiable {
    case inbox
    case sent
    case starred
    case trash

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .inbox: "Inbox"
        case .sent: "Sent"
        case .starred: "Starred"
        case .trash: "Trash"
        }
    }

    /// SEQTA `label` field for `action: list` requests.
    public var apiLabel: String { rawValue }
}

/// Server-side file id returned from `/seqta/student/file/upload/xhr2` for compose.
public struct MessageComposeAttachment: Sendable, Equatable, Identifiable {
    public let id: Int
    public let filename: String
    public let byteCount: Int?

    public init(id: Int, filename: String, byteCount: Int? = nil) {
        self.id = id
        self.filename = filename
        self.byteCount = byteCount
    }
}

public struct MessageRecipient: Sendable, Equatable, Hashable, Identifiable, Codable {
    public var id: Int
    public let displayName: String
    public let isStaff: Bool
    public let meta: String?

    public init(id: Int, displayName: String, isStaff: Bool, meta: String? = nil) {
        self.id = id
        self.displayName = displayName
        self.isStaff = isStaff
        self.meta = meta
    }
}

public enum AssessmentDisplayStatus: String, Sendable, Equatable, Codable {
    case upcoming = "Upcoming"
    case dueSoon = "Due soon"
    case overdue = "Overdue"
    case submitted = "Submitted"
    case marked = "Marked"
}

public struct AssessmentCriterion: Sendable, Equatable, Codable {
    public let name: String
    public let description: String?
    public let grade: String?
    public let percentage: Int?

    public init(name: String, description: String?, grade: String?, percentage: Int?) {
        self.name = name
        self.description = description
        self.grade = grade
        self.percentage = percentage
    }
}

public struct AssessmentDetail: Sendable, Equatable, Codable {
    public let id: Int
    public let title: String
    public let description: String?
    public let subjectCode: String
    public let subjectTitle: String
    public let dueDate: String?
    public let marked: Bool
    public let displayStatus: AssessmentDisplayStatus
    public let submitted: Bool
    public let overallGrade: String?
    public let overallPercentage: Int?
    public let feedbackComment: String?
    public let expectations: [String]
    public let criteria: [AssessmentCriterion]

    public init(
        id: Int,
        title: String,
        description: String?,
        subjectCode: String,
        subjectTitle: String,
        dueDate: String?,
        marked: Bool,
        displayStatus: AssessmentDisplayStatus,
        submitted: Bool,
        overallGrade: String? = nil,
        overallPercentage: Int? = nil,
        feedbackComment: String? = nil,
        expectations: [String] = [],
        criteria: [AssessmentCriterion] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.subjectCode = subjectCode
        self.subjectTitle = subjectTitle
        self.dueDate = dueDate
        self.marked = marked
        self.displayStatus = displayStatus
        self.submitted = submitted
        self.overallGrade = overallGrade
        self.overallPercentage = overallPercentage
        self.feedbackComment = feedbackComment
        self.expectations = expectations
        self.criteria = criteria
    }
}

public struct Portal: Sendable, Equatable, Codable {
    public let id: Int
    public let title: String
    public let url: String?
    public let uuid: String?
    public let isPowerPortal: Bool
    public let inheritStyles: Bool

    public init(
        id: Int,
        title: String,
        url: String?,
        uuid: String? = nil,
        isPowerPortal: Bool = false,
        inheritStyles: Bool = false
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.uuid = uuid
        self.isPowerPortal = isPowerPortal
        self.inheritStyles = inheritStyles
    }
}

public struct NoticeLabel: Sendable, Equatable, Codable {
    public let id: Int
    public let title: String
    public let colour: String?

    public init(id: Int, title: String, colour: String?) {
        self.id = id
        self.title = title
        self.colour = colour
    }
}

public struct Notice: Sendable, Equatable, Codable {
    public let title: String
    public let labelTitle: String?
    public let labelId: Int?
    public let colour: String?
    public let staff: String?
    public let contents: String

    public init(
        title: String,
        labelTitle: String?,
        labelId: Int?,
        colour: String?,
        staff: String?,
        contents: String
    ) {
        self.title = title
        self.labelTitle = labelTitle
        self.labelId = labelId
        self.colour = colour
        self.staff = staff
        self.contents = contents
    }
}
