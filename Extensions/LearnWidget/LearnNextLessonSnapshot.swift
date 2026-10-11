import Domain
import Foundation

public typealias LearnNextLessonSnapshot = NextLessonWidgetSnapshot

public extension NextLessonWidgetSnapshot {
    static let placeholder = NextLessonWidgetSnapshot(
        kind: .lesson,
        subjectName: "English",
        timeLabel: "9:00 AM",
        room: "B12"
    )
}
