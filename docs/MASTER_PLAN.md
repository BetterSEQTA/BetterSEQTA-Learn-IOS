# Master plan — BetterSEQTA Learn iOS

## Summary

Greenfield **SwiftPM + xtool** iOS app achieving **1:1 parity** with BetterSEQTA Learn Android, with polished motion/glass UX. Android is the source of truth for API and models; feature UIs should wire **full screens** (avoid Android `MainShell` placeholder tabs).

**Full plan (canonical detail):** [`.cursor/plans/learn_ios_port_plan_5f191c06.plan.md`](file:///c:/Users/Aden/.cursor/plans/learn_ios_port_plan_5f191c06.plan.md)

## Phases

| Phase | Focus | Status |
|-------|--------|--------|
| **0** | Docs, `Package.swift`, fixtures, secrets gitignore | Done |
| **1** | CoreSession, CoreNetworking, Data parsers + fixture tests | Done (iOS `swift test` on WSL limited) |
| **2** | CoreDesign + FeatureAuth (WebView, QR, launch loading) | In progress (~ onboarding carousel) |
| **3** | Feature modules (Home → Widget) in parallel | In progress (widget on device; BG workers partial) |
| **4** | Main shell: drawer, 5-tab bar, overlays, deep links | In progress (~ Material polish) |
| **5** | `swift test`, `xtool dev` smoke, JWACS manual QA | QA template ready; live JWACS not recorded |

## Repository layout

- `Sources/BetterSEQTALearnApp` — `@main`, shell entry (grows in Phase 4)
- `Sources/Core*` — platform layers
- `Sources/Domain` — models + repository protocols
- `Sources/Data` — DTOs, parsers, repository implementations
- `Sources/Feature*` — SwiftUI features
- `Tests/Fixtures` — JSON copied from Android unit tests
- `Secrets/` — gitignored credentials

## Definition of done

- All rows in [FEATURE_PARITY_CHECKLIST.md](FEATURE_PARITY_CHECKLIST.md) checked
- Student login on JWACS per [QA_SCHOOL_JWACS.md](QA_SCHOOL_JWACS.md)
- No secrets in git; no non-Learn codenames in `Sources/`
- `xtool dev` installs with team signing configured on the dev machine
