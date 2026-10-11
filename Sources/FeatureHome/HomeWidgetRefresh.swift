import Domain
import Foundation
import WidgetKit

public enum HomeWidgetRefresh {
    public static func publish(lessons: [TimetableLesson], now: Date = .now) {
        let snapshot = NextLessonResolver.resolve(lessons: lessons, now: now)
        LearnWidgetSharedStore.save(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }

    public static func publishSignedOut() {
        LearnWidgetSharedStore.save(.signedOut)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
