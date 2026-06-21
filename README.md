<div align="center">

# Hacker River

**Hacker News as a river — a native reader for iPhone, iPad, and Mac.**

New stories flow in, the ones you skip flow out after an hour, the ones you read
move to Recently Read for a few days, and the ones you dismiss never come back.
You never re-scan the same post twice. The feed is always fresh.

![Platform](https://img.shields.io/badge/platform-iPhone%20%C2%B7%20iPad%20%C2%B7%20Mac-black)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-blue)
![Dependencies](https://img.shields.io/badge/dependencies-none-brightgreen)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

</div>

Hacker River is a SwiftUI app built on top of
[**Ember**](https://github.com/DatanoiseTV/ember-hackernews) by DatanoiseTV (MIT).
Ember provides the native foundation — threaded comments, search, offline cache,
bookmarks, accessibility, and the adaptive iPhone/iPad/Mac layout — and Hacker
River adds the thing that makes it a *river*: a per-story lifecycle so the feed
curates itself. See [ATTRIBUTION.md](ATTRIBUTION.md).

## The river

Every story you see is tracked in a local **ledger** and flows through states:

| State | What it means | Default TTL |
| --- | --- | --- |
| **Unseen** | Hasn't appeared yet | — (always shown) |
| **Seen, not read** | Appeared, you scrolled past | **1 hour**, then it flows out |
| **Read** | You opened the link or the discussion | **5 days** in Recently Read |
| **Dismissed (✓)** | You checked it off | Gone immediately, forever |

- **Inbox count** in the title shows how many live stories are waiting.
- **"● N new posts — tap to load"** banner appears when background refresh finds
  stories that aren't in your river yet.
- **Swipe** a story right to **Save**, left to **Dismiss (✓)**. Opening it (link
  or discussion) moves it to **Recently Read**.
- The **River** chip merges your chosen feeds (Top/New/Ask/Show/Jobs by default);
  the other chips focus a single Hacker News feed.

Everything is on-device; there is no account and no server.

## Inherited from Ember

Native threaded comments (Algolia, one request per thread), full-text search,
offline disk cache, Saved stories, in-app Safari with Reader mode, user profiles,
six accent themes, full light/dark, haptics, a first-run onboarding that adapts to
your accessibility settings, and a three-pane layout on Mac and large iPad.

## Build & run

This repo has **no checked-in Xcode project** — it's generated from `project.yml`
with [XcodeGen](https://github.com/yonaskolb/XcodeGen). On a Mac with Xcode 16+:

```sh
brew install xcodegen        # once
xcodegen generate            # creates HackerRiver.xcodeproj
open HackerRiver.xcodeproj   # then ⌘R to run, ⌘U to test
```

Set your **Signing Team** on the `HackerRiver` target the first time (the project
ships with `DEVELOPMENT_TEAM` empty). For a fuller walkthrough — including the
command-line build/test invocations and the in-Xcode AI bootstrap prompt — see
[BUILD.md](BUILD.md).

## Project layout

```
Sources/
  App/            App entry, adaptive root (tabs vs. three-pane)
  Stores/         RiverStore (the ledger), BookmarkStore, SettingsStore
  Features/       Feed (the river), RecentlyRead, StoryDetail, Search, Saved,
                  Settings, User, Onboarding, Desktop, Shared
  Models/         HNItem, Feed, Algolia, HNUser
  Networking/     HNService (Firebase + Algolia), DiskCache, MockHNService
  DesignSystem/   Theme, Typography, components
  Utilities/      HTML rendering, relative time, launch args
Resources/        Info.plist, assets, Inter font
Tests/            XCTest ports of the river ledger + feed logic
project.yml       XcodeGen project definition
```

## License

MIT — see [LICENSE](LICENSE) (inherited from Ember) and
[ATTRIBUTION.md](ATTRIBUTION.md).
