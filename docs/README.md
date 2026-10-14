# BetterSEQTA Learn iOS — documentation

Tracking and architecture docs for the Swift/SwiftUI port of [BetterSEQTA Learn Android](../BetterSEQTA-Learn-Android/).

## Index

| Document | Description |
|----------|-------------|
| [MASTER_PLAN.md](MASTER_PLAN.md) | Phases, milestones, link to Cursor plan |
| [FEATURE_PARITY_CHECKLIST.md](FEATURE_PARITY_CHECKLIST.md) | Screen/API parity vs Android |
| [CHECKLIST_VERIFICATION.md](CHECKLIST_VERIFICATION.md) | Evidence log for checklist rows |
| [ARCHITECTURE.md](ARCHITECTURE.md) | SwiftPM layers and navigation |
| [SEQTA_API_STUDENT.md](SEQTA_API_STUDENT.md) | Student HTTP contract + fixtures |
| [DESIGN_LANGUAGE.md](DESIGN_LANGUAGE.md) | Glass, motion, components |
| [SUBAGENT_ORCHESTRATION.md](SUBAGENT_ORCHESTRATION.md) | Parallel agent rules |
| [QA_SCHOOL_REDACTED.md](QA_SCHOOL_REDACTED.md) | Manual QA script (no secrets) |
| [XCODE_CLOUD.md](XCODE_CLOUD.md) | Native Xcode project, signing, and Xcode Cloud onboarding |
| [WIDGET_XTOOL.md](WIDGET_XTOOL.md) | WidgetKit extension via xtool `appex` |
| [AGENT_STATUS.md](AGENT_STATUS.md) | Agent handoff log |

## Development (WSL + xtool)

```bash
cd /mnt/c/Users/Aden/Documents/BetterSEQTA-Learn-IOS
xtool dev build    # compile (copy to ./xtool on /mnt/c may fail — use deploy script for device)
./scripts/deploy-iphone.sh   # rsync app sources to ~/BetterSEQTA-Learn-IOS-build (ext4), install .app
./scripts/build-ios-wsl.sh   # optional Linux mirror; excludes Android/DesQTA siblings
swift test         # parser/domain tests when iOS SDK is available
./scripts/verify-swift-tests.sh   # non-blocking smoke
./scripts/run-ios-parser-tests.sh   # xtool compile gate (WSL)
```

Bundle ID: `org.betterseqta.learn` (`xtool.yml`).

**Physical iPhone (Windows + WSL):** `.\scripts\attach-iphone-usb.ps1` then `.\scripts\deploy-iphone.ps1`. WSL: `sudo apt-get install -y zip unzip`. If install hangs at **[Connecting]**, see [DEVICE_DEPLOY_WSL.md](DEVICE_DEPLOY_WSL.md). Widget signing: [WIDGET_XTOOL.md](WIDGET_XTOOL.md).

If SwiftPM says another instance is using `.build` but no `swift`/`xtool` is running, remove the stale lock: `rm -f .build/.lock` (see [AGENT_STATUS.md](AGENT_STATUS.md)).

Sibling folders (`BetterSEQTA-Learn-Android`, internal iOS reference) are gitignored clones for read-only porting — do not import their symbols into `Sources/`.
