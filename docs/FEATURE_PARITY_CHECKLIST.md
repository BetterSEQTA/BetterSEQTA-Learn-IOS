# Feature parity checklist

Mark each item when iOS matches Android behavior. Android paths are under `BetterSEQTA-Learn-Android/` (reference; not cloned in all dev environments).

## Auth (`FeatureAuth`)

- [~] Onboarding — 2-step welcome (`LearnOnboardingStubView`); school URL only on sign-in (`LearnLoginView` → `learn.rememberedSchoolUrl`)
- [x] QR login — `LearnQRCodeScannerView` (live camera) + paste fallback (`QRScannerEntryView`)
- [x] Connect / SSO deeplinks — `AuthRepositoryLive` + `ContentView.handleDeeplink` (QR vs connect by prefix)
- [x] WebView session cookie import — `LoginWebView` + `WebSessionCookieParser` → session save
- [x] Credential login — username/password against saved base URL
- [x] Heartbeat + session expiry → re-login (`SeqtaStudentResponseValidation`, `LearnSessionExpiryNotifier`, resume heartbeat in shell)

**Data layer (iOS):** `AuthRepositoryLive` implements QR, connect, credentials, web session, heartbeat (UI in `FeatureAuth`).

## Shell

- [~] Launch loading overlay until home ready — `AppLaunchLoadingOverlay` + `HomeLaunchGate` (`LearnMotion` fade; early ready after first home batch)
- [~] Modal drawer: Portals, Notices, Settings, Logout — `MainShell` side drawer + scrim (`LearnMotion.spatialStandardDefault`); width polish ongoing
- [x] Bottom nav: Home, Timetable, Courses, Tasks, Messages (badge)
- [x] Full-screen overlay routes for drawer destinations (top bar back, bottom bar hidden)

## Features

| Feature | Android module | iOS target | Done |
|---------|----------------|------------|------|
| Home | `feature/home` | `FeatureHome` | [~] sections + day picker + global subject filter (lessons + assessments) + profile greeting; Android motion polish ongoing |
| Timetable | `feature/timetable` | `FeatureTimetable` | [x] list + day picker (basic) |
| Courses | `feature/courses` | `FeatureCourses` | [x] subjects + course modules (basic) |
| Assessments | `feature/assessments` | `FeatureAssessments` | [x] list + by-subject tab + detail + status chips; home row → detail |
| Messages | `feature/messages` | `FeatureMessages` | [~] folders + list/load-more + HTML detail + star + compose + detail attachments + trash/restore/delete + shell unread refresh + starred inbox filter + server `searchValue` debounce + compose file picker/upload (`file/upload/xhr2` → `files` on send); Android compose UI still has no attachment picker |
| Notices | `feature/notices` | `FeatureNotices` | [x] date + labels (basic) |
| Portals | `feature/portals` | `FeaturePortals` | [x] grid + in-app WebView (`LearnPortalWebView`) with session cookie |
| Settings | `feature/settings` | `FeatureSettings` | [x] account + logout (basic) |
| Notifications | `feature/notifications` | `FeatureNotifications` | [~] permission + toggles + inbox badge poll + `LearnLocalNotificationPlanner` + `LearnHomeBackgroundRefresh` (~2h BG); not Room/WorkManager parity (see `docs/NOTIFICATIONS_WORKMANAGER_GAPS.md`) |
| Widget | `feature/widget` | WidgetKit extension | [~] xtool `extensions:` embeds `PlugIns/LearnWidget.appex`; `@main` `LearnWidgetBundle`; shared snapshot — see [WIDGET_XTOOL.md](WIDGET_XTOOL.md) |
| Calendar sync | `feature/calendar-sync` | `FeatureCalendarSync` + Settings entry | [~] on-demand sync + enable/auto toggles + `BGAppRefreshTask` (~24h, best-effort vs Android WorkManager) |

## Data / API

- [x] Core `SeqtaStudentClient` paths + `StudentRepositoryLive` / `AuthRepositoryLive`
- [x] Courses + messages parsers; past assessments batching (per-subject)
- [x] Parser tests aligned with Android `SeqtaResponseParsersTest` (+ fixtures)
- [x] `SeqtaStudentApi` endpoints — student paths used by features wired in `StudentRepositoryLive` / `AuthRepositoryLive` (messages, assessments, calendar, uploads); mark-read implicit on detail load

## Deep links

- [x] Data: `LearnDeeplinkParser` for `seqtalearn://`, `seqta://`, `betterseqtalearn://connect/`, `desqta://connect/`
- [x] App routing — auth deeplinks + logged-in tab/overlay routes (`LearnShellDeeplinkRouter`; queued when opened before sign-in)
