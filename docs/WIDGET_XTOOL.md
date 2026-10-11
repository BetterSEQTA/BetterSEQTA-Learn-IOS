# WidgetKit + xtool app extension

Official guide: [Create App Extensions (appex)](https://xtool.sh/documentation/xtool/appex).

## Repo wiring

| Piece | Location |
|-------|----------|
| SPM product / target | `LearnWidget` → `Extensions/LearnWidget` |
| Widget `@main` | `LearnWidgetBundle` |
| Extension Info.plist | `LearnWidget-Info.plist` (`com.apple.widgetkit-extension`) |
| App Group (app + widget) | `group.org.betterseqta.learn` in `BetterSEQTALearn.entitlements` + `LearnWidget.entitlements` |
| Shared snapshot | `LearnWidgetSharedStore` / `HomeWidgetRefresh` (main app writes after home load) |
| xtool | `xtool.yml` → `product: BetterSEQTALearn`, `extensions: [{ product: LearnWidget, … }]` |

## Build & run

```bash
cd /mnt/c/Users/Aden/Documents/BetterSEQTA-Learn-IOS
rm -f .build/.lock
xtool dev build   # compiles app + embeds widget extension when appex is supported
xtool dev         # install; add widget from home-screen widget gallery
```

If copy to `xtool/BetterSEQTALearn.app` on `/mnt/c` fails (drvfs), use `./scripts/build-ios-wsl.sh`.

### Device install (WSL) and signing

Embedding `LearnWidget.appex` can trigger xtool signing error **Can't find free space of LoadCommands for CodeSignature**. Until that is resolved upstream:

- **`./scripts/deploy-iphone.ps1`** uses `xtool.device.yml` (no extension) by default.
- Widget QA on device may require Xcode/macOS embed, or `WITH_WIDGET=1 ./scripts/deploy-iphone.sh` when signing succeeds.

## Verify

1. Sign in on Coneqt-S (or your school).
2. Open **Home** so timetable snapshot is written.
3. Add **Next lesson** widget → should match in-app “next lesson”.
4. Sign out → widget shows sign-in required.

## Manual Xcode fallback

If your xtool build ignores `extensions:` (older CLI), use **File → New → Widget Extension** and link the `LearnWidget` product per the upstream doc.
