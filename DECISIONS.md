# Decisions log — native port (overnight, unattended)

Choices made while turning Hacker River into a native SwiftUI app on top of Ember,
recorded so nothing silently surprised you. Owner-confirmed choices up front; the
rest were judgement calls made to keep moving without pausing.

## Confirmed with the owner before starting
- **Approach:** SwiftUI native, modeled on / forked from Ember.
- **Ember:** fork/vendor the real upstream source (MIT) rather than reimplement.
- **Web app:** delete the React/Vite app entirely (kept only product docs).

## Scope & feature mapping
1. **Kept all of Ember's features** (native comments, search, offline cache,
   bookmarks/Saved, accessibility, onboarding, three-pane desktop). They directly
   realize Hacker River's own roadmap (comments, dark mode, save-for-later), so
   removing them would have thrown away exactly what we wanted.
2. **The river is the default mode.** The feed's chip bar is `[River] + Top, New,
   Best, Ask, Show, Jobs`. The **River** chip merges sources and applies the full
   ledger (seen/read/dismissed + TTL outflow). Selecting a single feed is a
   "browse" mode that still honors dismissals and dims read items but does **not**
   expire items out — the River is the curated inbox; single feeds are for digging.
3. **Default river sources = Top, New, Ask, Show, Jobs** (matches the web app).
   **Best** is available as a toggle but off by default.
4. **Sort options reduced to Rank and Newest.** The web app also had Ask/Show/Job
   "source sorts"; those are redundant now that each source is a first-class chip.
   *Newest* is approximated by descending item id (higher id == more recent) to
   avoid fetching every item just to sort.
5. **Recently Read is its own tab / sidebar item**, promoted from the web app's
   collapsed section (answering the PRD's open question #2).

## River mechanics
6. **Opening either the article link OR the discussion marks a story read** (a
   "tap") and moves it to Recently Read. The web app distinguished title-tap from
   comments-link, but Ember's model centers the discussion view, so both count.
   This matches the river's intent: engaging with a story removes it from the feed.
7. **"Mark as Unread" / "Back to River" resets `firstSeen` to now**, so a restored
   story actually reappears instead of being instantly filtered out as an old,
   already-expired entry.
8. **Ledger persisted as JSON in Application Support** (like Ember's BookmarkStore),
   not UserDefaults, because entries carry timestamps and a story snapshot.
9. **Read snapshots are stored** so Recently Read renders offline and after
   relaunch (the live feed no longer holds those items).
10. **River merge tolerates a single failing source** (`try?` per source) so one
    bad endpoint doesn't sink the whole river; single-feed mode still surfaces
    errors normally.
11. **`markSeen` runs per fetched page** (only stories actually loaded get a
    `firstSeen` clock). The web app timestamped the whole built feed at once; the
    native app pages lazily, so this is both necessary and arguably more correct.
12. **Auto-refresh is a foreground task loop** that only sets the "N new posts"
    banner (no background-fetch entitlement, no silent reloads) — mirroring the
    web app's in-tab interval behavior.

## Project / packaging
13. **Bundle id `com.tangibleclick.hackerriver`**, marketing version `1.0.0`,
    `CURRENT_PROJECT_VERSION 1`. `DEVELOPMENT_TEAM` left blank — set it in Xcode.
14. **App display name "Hacker River"**, target/module `HackerRiver`,
    `@main struct HackerRiverApp`.
15. **Kept the upstream MIT `LICENSE` verbatim** and added `ATTRIBUTION.md`. Kept
    the "Ember" accent color name as a small nod to the origin.
16. **Added an XcodeGen unit-test target** (`HackerRiverTests`) hosted in the app,
    with XCTest ports of `ledger.test.ts` and `feed.test.ts`.
17. **Replaced the GitHub Pages (npm) workflow** with a macOS Xcode build+test
    workflow (`.github/workflows/ios-ci.yml`). The old workflow deployed the web
    app and is no longer meaningful.

## The big caveat
18. **Nothing here has been compiled.** This was authored in a Linux container with
    no Swift/Xcode toolchain. The code is complete and internally consistent and
    follows Ember's patterns, but the first real compile is on your Mac. See
    `BUILD.md` for the build/test steps and `XCODE_BOOTSTRAP.md` for a hand-off
    prompt to finish any first-build fixups. This is the one place I'd expect to
    spend follow-up time.

## Git
19. Work committed in logical chunks and pushed to **both** `main` and
    `claude/hacker-river-native-app-no5ryf` (per the request to commit to main).
    No pull request was opened.
