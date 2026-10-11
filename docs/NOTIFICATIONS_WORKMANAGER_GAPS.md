# Notifications — iOS vs Android WorkManager

Android schedules periodic work after login (`AppBackgroundSyncScheduler`):

| Worker | Interval | iOS parity |
|--------|----------|------------|
| `NotificationDispatchWorker` | 30 min | **Partial** — `LearnLocalNotificationPlanner` schedules assessment reminders on home refresh (not 30 min BG) |
| `AssessmentRefreshWorker` | 12 h | **Partial** — `LearnHomeBackgroundRefresh` (~2h BG) refreshes home + planner |
| `NoticePollWorker` | 2 h | **Partial** — new notices on home refresh fire one-shot local alerts (deduped); no 2 h BG poll |
| `NextLessonWidgetWorker` | 45 min | Partial — `HomeWidgetRefresh` on home load; `LearnWidget.appex` via xtool `extensions:` (no 45 min BG worker) |
| `TimetableCalendarSyncWorker` | 24 h | Partial — `BGAppRefreshTask` (~24 h, best-effort) |

## What iOS implements today

- Permission request + category registration (`LearnNotificationsCoordinator`)
- Assessment / notice toggles in Settings (`LearnNotificationPreferencesStore`)
- **Foreground** unread inbox count: resume + `LearnInboxDidChangeNotifier` + optional poll while app is active (`LearnInboxPollPreferencesStore`)
- App icon badge from unread inbox count when authorized (`MainShellViewModel`)
- Manual **Refresh message badge** in Notifications settings
- **Assessment reminders** + **notice alerts** via `LearnLocalNotificationPlanner` when home data refreshes (Settings toggles)

## What remains for true 1:1

- Room-backed persistence + replanning independent of home refresh
- Background workers equivalent to 30 min / 2 h periodic fetch (BGAppRefresh / push)
- Notification channels UI parity (Android system channels vs iOS single permission)
