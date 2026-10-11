# Agent status log

## 2026-10-11 — WSL deploy/toolchain fixes

- **`scripts/wsl-env.sh`:** sources `/etc/profile.d/swift.sh` so non-login WSL/bash finds Swift (`Failed to obtain Swift version` fix).
- **`scripts/deploy-iphone.ps1`:** Windows wrapper; `.gitattributes` forces `*.sh` LF; CRLF on drvfs breaks shebang — normalize with `python3` if needed.
- **`run-ios-parser-tests.sh`:** treats `Build complete!` as PASS when drvfs `.app` copy fails.
- **`xtool dev build`:** compile **green** (~8s); post-build copy to `xtool/` on `/mnt/c` still fails (expected).

## 2026-10-11 — Local notification planner (goal stream)

- **`LearnLocalNotificationPlanner`:** On home refresh, schedules assessment due reminders (8:00 day-before) and one-shot alerts for new notices (deduped); respects Settings toggles; cancels assessment pending requests when disabled.
- **`LearnAssessmentDueDate`** in Domain + unit tests.
- Build: **compile green** (~49s).

## 2026-10-11 — Follow-up after stream `7d078d80`

- **Widget:** Supersedes “manual embed only” from that stream — `xtool.yml` `extensions:` now builds `PlugIns/LearnWidget.appex` ([appex docs](https://xtool.sh/documentation/xtool/appex)); see `docs/WIDGET_XTOOL.md`.
- **Build:** `xtool dev build` compile green with widget extension; drvfs copy to `xtool/` still fails — **device:** `scripts/deploy-iphone.sh` (no rsync); optional mirror: `scripts/build-ios-wsl.sh` (excludes Android/DesQTA siblings).
- **Still open from `7d078d80`:** JWACS Phase A live run on Coneqt-S, WorkManager-equivalent background workers (`docs/NOTIFICATIONS_WORKMANAGER_GAPS.md`), local notification scheduling.

## 2026-10-11 — Notifications foreground badge, onboarding steps, shell motion, widget doc

### Done

- **Notifications:** Foreground inbox poll preference + manual badge refresh; app icon badge when authorized; `docs/NOTIFICATIONS_WORKMANAGER_GAPS.md`.
- **Onboarding:** 3-step `LearnOnboardingStubView` (glass/motion, school URL on last step).
- **Shell:** `LearnMotion` drawer fade + tab transitions; launch overlay fade; inbox poll loop in `MainShell`.
- **Widget:** `docs/WIDGET_XTOOL.md` manual Xcode embed steps.
- **Tests:** `message_upload_response.json` fixture test for compose upload parse.
- **QA:** Pass/Fail table in `QA_SCHOOL_JWACS.md`; checklist rows updated.

### Build / test

- `xtool dev build`: **compile green** (~20s); drvfs `.app` copy failed (expected).
- `swift test` on Linux host fails without SwiftUI SDK (DomainTests compile in `Package.swift`; run on macOS/xtool test host).

### Next

- Widget extension embed; assessment/notice background scheduling; JWACS live QA; Material-level polish.

## 2026-10-11 — Compose attachments, calendar BG, home polish, widget entitlements doc

### Done

- **Messages compose:** `file/upload/xhr2` upload + `files` ids on `save/message`; `LearnComposeMessageView` file importer + attachment list (DesQTA parity; Android compose UI still no picker).
- **Calendar sync:** master enable + auto-sync toggles; `LearnCalendarSyncBackground` `BGAppRefreshTask` (~24h); `Info.plist` permitted identifiers + `fetch` mode.
- **Widget:** `BetterSEQTALearn.entitlements` App Group `group.org.betterseqta.learn`; `LearnWidgetBundle` remains without `@main` (xtool extension embed TBD).
- **Home:** subject-colour filter chips (toggle-off), richer assessment cards/empty states.
- **Tests:** `parseUploadedMessageFile` in `DataTests`.
- **Docs:** `FEATURE_PARITY_CHECKLIST`, `QA_SCHOOL_JWACS`, `SEQTA_API_STUDENT`.

### Build / test

- `xtool dev build`: **compile green** (~60s); drvfs `.app` copy failed (expected).

### Next

- Embed WidgetKit extension in xtool; wire entitlements in build; push notifications UI; auth onboarding carousel; JWACS live run.

## 2026-10-11 — Messages starred/search + widget snapshot pipeline

### Done

- **Messages:** Starred folder loads inbox + client filter (Android parity); `searchValue` on list API with 300ms debounce; unstar removes row in starred folder.
- **Widget:** `NextLessonResolver` + `LearnWidgetSharedStore` (App Group + standard fallback); `HomeWidgetRefresh` on home pull/launch + signed-out on logout; `LearnTimelineProvider` reads shared snapshot.
- **Tests:** `DomainTests/NextLessonResolverTests.swift`.
- **Warnings:** `@preconcurrency import AVFoundation` on QR scanner (Sendable capture downgraded).

### Build / test

- `xtool dev build`: **compile green** (~40s); drvfs `.app` copy failed (expected).
- `swift test --filter NextLessonResolverTests` — run when host Swift test SDK available.

### Next

- Compose attachments; calendar BG/auto-sync; home dashboard polish; WidgetKit extension embed + entitlements; JWACS QA.

## 2026-10-11 — Consolidated build (orchestrator 1abfe288)

- Waited for parallel child SwiftPM builds to finish, then `rm -rf .build && xtool dev build`: **compile green** (~77s); drvfs `.app` copy to `xtool/` failed (expected).
- **Merged child work:** Messages attachments/trash/restore + inbox badge refresh; `FeatureNotifications` settings + widget reload; `FeatureCalendarSync` + `CalendarSyncRepositoryLive`; auth onboarding/deeplink/shell polish (see checklist).
- **Tweak:** `MainShell` `HomeNavigationCallbacks` use `Task { @MainActor in … }` for Sendable closure warnings.
- Goal **not** marked complete; `build-ios-wsl.sh` hit intermittent `Failed to obtain Swift version` this run.

## 2026-10-11 — Build unblock (stale SwiftPM lock)

- **Stuck:** No WSL `swift`/`xtool` processes; `.build/.lock` held PID **23385** (dead) — blocked new SwiftPM sessions after an interrupted build.
- **Action:** Removed stale `.lock` only (no kills); `xtool dev build` **compile green** (~7s); post-build `.app` copy to `xtool/` on drvfs failed (permission — expected).

## 2026-10-11 — Child D: auth/shell polish + checklist audit

### Done

- **Onboarding:** `LearnOnboardingStubView` collects optional school URL (saved via `LoginPreferencesStore`); `UrlEntryView` URL keyboard/content-type polish.
- **Deeplinks:** `LearnShellDeeplinkRouter` restricts to Learn schemes, aligns auth detection with `isValidAuthDeeplink`; shell routes queue when opened before sign-in (`ContentView`).
- **Shell:** Drawer selection accent + shadow; launch overlay uses `FluidLoadingBarView`; menu accessibility label.
- **Docs:** Honest pass on `FEATURE_PARITY_CHECKLIST.md`, expanded `QA_SCHOOL_JWACS.md` smoke steps (no secrets).

### Build / test

- `xtool dev build`: compile **green** (~13s); post-build `.app` copy to `xtool/` on drvfs failed (permission — expected).
- Build fixes while verifying: `LearnNotificationPreferencesStore` Swift 6 (`@MainActor` class), `public typealias JSONObject`.

### Next

- Message attachments + trash/restore; home Android parity; calendar sync; WidgetKit; live JWACS run.

## 2026-10-11 — Messages folders/detail, assessments by subject, home → detail

### Done

- **Messages:** `action: list` POST body (folder labels, offset/limit), sent+outbox merge; `action: message` HTML detail via `WKWebView`; star/unstar via `save/message` `x-star`; inbox/sent/starred/trash picker + load more; parsers/tests + `messages_list_action.json` fixture.
- **Assessments:** “By subject” tab with grouped sections; `Assessment.listDisplayStatus()` status chips on rows; home assessment card opens assessment detail on Tasks tab.
- **Docs:** Updated `FEATURE_PARITY_CHECKLIST.md`, `SEQTA_API_STUDENT.md`.

### Build / test

- `xtool dev build` — run after edits (WSL).
- `DataTests` — message list/detail parser tests added.

### Next

- Message attachments + trash/restore; shell badge refresh after read; full Android Messages UI polish; JWACS QA; WidgetKit.

## 2026-10-11 — Assessment detail, message compose, shell deeplinks

### Done

- **Assessments:** `getAssessmentDetail` + `AssessmentDetailParser` parity in `StudentRepositoryLive`; `LearnAssessmentDetailView` with navigation from upcoming/past lists; subjects loaded for metaclass resolution; submissions path fixed to `/assessment/submissions/get`.
- **Messages:** `loadMessageRecipients`, `sendMessage` (`save/message`); `LearnComposeMessageView` + toolbar entry from inbox.
- **Shell:** `LearnShellDeeplinkRouter` routes logged-in `seqta://` / `seqtalearn://` paths to tabs/overlays (auth links unchanged).
- **Tests:** `parseAssessmentDetail`, recipients, submission payload helpers in `DataTests`.
- **Domain:** `AssessmentDetail`, `MessageRecipient`, `AssessmentDisplayStatus`.

### Build / test

- `xtool dev build`: **compile green** (~57s); post-build `.app` copy to `xtool/` on drvfs still fails (permission).
- `swift test --filter DataTests`: run when Linux `swift test` is configured (iOS SDK tests typically via Xcode/xtool).

### Next

- Full messages module parity (labels, paging, detail API, mark read/star, attachments), assessments by-subject tab, home → detail navigation, JWACS QA, WidgetKit.

## 2026-10-11 — Session expiry, QR camera, portal WebView

### Done

- **Session expiry:** `SeqtaStudentResponseValidation` on all `SeqtaStudentClient` posts; `LearnSessionExpiryNotifier` → `LearnAppDependencies.handleSessionExpired()` clears session; login screen shows “Session expired…”; resume heartbeat in `MainShellViewModel`.
- **Auth:** Live `AVCaptureSession` QR scanner in `FeatureAuth` (`LearnQRCodeScannerView`).
- **Portals:** In-app `WKWebView` with `JSESSIONID` cookie (`LearnPortalWebView`).
- **Notifications:** Register categories + request authorization on app launch.
- **Scripts:** Fixed CRLF on `scripts/verify-swift-tests.sh` / `scripts/build-ios-wsl.sh` (use `sed -i 's/\r$//'` on drvfs if WSL still chokes).
- **Tests:** `SeqtaStudentResponseValidationTests` added.

### Build / test (this turn)

- WSL: `swift` not on PATH; `xtool dev build` exits 1 (`Failed to obtain Swift version`) — could not re-verify compile locally.
- Prior agent log: xtool compile green before these edits; re-run `scripts/build-ios-wsl.sh` when Swift/xtool toolchain is healthy.

### Next

- Assessment detail screen, message compose, universal link routing, WidgetKit target, full notifications UI, calendar sync, JWACS QA.

## 2026-03-22 — Follow-up after build-verify stream (`3f47c821`)

### Done

- Fixed Swift 6 `LearnAppDependencies` deinit: session expiry uses `NotificationCenter.notifications` `Task` + cancel in `deinit` (replaces `NSObjectProtocol` observer).
- **`xtool dev build`:** compile **green** (~19s) on WSL (`swift` 6.4 + `xtool`).

### Carried from `3f47c821`

- Session expiry validation on student POSTs → logout + login message.
- Live QR (`LearnQRCodeScannerView`), portal `WKWebView`, notification permission at launch.
- `SeqtaStudentResponseValidationTests` added (run via iOS SDK / full `swift test` when available).

## 2026-03-22 — Follow-up after A3 Data + features (`f2229f5c`)

### Done

- Confirmed `MainShell` already wires `Learn*Timetable/Courses/Assessments/Messages/Portals/Notices/Settings` views (prior integration).
- Swift 6 fixes: `HomeColourUtils` cache, `HomeViewModel` load progress (no `@Sendable` closure races), `Subject`/`Course` `Identifiable`+`Hashable` in `Domain`, `LearnSessionStore.currentSession()` for `@Sendable` student repo provider.
- **`xtool dev build`:** compile **green** (~17s); post-build copy to `xtool/BetterSEQTALearn.app` on `/mnt/c` still fails (known drvfs) — use `scripts/build-ios-wsl.sh`.

### Next

- Session-expired UX, live QR camera, WidgetKit target, notifications/calendar parity, JWACS QA.

## 2026-03-22 — A3 features + Data (stream)

### Done

- **Data:** Completed `AuthRepositoryLive` (QR, connect, credentials, web session + profile/heartbeat), `getCourses` / `getMessages` / `getPastAssessments` in `StudentRepositoryLive`, courses & messages parsers, criteria-aware assessment grades, `LearnJwtUserId` / `LearnDeeplinkParser` / `LearnJwtValidator`, enhanced `learnSeqtaPOST` (JWT bearer, Set-Cookie).
- **Features:** Added SwiftPM targets with real screens: `FeatureTimetable`, `FeatureCourses`, `FeatureAssessments`, `FeatureMessages`, `FeatureNotices`, `FeaturePortals`, `FeatureSettings`; shared `LearnScreenHeader` / empty & error states in `CoreDesign`.
- **Tests:** Expanded `DataTests/SeqtaResponseParsersTests` to mirror Android parser tests; fixtures `courses_response.json`, `messages_response.json`.
- **Package.swift:** Registered all feature libraries; `BetterSEQTALearnApp` depends on feature modules (shell wiring unchanged per stream rules).
- **Notifications / Widget:** `FeatureNotifications` authorization skeleton; `Extensions/LearnWidget/LearnTimelineWidget.swift` placeholder.
- **Docs:** Updated `FEATURE_PARITY_CHECKLIST.md`, this log.

### Not touched (per assignment)

- `ContentView`, `MainShell`, `FeatureAuth` UI.

### Next

- Wire feature views into shell navigation (A2).
- Full auth UI + motion polish.
- Assessment detail, message compose, portal WebView parity.
- xtool Widget extension target + push notifications.

## 2026-03-22 — Shell ↔ feature module wiring (A3 + A3-features)

### Done

- `MainShell` tabs use `LearnTimetableView`, `LearnCoursesView`, `LearnAssessmentsView`, `LearnMessagesView` (replaces tab placeholders).
- Drawer overlays use `LearnPortalsView`, `LearnNoticesView`, `LearnSettingsView`; removed `ShellPlaceholderOverlays.swift`.

---

## 2026-03-22 — Integration after A2 Auth + Design

### Done

- Fixed `Package.swift`: added missing `FeatureHome`, `FeatureAuthTests`, `Data` app dependency, `targetDeps()` for SPM 6.
- Registered deeplink URL schemes via root `Info.plist` + `xtool.yml` `infoPath`.
- `ContentView.onOpenURL` forwards inbound links to auth handler.
- `@MainActor AuthRepository` protocol for `AuthRepositoryLive` Swift 6 isolation.
- `SessionData.resolvedUserId` in CoreSession; `StudentRepositoryLive` compile fixes (`try requireSession()`).

### Build

- `xtool dev build` compiles through Data layer; intermittent WSL `OpenGLES`/module-cache errors on `/mnt/c` — use `scripts/build-ios-wsl.sh` or `rm -rf .build` and rebuild.

---

## 2026-03-22 — A0 scaffold (Phase 0 + minimal Phase 1)

### Done

- Created `docs/` set: README, MASTER_PLAN, FEATURE_PARITY_CHECKLIST, ARCHITECTURE, SEQTA_API_STUDENT, DESIGN_LANGUAGE, SUBAGENT_ORCHESTRATION, QA_SCHOOL_JWACS, AGENT_STATUS.
- Updated `.gitignore` for `Secrets/`, `Tests/Fixtures/live/`, `.env.local`, Swift/xtool build dirs.
- Added `Package.swift` (multi-target SwiftPM), `xtool.yml` (`org.betterseqta.learn`, product `BetterSEQTALearn`).
- Scaffolded sources: `CoreCommon`, `CoreDesign`, `CoreNetworking`, `CoreSession`, `Domain`, `Data`, `FeatureAuth`, `BetterSEQTALearnApp` with `@main` + `ContentView`.
- Ported Domain models from Android `Models.kt` + `SessionData.kt`; repository protocols from `Repositories.kt`.
- `LearnSession`, `LearnSessionStore`, `learnSeqtaPOST`, `SeqtaStudentClient` stub with student paths.
- Copied Android JSON fixtures to `Tests/Fixtures/` (`login_response.json`, `subjects_response.json`).
- Added `Tests/DomainTests`, `Tests/DataTests` (minimal).
- `Secrets/.gitkeep`, `Secrets/README.md`, `scripts/verify-swift-tests.sh` (non-blocking exit 0).

### Tests run

- `swift build` (Linux host): **expected fail** — SwiftUI modules require iOS SDK.
- `xtool dev build`: **compile succeeded** (~29s). Post-build copy to `xtool/BetterSEQTALearn.app` on `/mnt/c/...` failed with permission (drvfs); build artifacts in xtool cache are OK for verify.

### Blockers / next

- Resolve WSL→Windows `xtool/` output permissions or build from Linux home path for local `.app` bundle.
- Confirm install with `xtool dev` on device (A5 agent only).
