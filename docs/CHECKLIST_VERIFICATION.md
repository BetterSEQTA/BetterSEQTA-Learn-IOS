# Checklist verification log

Evidence for [FEATURE_PARITY_CHECKLIST.md](FEATURE_PARITY_CHECKLIST.md). Update when rows change.

| Row | Status | Evidence |
|-----|--------|----------|
| Connect / SSO deeplinks | [x] | `AuthRepositoryLive.loginWithQr/Connect`, `ContentView.handleDeeplink` |
| Credential login | [x] | `AuthRepositoryLive.loginWithCredentials` |
| Heartbeat + session expiry | [x] | `SeqtaStudentResponseValidation`, `LearnSessionExpiryNotifier` |
| Bottom nav + overlays | [x] | `MainShell.swift` |
| Timetable / Courses / Notices / Settings | [x] | `Feature*` views wired in shell |
| Data parsers + tests | [x] | `Tests/DataTests`, `Tests/Fixtures` |
| SeqtaStudentApi wiring | [x] | `StudentRepositoryLive`, `SeqtaStudentClient` |
| App deeplink routing | [x] | `LearnShellDeeplinkRouter` |
| Widget extension build | [~] | `xtool.yml` `extensions:` → `PlugIns/LearnWidget.appex`; device QA open |
| JWACS Coneqt-S | [ ] | `QA_SCHOOL_JWACS.md` Phase A — **no recorded pass/fail** |
| WorkManager notifications | [~] | `NOTIFICATIONS_WORKMANAGER_GAPS.md` |

**Build gate:** `xtool dev build` compile success (WSL). **Not done:** all `[~]` rows, live JWACS, `xtool dev` install smoke on device.
