import Foundation

/// SQLite / disk partition: one namespace per SEQTA school + signed-in student account.
public enum StudentCacheScope: Sendable {
    /// Builds a stable scope so cache never leaks across schools or accounts on the same device.
    public static func storageScope(for session: SessionData) -> String {
        let school = normalizedSchoolKey(baseUrl: session.baseUrl)
        let account: String
        if let userId = session.userId {
            account = "uid:\(userId)"
        } else if let username = session.storedUsername?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !username.isEmpty {
            account = "user:\(username.lowercased())"
        } else {
            account = "session:\(session.jsessionId.hashValue)"
        }
        return "\(school)|\(account)"
    }

    /// Host-based school id (ignores scheme/trailing slash so the same school does not get duplicate caches).
    public static func normalizedSchoolKey(baseUrl: String) -> String {
        var trimmed = baseUrl.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        while trimmed.hasSuffix("/") {
            trimmed.removeLast()
        }
        if let url = URL(string: trimmed), let host = url.host, !host.isEmpty {
            var key = host
            if let port = url.port, port != 80, port != 443 {
                key += ":\(port)"
            }
            return key
        }
        return trimmed
            .replacingOccurrences(of: "://", with: "_")
            .replacingOccurrences(of: "/", with: "_")
    }
}

/// Stable cache bucket ids for persisted student data (local database).
public enum StudentCacheKey: Sendable, Hashable {
    case profile
    case subjects
    case courses
    case courseThemes
    case courseContent(programme: Int, metaclass: Int)
    case timetable(from: String?, until: String?)
    case assessmentsUpcoming
    case assessmentsPast
    case assessmentDetail(assessmentId: Int)
    case noticeLabels
    case notices(date: String)
    case portals
    case messages(folder: String, search: String, offset: Int)
    case messageDetail(id: Int)

    public var storageKey: String {
        switch self {
        case .profile:
            return "profile"
        case .subjects:
            return "subjects"
        case .courses:
            return "courses"
        case .courseThemes:
            return "courseThemes"
        case let .courseContent(programme, metaclass):
            return "courseContent.\(programme).\(metaclass)"
        case let .timetable(from, until):
            return "timetable.\(from ?? "_").\(until ?? "_")"
        case .assessmentsUpcoming:
            return "assessments.upcoming"
        case .assessmentsPast:
            return "assessments.past"
        case let .assessmentDetail(assessmentId):
            return "assessments.detail.\(assessmentId)"
        case .noticeLabels:
            return "notices.labels"
        case let .notices(date):
            return "notices.day.\(date)"
        case .portals:
            return "portals"
        case let .messages(folder, search, offset):
            return "messages.\(folder).\(search.hashValue).\(offset)"
        case let .messageDetail(id):
            return "messages.detail.\(id)"
        }
    }
}

public extension Notification.Name {
    /// Posted when background refresh writes new data. `userInfo["key"]` is `StudentCacheKey.storageKey`.
    static let studentDataCacheDidUpdate = Notification.Name("studentDataCacheDidUpdate")
}

public extension StudentRepository {
    func cachedValue<T: Decodable & Sendable>(_ storageKey: String) async -> T? {
        guard let data = await readCachedJSON(storageKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}

@MainActor
public enum StudentCacheUpdateListener {
    /// Listens for background cache writes; `prefixes` match `StudentCacheKey.storageKey` (exact or prefix).
    public static func start(
        prefixes: [String],
        onUpdate: @escaping () async -> Void
    ) -> Task<Void, Never> {
        Task {
            for await notification in NotificationCenter.default.notifications(
                named: .studentDataCacheDidUpdate
            ) {
                guard let key = notification.userInfo?["key"] as? String else { continue }
                guard prefixes.contains(where: { key == $0 || key.hasPrefix($0) }) else { continue }
                await onUpdate()
            }
        }
    }
}
