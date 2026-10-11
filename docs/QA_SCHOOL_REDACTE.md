# Manual QA — REACTED (Coneqt-S)

**School host (env only):** set `SEQTA_TEST_BASE_URL` to your school origin (example: `REDACTED`). Do not commit credentials or session tokens.

## Prerequisites

- Device or simulator with app installed via `xtool dev`
- Credentials in gitignored `Secrets/SeqtaTestCredentials.plist` **or** environment variables:
  - `SEQTA_TEST_USERNAME`
  - `SEQTA_TEST_PASSWORD`
- Network access to school SEQTA

## Phase A — Receive only (Coneqt-S)

Run this first against `REDACTED` (or `SEQTA_TEST_BASE_URL`). **No compose, no calendar writes, no file uploads** — only inbound auth and read APIs.


| #   | Step                                                                                                                                                                           | Pass / Fail | Notes |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------- | ----- |
| A1  | **Connect deeplink (receive)** — paste `desqta://connect/…` or `betterseqtalearn://connect/…` from a trusted QR; app parses `u` + `s` and lands in shell (one heartbeat only). |             |       |
| A2  | **Web login (receive session)** — school WebView; `JSESSIONID` imported; home loads.                                                                                           |             |       |
| A3  | **Home / timetable / courses / tasks** — lists and detail screens load (pull-to-refresh OK).                                                                                   |             |       |
| A4  | **Messages read** — inbox + open thread + open attachment download (do not send).                                                                                              |             |       |
| A5  | **Notices / portals read** — notice body; portal WebView loads.                                                                                                                |             |       |
| A6  | **Widget read** — after home refresh, widget shows next lesson from shared snapshot (`xtool` appex — see [WIDGET_XTOOL.md](WIDGET_XTOOL.md)).                                  |             |       |
| A7  | **Local alerts (receive)** — with notifications allowed + toggles on, home refresh schedules assessment reminders / new-notice alerts (no compose).                            |             |       |




## Phase B — Send / write (optional)

Compose, calendar sync, and other mutating flows — run only after Phase A passes.

## Full smoke script

Record **Pass** / **Fail** / **Skip** and short notes (no secrets).


| #   | Step                                                                                                                                                | Pass / Fail | Notes |
| --- | --------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- | ----- |
| 1   | **Cold launch** — app opens to welcome onboarding (first run) or sign-in; no crash.                                                                 |             |       |
| 2   | **School URL** — on onboarding or **Sign in** / **School web** tab, enter host from `SEQTA_TEST_BASE_URL`; relaunch sign-in — URL pre-fills.        |             |       |
| 3   | **Web login** — **School web** → **Open school login** → complete school login in WebView → main shell with launch overlay, then home.              |             |       |
| 4   | **Credential login** (optional) — **Sign in** tab with test username/password if school allows API login.                                           |             |       |
| 5   | **QR / connect** (optional) — paste valid `seqtalearn://sso/…` or `desqta://connect/…`; invalid links show clear error.                             |             |       |
| 6   | **Launch gate** — after login, “Preparing your dashboard…” until home data; overlay fades out.                                                      |             |       |
| 7   | **Drawer** — hamburger opens side menu; **Welcome Portals**, **Notices**, **Settings**, **Log out**; scrim tap closes.                              |             |       |
| 8   | **Logout** — confirm dialog clears session and returns to sign-in.                                                                                  |             |       |
| 9   | **Home** — profile name and today’s lessons or empty states (no infinite spinner).                                                                  |             |       |
| 10  | **Timetable** — change day; lessons or empty state.                                                                                                 |             |       |
| 11  | **Courses** — subject list loads.                                                                                                                   |             |       |
| 12  | **Tasks** — upcoming list; open detail; **By subject** tab groups items.                                                                            |             |       |
| 13  | **Messages** — inbox loads; open thread (HTML); star/unstar; attachment download/open; compose sends (if allowed).                                  |             |       |
| 14  | **Messages compose attachments** — **Add files** → pick PDF/image → **Send** → sent folder shows message.                                           |             |       |
| 15  | **Messages search / starred** — search debounces (~300ms); **Starred** folder filters inbox.                                                        |             |       |
| 16  | **Notices** — date/labels; body renders.                                                                                                            |             |       |
| 17  | **Portals** — grid opens; portal WebView loads signed-in content.                                                                                   |             |       |
| 18  | **Settings** — account host; **Calendar sync** sheet; logout works.                                                                                 |             |       |
| 19  | **Calendar sync** — allow calendars → enable sync → **Sync now** → iOS Calendar events; optional **Sync automatically**.                            |             |       |
| 20  | **Widget data** — home loads → widget or in-app lessons match `NextLessonResolver`; sign out → sign-in required snapshot (when extension embedded). |             |       |
| 21  | **Heartbeat** — background 1–2 min, resume; still signed in (or re-login if session invalidated).                                                   |             |       |
| 22  | **Shell deeplink** — `seqtalearn://messages` or `seqtalearn://settings` while signed in → correct tab/overlay.                                      |             |       |
| 23  | **Notifications settings** — toggles persist; **Refresh message badge now** updates tab badge; inbox poll interval while app open (optional).       |             |       |




