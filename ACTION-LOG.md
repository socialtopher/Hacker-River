# ACTION-LOG

## 2026-04-30 - Task 1

Summary of changes:
- Wired `favicon.svg` into the site document head.
- Added a focused test covering the favicon registration in `index.html`.

Files changed:
- `index.html`
- `src/indexHtml.test.js`

Verification performed:
- `npm test -- --run src/indexHtml.test.js`
- `npm test`
- `npm run build`

Remaining risks or follow-ups:
- None for this task.

## 2026-04-30 - Task 2

Summary of changes:
- Matched feed metadata typography to Hacker News by using the Verdana/Geneva/sans-serif stack instead of monospace.
- Added a focused stylesheet regression test for the HN font stack.

Files changed:
- `src/styles.css`
- `src/styles.test.js`
- `TASKS.md`

Verification performed:
- `npm test -- --run src/styles.test.js`
- `npm test`
- `npm run build`

Remaining risks or follow-ups:
- Visual parity is closer, but exact browser-level font rendering will still depend on the user’s installed Verdana fallback behavior.

## 2026-04-30 - Task 3

Summary of changes:
- Made HN Rank the default feed order instead of score sorting.
- Added a `Sort by` setting with immediate reordering for `HN Rank`, `Newest`, `Ask`, `Show`, and `Jobs`.
- Carried HN/source rank metadata through fetch and feed construction so sort changes do not require a refetch.

Files changed:
- `src/App.tsx`
- `src/App.test.tsx`
- `src/lib/constants.ts`
- `src/lib/feed.ts`
- `src/lib/feed.test.ts`
- `src/lib/hnApi.ts`
- `src/types.ts`
- `TASKS.md`

Verification performed:
- `npm test -- --run src/lib/feed.test.ts src/App.test.tsx`
- `npm test`
- `npm run build`

Remaining risks or follow-ups:
- Source-priority sorts use each story’s membership/rank inside the fetched HN source lists; if HN changes endpoint composition, the relative grouping will follow that API data.

## 2026-04-30 - Task 4

Summary of changes:
- Added a focused roadmap in `IDEAS.md` covering speed, animation, and usefulness improvements.
- Included a suggested implementation order and lightweight research notes with current references.

Files changed:
- `IDEAS.md`
- `TASKS.md`

Verification performed:
- `npm test`
- `npm run build`

Remaining risks or follow-ups:
- Roadmap items are proposals only; the service-worker and background-task ideas need implementation-time browser support checks before shipping.

## 2026-04-30 - Post-merge validation

Summary of changes:
- Fast-forward merged `night-work` into local `main`.
- Attempted local runtime validation after merge.

Files changed:
- `ERRORS.md`

Verification performed:
- `git merge --ff-only night-work`
- Attempted `npm run dev -- --host 127.0.0.1 --port 4173`
- Attempted browser inspection via Playwright MCP

Remaining risks or follow-ups:
- Deployment and live-site validation remain blocked until someone pushes `main` and checks the built site.

## 2026-06-21 - Native app port (SwiftUI, forked from Ember)

Summary of changes:
- Removed the React/Vite web app and vendored Ember (DatanoiseTV, MIT) as the
  native SwiftUI base for iPhone/iPad/Mac.
- Ported the river ledger to `RiverStore` (seen/read/dismissed + TTLs, read
  snapshots) and rebuilt feed construction in `FeedViewModel` (merged sources,
  ledger filtering, inbox count, new-post banner, rank/newest sort).
- Added the inbox count, "N new posts" banner, swipe-to-dismiss, a Recently Read
  tab/column, and river settings; rebranded throughout.
- Added an XcodeGen unit-test target with XCTest ports of the web tests, and a
  macOS Xcode build/test GitHub Actions workflow (replacing the npm Pages one).

Files changed:
- Whole `Sources/`, `Resources/`, `Tests/`, `project.yml`, `.github/workflows/`,
  plus `README.md`, `BUILD.md`, `ATTRIBUTION.md`, `DECISIONS.md`,
  `XCODE_BOOTSTRAP.md`.

Verification performed:
- None — Linux container has no Swift/Xcode toolchain. Code is complete and
  internally consistent; first compile happens on the Mac. See DECISIONS.md #18.

Remaining risks or follow-ups:
- Build/run/test on a Mac (BUILD.md); expect minor first-compile fixups. Use the
  hand-off prompt in XCODE_BOOTSTRAP.md.
