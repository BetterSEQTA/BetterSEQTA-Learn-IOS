# Xcode and Xcode Cloud

Open `BetterSEQTALearn.xcodeproj` in full Xcode (not just the command-line tools),
then select the shared `BetterSEQTALearn` scheme. The app target compiles
`Sources/BetterSEQTALearnApp` and links the feature libraries from the local
`Package.swift`. It embeds `LearnWidgetExtension`, which compiles the existing
WidgetKit sources. Neither entry-point library is also linked into its native
target, so each executable has just one `@main`.

## App identity and signing

The Xcode app uses the existing **BetterLearn** App Store Connect record:

- App bundle ID: `com.sethburkart.BetterLearn`
- Widget bundle ID: `com.sethburkart.BetterLearn.widget`
- Developer team: `5949S6UQCX`
- Shared App Group: `group.org.betterseqta.learn`

Both targets use automatic signing. Register the widget identifier and associate
the shared App Group with both identifiers in the developer account before
archiving a signed build. The App Group matches the existing shared-store code.
The `org.betterseqta.learn` background task identifiers and URL schemes retain
their existing values; they do not need to match the App Store bundle ID.

The separate xtool configuration keeps its original `org.betterseqta.learn`
identity. An xtool build and an Xcode build are therefore separate app installs.

## Initial Cloud setup

Apple requires the first workflow to be configured from Xcode:

1. Sign into the developer account in Xcode Settings > Accounts.
2. Open the project and choose Product > Xcode Cloud > Create Workflow (or the
   Cloud tab in the Report navigator).
3. Select `BetterSEQTALearn`, the developer team above, and the existing
   BetterLearn app record.
4. Authorize Xcode Cloud for `BetterSEQTA/BetterSEQTA-Learn-IOS` on GitHub.
5. Use the shared `BetterSEQTALearn` scheme, latest stable Xcode/macOS, and an
   iOS Archive action with no distribution for the first build. Run it on the
   setup branch before enabling automatic builds on `main`.
6. Inspect the build result and resolve any compiler or provisioning errors.

After onboarding, manage workflows in App Store Connect's Xcode Cloud module.
A successful archive is the initial CI gate. TestFlight distribution additionally
needs production app icons and the usual App Store validation requirements.
This scheme does not yet configure a test action; the existing SwiftPM test
suites remain separate.

There are no external Swift package dependencies or build-time credentials.
The committed project is ready for checkout; Xcode Cloud does not need XcodeGen,
xtool, Homebrew setup scripts, or project regeneration.

## Local validation

With full Xcode installed, build without provisioning first:

```bash
xcodebuild -project BetterSEQTALearn.xcodeproj \
  -scheme BetterSEQTALearn -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```

To check that Xcode Cloud can discover the app:

```bash
xcodebuild -project BetterSEQTALearn.xcodeproj \
  -describeAllArchivableProducts -json
```

## Maintaining the project

`project.yml` is the XcodeGen specification. After changing it, regenerate using
XcodeGen 2.46.0 and commit both the specification and generated project:

```bash
brew install xcodegen
xcodegen generate
```

Keep signing, target, and scheme changes in the specification so regeneration
preserves them. Do not commit `xcuserdata`, derived data, or signing credentials.

Reference: [Configuring your first Xcode Cloud workflow](https://developer.apple.com/documentation/xcode/configuring-your-first-xcode-cloud-workflow).
