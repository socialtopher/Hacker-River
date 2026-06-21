# Changelog

All notable changes to Hacker River (native) are documented here. The format is
based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.0.0] - 2026-06-21

First native release. Hacker River became a SwiftUI app for iPhone, iPad, and Mac,
built on top of [Ember](https://github.com/DatanoiseTV/ember-hackernews) (MIT) —
see [ATTRIBUTION.md](ATTRIBUTION.md). The React/Vite web app was removed.

### Added (the river, on top of Ember)
- **River feed** — merges your chosen Hacker News feeds and tracks every story in
  a local ledger so seen-but-skipped stories expire out (default 1h), read stories
  move to Recently Read (default 5d), and dismissed stories never return.
- **Inbox count** in the feed title and a **"● N new posts — tap to load"** banner
  driven by foreground auto-refresh.
- **Swipe to dismiss (✓)** and swipe to save; opening a story (link or discussion)
  moves it to **Recently Read** (new tab and desktop sidebar item).
- **River settings** — auto-refresh interval, unseen/read TTLs, sort (Rank/Newest),
  and which feeds are merged into the river.
- A `RiverStore` ledger persisted to disk with read snapshots (Recently Read works
  offline), and XCTest ports of the original web app's ledger and feed logic.

### Inherited from Ember
Native threaded comments, full-text search, offline disk cache, Saved stories,
in-app Safari + Reader mode, user profiles, onboarding, accent themes, light/dark,
haptics, accessibility, and the adaptive tab/three-pane layout.
