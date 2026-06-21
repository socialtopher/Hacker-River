# Attribution

Hacker River is built on top of **Ember**, a native SwiftUI Hacker News client by
**DatanoiseTV**, used under the MIT License.

- Upstream project: https://github.com/DatanoiseTV/ember-hackernews
- Upstream license: MIT — preserved verbatim in [LICENSE](LICENSE)
  (`Copyright (c) 2026 DatanoiseTV`).

## What came from Ember

The native foundation: the SwiftUI app structure and adaptive iPhone/iPad/Mac
layout, the Hacker News networking layer (Firebase API for feeds/items/users and
the Algolia API for comment trees and search), the disk cache, native threaded
comment rendering, search, bookmarks, user profiles, the design system and
typography, onboarding, and the accessibility work.

The `Tools/` scripts and the warm "Ember" accent color are also retained from
upstream — the accent name is kept as a small nod to the original.

## What Hacker River adds

The "river" model and its supporting UI:

- `RiverStore` — the seen/read/dismissed ledger with per-state TTLs, ported from
  the original Hacker River web app's `localStorage` ledger.
- River feed construction in `FeedViewModel` (merged sources, ledger filtering,
  inbox count, new-post detection, rank/newest sort).
- The inbox count, the "new posts" banner, swipe-to-dismiss, and the Recently
  Read screen.
- River settings (auto-refresh, unseen/read TTLs, sources, sort) and the rebrand.

The original Hacker River product (a React/Vite web app) lived in this repo's
history before being replaced by this native app; its product requirements are in
[`hacker-river-prd.md`](hacker-river-prd.md).
