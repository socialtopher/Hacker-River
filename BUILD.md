# Building & testing Hacker River on your Mac

This native app was authored in a Linux container with **no Xcode toolchain**, so
it has **not been compiled** yet. The code is complete and self-consistent, but
the first real build happens on your Mac. Expect to spend a few minutes on
signing and possibly a small fixup or two — that's normal for a fresh fork that
hasn't seen a compiler.

## Prerequisites

- macOS with **Xcode 16 or newer** (iOS 18 SDK; the app targets iOS 18 and Mac
  Catalyst 15).
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## 1. Generate the Xcode project

There's no `.xcodeproj` in git — it's generated from `project.yml`:

```sh
cd Hacker-River
xcodegen generate
open HackerRiver.xcodeproj
```

## 2. Set signing

Select the **HackerRiver** target → **Signing & Capabilities** → choose your Team.
(`project.yml` ships `DEVELOPMENT_TEAM` empty and code signing disabled so it
generates cleanly; for on-device runs you'll want a team. The Simulator runs
without signing.)

## 3. Run

- **iPhone/iPad:** pick a Simulator and press **⌘R**.
- **Mac (Catalyst):** choose "My Mac (Mac Catalyst)" and **⌘R**.

## 4. Test

Press **⌘U**, or from the command line:

```sh
xcodebuild test \
  -project HackerRiver.xcodeproj \
  -scheme HackerRiver \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

The `Tests/` target ports the original web app's ledger and feed logic
(`RiverStoreTests`, `FeedLogicTests`).

A command-line build only:

```sh
xcodebuild build \
  -project HackerRiver.xcodeproj \
  -scheme HackerRiver \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Likely first-build fixups

The code follows Ember's existing patterns closely, but since nothing here has
been through `swiftc`, watch for:

- **Strict-concurrency warnings** if your project bumps Swift to 6 language mode.
  The app uses Swift 5 mode (`SWIFT_VERSION: 5.0`), where these are warnings, not
  errors.
- **SF Symbol names** — all symbols used (e.g. `water.waves`, `book.fill`,
  `book.closed`) exist on iOS 18, but if Xcode flags one, substitute a near match.
- **Preview crashes** are harmless to the app; `#Preview` blocks inject the
  stores they need, but previews aren't part of `xcodebuild build`.

If something doesn't compile, the fastest path is the bootstrap prompt below.

## Hand-off: bootstrap prompt for Claude inside Xcode

Open the project in Xcode, start Claude (or any coding assistant) at the repo
root, and paste the prompt in [`XCODE_BOOTSTRAP.md`](XCODE_BOOTSTRAP.md). It tells
the assistant exactly what this project is, what was done in the Linux session,
what hasn't been verified, and how to drive it to a green build and test run.
