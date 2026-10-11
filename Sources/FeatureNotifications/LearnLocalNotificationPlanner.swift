import Domain
import Foundation
import UserNotifications

/// Schedules local alerts after home data refresh (best-effort vs Android WorkManager workers).
public enum LearnLocalNotificationPlanner {
    private static let assessmentPrefix = "learn.assessment."
    private static let noticePrefix = "learn.notice."
    private static let seenNoticesKey = "learn.notifications.seenNoticeKeys"

    public static func syncAfterHomeLoad(
        assessments: [Assessment],
        notices: [Notice],
        assessmentRemindersEnabled: Bool,
        noticeAlertsEnabled: Bool
    ) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized
            || settings.authorizationStatus == .provisional
            || settings.authorizationStatus == .ephemeral else {
            return
        }

        if assessmentRemindersEnabled {
            await rescheduleAssessmentReminders(assessments: assessments)
        } else {
            await cancelAssessmentReminders()
        }

        if noticeAlertsEnabled {
            await deliverNewNoticeAlerts(notices: notices)
        }
    }

    public static func cancelAssessmentReminders() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(assessmentPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    private static func rescheduleAssessmentReminders(assessments: [Assessment]) async {
        await cancelAssessmentReminders()
        let center = UNUserNotificationCenter.current()
        let now = Date()
        let horizon = Calendar.current.date(byAdding: .day, value: 21, to: now) ?? now

        for assessment in assessments where !assessment.marked {
            guard let due = LearnAssessmentDueDate.date(from: assessment.dueDate),
                  due > now,
                  due <= horizon else {
                continue
            }
            let fireDate = reminderFireDate(before: due, now: now)
            guard fireDate > now else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Assessment due"
            content.body = "\(assessment.title) (\(assessment.subjectCode))"
            content.sound = .default
            content.categoryIdentifier = "learn.assessment.reminder"

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(assessmentPrefix)\(assessment.id)",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    private static func reminderFireDate(before due: Date, now: Date) -> Date {
        let calendar = Calendar.current
        if let dayBefore = calendar.date(byAdding: .day, value: -1, to: due),
           dayBefore > now,
           let atEight = calendar.date(
               bySettingHour: 8,
               minute: 0,
               second: 0,
               of: dayBefore
           ) {
            return atEight
        }
        return calendar.date(bySettingHour: 8, minute: 0, second: 0, of: due)
            ?? due.addingTimeInterval(-3600)
    }

    private static func deliverNewNoticeAlerts(notices: [Notice]) async {
        let center = UNUserNotificationCenter.current()
        var seen = Set(UserDefaults.standard.stringArray(forKey: seenNoticesKey) ?? [])
        var newlySeen: [String] = []

        for notice in notices {
            let key = noticeStableKey(notice)
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            newlySeen.append(key)

            let content = UNMutableNotificationContent()
            content.title = notice.labelTitle ?? "School notice"
            content.body = notice.title
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "\(noticePrefix)\(key.hashValue)",
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            )
            try? await center.add(request)
        }

        if !newlySeen.isEmpty {
            UserDefaults.standard.set(Array(seen), forKey: seenNoticesKey)
        }
    }

    private static func noticeStableKey(_ notice: Notice) -> String {
        let digest = "\(notice.title)|\(notice.labelId ?? 0)|\(notice.contents.prefix(64))"
        return String(digest.hashValue)
    }
}
