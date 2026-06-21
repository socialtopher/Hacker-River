# Xcode bootstrap prompt

Copy everything in the fenced block below into Claude (or your coding assistant)
running at the root of this repo on your Mac. It hands off cleanly from the Linux
session that authored the app.

---

```
You are picking up a SwiftUI app called Hacker River. Read this fully before acting.

WHAT THIS IS
- A native iOS/iPad/Mac (Mac Catalyst) Hacker News reader.
- It is a fork of Ember (github.com/DatanoiseTV/ember-hackernews, MIT) with a
  "river" feature layered on top. Ember provides feeds, native threaded comments,
  search, offline disk cache, bookmarks, accessibility, onboarding, and the
  adaptive tab/three-pane layout.
- The "river" is the differentiator: every story is tracked in a local ledger and
  flows through states — Unseen -> Seen (1h TTL) -> Read (Recently Read, 5d TTL)
  -> or Dismissed (gone immediately). The feed never shows the same post twice.

KEY FILES TO ORIENT YOURSELF (read these first)
- README.md, BUILD.md, ATTRIBUTION.md, DECISIONS.md  (DECISIONS.md explains every
  design choice and any assumption made without the owner present).
- Sources/Stores/RiverStore.swift        the ledger (the heart of the app)
- Sources/Features/Feed/FeedViewModel.swift   merges sources + filters the river
- Sources/Features/Feed/FeedView.swift        inbox count, new-posts banner, swipes
- Sources/Features/RecentlyRead/RecentlyReadView.swift
- Sources/Stores/SettingsStore.swift / Features/Settings/SettingsView.swift
- project.yml                            XcodeGen project (no .xcodeproj in git)
- Tests/RiverStoreTests.swift, Tests/FeedLogicTests.swift

CRITICAL CONTEXT
- This code was written in a Linux container with NO Swift/Xcode toolchain, so it
  has NEVER been compiled. It is complete and internally consistent, but the first
  compile is happening now, with you. Treat build errors as expected first-pass
  issues, not as signs something is deeply wrong.
- Do not re-architect. The river design is intentional and documented in
  DECISIONS.md. Make the smallest changes needed to compile, pass tests, and run.

YOUR TASK
1. Generate the project and build it:
     xcodegen generate
     xcodebuild build -project HackerRiver.xcodeproj -scheme HackerRiver \
       -destination 'platform=iOS Simulator,name=iPhone 16'
   (If the named simulator doesn't exist, run `xcrun simctl list devices` and pick
   an available iPhone.)
2. Fix any compile errors with minimal, idiomatic edits. Most likely areas:
   SwiftUI strict-concurrency around the @Observable stores and the @MainActor
   FeedViewModel; an SF Symbol name; or a SwiftUI API signature. Keep RiverStore's
   ledger semantics (TTLs, dismissed-never-returns, read snapshots) intact.
3. Run the tests and make them pass:
     xcodebuild test -project HackerRiver.xcodeproj -scheme HackerRiver \
       -destination 'platform=iOS Simulator,name=iPhone 16'
   The tests encode the river rules — if a test fails, prefer fixing the code to
   match the test, not weakening the test, unless the test is clearly wrong.
4. Launch in the Simulator and sanity-check the river end to end:
   - Stories load in the River tab with an inbox count in the title.
   - Swiping left dismisses a story (✓) and it doesn't come back.
   - Opening a story (link or discussion) moves it to the Recently Read tab.
   - Settings -> River shows auto-refresh, TTLs, sort, and source toggles.
5. Report what you changed and the final build/test status. Then ask the owner
   (Chris) before any larger work (e.g. background push, iCloud sync, App Store
   prep).

CONVENTIONS
- Match the surrounding Ember code style. No new third-party dependencies.
- Commit in small logical chunks with clear messages. The active branch is
  claude/hacker-river-native-app-no5ryf; main has the same content.
```