### Auth & shell (detail)

1. **Cold launch** — app opens to welcome onboarding (first run) or sign-in; no crash.
2. **School URL** — on onboarding or **Sign in** / **School web** tab, enter host from `SEQTA_TEST_BASE_URL` (with or without `https://`); trailing slashes are trimmed. Relaunch sign-in screen — URL should pre-fill.
3. **Web login** — **School web** → **Open school login** → complete school login in embedded WebView → lands in main shell with launch overlay, then home.
4. **Credential login** (optional) — **Sign in** tab with test username/password if your school allows API login.
5. **QR / connect** (optional) — paste a valid `seqtalearn://sso/…` or `desqta://connect/…` link from a trusted QR; invalid links show a clear error (no crash).
6. **Launch gate** — after login, full-screen “Preparing your dashboard…” until home data appears (overlay fades out).
7. **Drawer** — hamburger opens side menu; **Welcome Portals**, **Notices**, **Settings**, **Log out** work; scrim tap closes drawer.
8. **Logout** — confirm dialog clears session and returns to sign-in.



### Features

1. **Home** — profile name and today’s lessons or empty states (no infinite spinner).
2. **Timetable** — change day; lessons or empty state.
3. **Courses** — subject list loads.
4. **Tasks** — upcoming list; open detail from row; **By subject** tab groups items.
5. **Messages** — inbox loads; open thread (HTML body); star/unstar; download/open attachment; compose sends (if school allows).
6. **Messages compose attachments** — New message → **Add files** → pick a small PDF/image → file appears in list → **Send** → sent folder shows message (school may enforce size limits).
7. **Messages search / starred** — search debounces (~300ms); **Starred** folder shows only starred inbox items; unstar removes row in starred view.
8. **Notices** — date/labels; body renders.
9. **Portals** — grid opens; portal WebView loads signed-in content.
10. **Settings** — shows account host; **Calendar sync** opens sheet; logout works.
11. **Calendar sync** — allow calendars → enable **Timetable calendar sync** → **Sync now** → check iOS Calendar for BetterSEQTA events; optional **Sync automatically** (requires Background App Refresh in iOS Settings).
12. **Widget data** — after login, home loads → add Widget (when extension installed) or verify in-app home lessons match `NextLessonResolver` expectation; sign out → widget snapshot shows sign-in required (once extension embedded + App Group provisioned).



### Session & deeplinks (logged in)

1. **Heartbeat** — background app 1–2 minutes, resume; still signed in (or clear re-login message if school invalidated session).
2. **Shell deeplink** — with Safari or Notes, open `seqtalearn://messages` (or `seqtalearn://settings`) while app is running signed in → correct tab or overlay.



## Regression notes

Record anomalies in GitHub issues with date, iOS version, and screen. Attach redacted screenshots only.

## Security

Rotate passwords if exposed. Never paste live passwords or `JSESSIONID` values into `docs/` or chat logs stored in the repo.