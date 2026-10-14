# BetterSEQTA Learn iOS

SwiftUI student app for SEQTA Learn, ported from [BetterSEQTA Learn Android](BetterSEQTA-Learn-Android/) using **SwiftPM** and **[xtool](https://xtool.sh/)**.

## Quick start

See [docs/README.md](docs/README.md) for architecture, API notes, and agent workflow.

```bash
# WSL (after install-xtool-wsl.sh)
cd /mnt/c/Users/Aden/Documents/BetterSEQTA-Learn-IOS
xtool dev
./scripts/verify-swift-tests.sh
```

## Xcode / Xcode Cloud

Open `BetterSEQTALearn.xcodeproj` and select the `BetterSEQTALearn` scheme.
See [Xcode Cloud setup](docs/XCODE_CLOUD.md) for signing, cloud onboarding, and
local build commands. The Xcode app uses `com.sethburkart.BetterLearn` for the
existing BetterLearn App Store Connect record.

The xtool bundle ID remains `org.betterseqta.learn`.
