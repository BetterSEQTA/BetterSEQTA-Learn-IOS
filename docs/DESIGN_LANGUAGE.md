# Design language — BetterSEQTA Learn iOS

Aligned with [Apple HIG Components](https://developer.apple.com/design/human-interface-guidelines/components) and [Motion](https://developer.apple.com/design/human-interface-guidelines/motion). Interaction polish follows fluid-interface principles (press feedback, springs, interruptible transitions).

## Principles

- **Typography**: semantic scale in `LearnTypography` (screen / section / row / meta). Use `learnReadableBody()` on multi-line previews; prefer `primaryText` → `secondaryText` → `tertiaryText` for hierarchy.
- **Layout**: flat canvas (`LearnScreenBackground`), inset grouped **glass** sections (`LearnGlassGroupedSection`, `learnGroupedGlass`), 20pt horizontal padding (`LearnLayout.horizontalPadding`).
- **Glass tiers**: chrome bars (`learnChromeGlass`), grouped surfaces (`learnGroupedGlass`), compose/sheets (`learnComposeMaterial`, `learnLiquidGlassSheetBackground`). iOS 26 uses `glassEffect`; earlier iOS uses `ultraThinMaterial`.
- **Accent**: BetterSEQTA indigo (`LearnTheme.Colors.accent`) on controls and selection only.
- **Motion**: chrome uses critically damped springs (`LearnMotion.spatialStandard*`); morphing islands/tabs/destructive confirm use `fluidMorphSpring` / `liquidTabSpring` (light overshoot). Drawer: `drawerSpring`. Gate on `LearnMotionProfile` / Reduce Motion.
- **Press**: default micro-depression `0.96` (`LearnPressFeedbackStyle`).
- **Haptics**: `LearnHaptics.selection()` / `lightImpact()` on tabs, segments, and primary actions.

## Component map (Swift)

| HIG role | Swift |
|----------|--------|
| Navigation bar | `LearnShellTopBar`, `LearnInlineNavBar` |
| Tab bar | `LearnShellBottomBar` |
| Sidebar | `LearnShellDrawer` |
| Section header | `LearnSectionHeader` |
| List row | `LearnListRow` |
| Search | `LearnSearchField` |
| Segmented control | `LearnUnderlineSegmentBar` (`density`: `.compact` / `.regular`, `style`: `.discrete` / `.fluid`) |
| Date navigation | `LearnDateChrome`, `LearnGraphicalDateSheet` |
| Grouped content | `LearnGlassGroupedSection`, `LearnGlassCard` |
| Settings lists | `LearnGlassListRowBackground`, `learnInsetSettingsList()` |
| Status | `LearnStatusChip` |
| HTML body | `LearnHTMLContentView` |
| Loading / empty / error | `LearnLoadingState`, `LearnEmptyState`, `LearnErrorBanner` |
| Press / list entrance | `learnRowPress`, `learnListEntrance` |
| Fluid interactions | `LearnFluidInteractions` — copy/success morph (`LearnCopyMorphButton`, `LearnCopyMorphIconButton`, `LearnMorphSuccessFeedback`), action icons, inline delete, timed undo |
| Scroll island | `LearnScrollOffsetReporter`, `learnScrollIslandChrome` |
| Inline toast | `learnInlineToast` |

## Shell navigation depth

- Root tabs report `learnShellNavigationDepth(0)`.
- Pushed details report `learnShellNavigationDepth(1)` and use `LearnInlineNavBar` so the shell top bar animates away.

## Manual QA checklist

- [ ] Home — glass sections, notice preview + sheet, header scroll fade
- [ ] Timetable — week pager, agenda/day, date sheet
- [ ] Courses — list rows, subject detail inline nav
- [ ] Tasks — underline segments, assessment detail glass sections
- [ ] Messages — search field, folders, detail inline nav, compose glass
- [ ] Notices (drawer) — date chrome, labels, HTML detail
- [ ] Portals — glass tiles, portal sheet
- [ ] Settings / Notifications / Calendar sync — grouped lists
- [ ] Login — underline methods, glass fields
- [ ] Drawer + tab bar — glass chrome, haptics
- [ ] Reduce Motion — no stagger / minimal transitions

## Loading

- `FluidLoadingCoordinator` + `FluidLoadingBarView` for long operations.
- `LearnSkeletonView` presets per screen type.
