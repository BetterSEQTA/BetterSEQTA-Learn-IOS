import Foundation

enum ShellTab: Hashable, CaseIterable {
    case home
    case timetable
    case courses
    case assessments
    case messages

    var title: String {
        switch self {
        case .home: "Home"
        case .timetable: "Timetable"
        case .courses: "Courses"
        case .assessments: "Assessments"
        case .messages: "Messages"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house"
        case .timetable: "calendar"
        case .courses: "book"
        case .assessments: "doc.text"
        case .messages: "envelope"
        }
    }
}

enum ShellOverlay: Hashable {
    case portals
    case notices
    case settings

    var title: String {
        switch self {
        case .portals: "Welcome Portals"
        case .notices: "Notices"
        case .settings: "Settings"
        }
    }
}
