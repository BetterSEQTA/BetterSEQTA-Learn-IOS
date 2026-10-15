# Liquid Glass (iOS 26+)

BetterSEQTA Learn targets **iOS 26** in `Package.swift` and uses native SwiftUI
[`glassEffect`](https://developer.apple.com/documentation/SwiftUI/View/glassEffect(_:in:)),
[`GlassEffectContainer`](https://developer.apple.com/documentation/SwiftUI/GlassEffectContainer), and
[`glassEffectID`](https://developer.apple.com/documentation/SwiftUI/View/glassEffectID(_:in:)) via
`CoreDesign/LearnLiquidGlass.swift` and grouped surfaces / drawer (`LearnShellDrawer`,
`learnGroupedGlass`, etc.). **`LearnShellTopBar`** is a flat bar (menu · centered title · actions).

**Tab bar:** `MainShell` uses SwiftUI **`TabView`** (same approach as
[TechQTA](https://github.com/BetterSEQTA/BetterSEQTA-Teach-IOS)) so iOS 26+ draws the
system **floating Liquid Glass** tab bar. Do not replace it with a full-width custom bar.

**Navigation:** TeachQTA-style **`TabView`** plus a shared **`LearnShellTopBar`** above tab content.
**Settings** pushes inside the active tab’s `NavigationStack`. Portals/Notices use overlay routes.

See Apple’s [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass).

## Linux + xtool

1. Install **xtool 1.20.1+** and **Swift 6.2+** with the **Xcode 26/27 Darwin SDK**:
   `xtool sdk build /path/to/Xcode_27.xip -o darwin.xtoolsdk` then `xtool sdk install darwin.xtoolsdk`.
2. Build from the synced tree: `WIN_SRC=/path/to/repo ./scripts/build-ios-wsl.sh`.

Avoid opaque `toolbarBackground` / legacy sheet materials on navigation chrome; they block system glass.
