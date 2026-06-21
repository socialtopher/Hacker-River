# Project Notes

These are repo-specific preferences and product decisions taught during development.

## Platform (current)

- Hacker River is now a **native SwiftUI app** (iOS/iPad/Mac), forked from Ember
  (DatanoiseTV, MIT). The React/Vite web app was removed. See README.md,
  ATTRIBUTION.md, DECISIONS.md.
- No checked-in `.xcodeproj`; generate with `xcodegen generate`. Build/test in
  Xcode (`⌘R` / `⌘U`) or via `xcodebuild` — see BUILD.md.
- No third-party dependencies. Match Ember's existing code style.

## Workflow

- Use test-driven development for product behavior: add failing tests first, then implement.
- Keep changes small and commit independent features separately.
- Run tests (`⌘U` / `xcodebuild test`) and a build before considering changes ready.
- The product decisions below were defined for the web app and are now realized
  natively (the ✓ dismiss control is a left-swipe; Share is in the row/context
  menu; "paging" is lazy infinite scroll; the title count is the river inbox).

## Product Decisions

- A checkmark control (`✓`) to the left of each feed item number dismisses the item immediately.
- Dismissed items are stored in the local ledger with `dismissed: true` and should not reappear in the feed.
- Dismissal is separate from reading: dismissed items do not move into Recently Read.
- A `Share` control belongs in the metadata line to the right of the comments link.
- Sharing copies the story URL when available, falling back to the Hacker News comments URL.
- The feed uses Hacker News-style paging: show 30 items at a time with a `More` control.
- Moving to the next page clears all currently visible page items by marking them dismissed.
- The title count is an inbox count: all fetched API items remaining after clicked or dismissed items are removed.
