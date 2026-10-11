# SEQTA student API

Transport: **HTTP POST**, JSON body, session cookie `JSESSIONID=<value>`.

iOS implementation: `Sources/CoreNetworking/LearnSeqtaRequest.swift`, `SeqtaStudentClient.swift`.

Android reference: `core/network/.../SeqtaStudentApi.kt`, `data/student/StudentRepositoryImpl.kt`.

## Endpoints

| Operation | Path | Body notes |
|-----------|------|------------|
| Login / profile | `/seqta/student/login` | `{}` after cookie established |
| Heartbeat | `/seqta/student/heartbeat` | `{"heartbeat":true}` |
| Subjects | `/seqta/student/load/subjects` | `{}` |
| Courses | `/seqta/student/load/courses` | `{}` |
| Timetable | `/seqta/student/load/timetable` | `from`, `until`, `student` |
| Upcoming assessments | `/seqta/student/assessment/list/upcoming` | `student` |
| Past assessments | `/seqta/student/assessment/list/past` | per-subject `programme`, `metaclass`, `student` |
| Assessment detail | `/seqta/student/assessment/get` | per Android parsers |
| Submissions | `/seqta/student/assessment/submissions` | |
| Messages list | `/seqta/student/load/message` | `action: list`, `label` (inbox/sent/starred/trash), `offset`, `limit` |
| Message body | `/seqta/student/load/message` | `action: message`, `id` |
| Save message | `/seqta/student/save/message` | compose; `files: [Int]` attachment ids; `mode: x-star` to star/unstar |
| Upload message file | `/seqta/student/file/upload/xhr2` | raw body; headers `X-File-Name`, `X-Accept-Mimes`, `X-Requested-With` |
| Message attachment GET | `/seqta/student/load/file` | `type=message`, `file=<uuid>` |
| Message people | `/seqta/student/load/message/people` | |
| Portals | `/seqta/student/load/portals` | |
| Notices labels | `/seqta/student/load/notices` | `mode: labels` |
| Notices by date | `/seqta/student/load/notices` | `date` |

Base URL: school origin only (e.g. `https://coneqt-s.example.edu.au`), paths as above.

## Fixtures (committed)

| File | Source |
|------|--------|
| `Tests/Fixtures/login_response.json` | Android `data/src/test/resources/fixtures/` |
| `Tests/Fixtures/subjects_response.json` | Android `data/src/test/resources/fixtures/` |

## Live captures (gitignored)

Optional Playwright/HAR exports: `Tests/Fixtures/live/` — never commit credentials or raw cookies.

## Discrepancies

| Topic | Android | DesQTA / other | iOS decision |
|-------|---------|----------------|--------------|
| _(none logged yet)_ | | | Follow Android unless JWACS proves otherwise |
