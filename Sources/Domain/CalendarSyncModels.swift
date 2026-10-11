import Foundation

public enum CalendarSyncAuthorizationStatus: String, Sendable, Equatable {
    case notDetermined
    case denied
    case authorized
    case restricted
}

public struct CalendarSyncPreferences: Sendable, Equatable, Codable {
    public var isEnabled: Bool
    /// Mirrors Android `calendarSyncEnabled` + periodic WorkManager (iOS: BGAppRefresh ~24h when allowed).
    public var autoSyncEnabled: Bool
    public var syncTimetable: Bool
    public var syncAssessments: Bool
    public var selectedCalendarIdentifier: String?
    public var lastSyncedAt: Date?
    public var lastSyncSummary: String?

    public init(
        isEnabled: Bool = false,
        autoSyncEnabled: Bool = false,
        syncTimetable: Bool = true,
        syncAssessments: Bool = true,
        selectedCalendarIdentifier: String? = nil,
        lastSyncedAt: Date? = nil,
        lastSyncSummary: String? = nil
    ) {
        self.isEnabled = isEnabled
        self.autoSyncEnabled = autoSyncEnabled
        self.syncTimetable = syncTimetable
        self.syncAssessments = syncAssessments
        self.selectedCalendarIdentifier = selectedCalendarIdentifier
        self.lastSyncedAt = lastSyncedAt
        self.lastSyncSummary = lastSyncSummary
    }
}

public struct CalendarSyncCalendarOption: Sendable, Equatable, Identifiable {
    public let id: String
    public let title: String

    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

public struct CalendarSyncSummary: Sendable, Equatable {
    public let timetableEvents: Int
    public let assessmentEvents: Int

    public init(timetableEvents: Int, assessmentEvents: Int) {
        self.timetableEvents = timetableEvents
        self.assessmentEvents = assessmentEvents
    }

    public var displayText: String {
        "Synced \(timetableEvents) lessons and \(assessmentEvents) assessments."
    }
}
