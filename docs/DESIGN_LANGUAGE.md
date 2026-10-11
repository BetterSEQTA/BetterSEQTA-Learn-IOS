# Design language — BetterSEQTA Learn iOS

## Principles

- **Liquid glass** surfaces: gradient mesh background → blurred cards/bars with subtle stroke (iOS 26 `glassEffect` when deployment target allows; fallback `Material.ultraThin`).
- **Motion**: spring-based transitions; respect user prefs `richAnimations` / `staggeredEntrances` / Reduce Motion.
- **Haptics**: tab changes, login success, destructive actions (`LearnFeedback` — Phase 2).
- **Accessibility**: Dynamic Type, contrast on glass, focus rings on controls.

## Tokens (initial)

| Token | Swift location | Notes |
|-------|----------------|-------|
| Background | `LearnTheme.Colors.background` | Dark mesh base |
| Glass card | `LearnGlassCard` | Rounded 16pt, ultraThin material |
| Accent | User setting + `LearnTheme.accentName` | Port Android `Color.kt` accents in Phase 2 |

## Motion (`LearnMotion`)

Mirror Android `AppMotion` behavior (Learn naming on iOS):

- Spatial / effects spring presets in `LearnMotion.swift`
- `LearnMotionProfile` environment + Reduce Motion
- Press scale via `LearnPrimaryButtonStyle` / `learnPressableScale`
- Staggered home section entrance (shell wires profile)

## Loading

- `FluidLoadingCoordinator` + `FluidLoadingBarView` for launch and section loads (`CoreDesign`).
- Full-screen launch overlay until `homeReady` (Android `AppLaunchLoadingScreen`).

## Components (backlog)

- Glass bottom navigation + message badge
- Drawer rows with icons
- Subject colour chips from timetable/home data
- HTML notice body: isolated `WKWebView` or attributed string parser

## Inspiration only

DesQTA glass CSS — translate to SwiftUI materials; do not embed web theme engine.
