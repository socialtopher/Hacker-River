# IDEAS.md

## Faster

### 1. Virtualize long sections
- Apply `content-visibility: auto` and a reasonable `contain-intrinsic-size` to feed and recently-read rows.
- Why: offscreen rows can skip layout/paint work, which should help mobile responsiveness as the river grows.
- Effort: low.

### 2. Idle-time ledger cleanup and cache warming
- Move non-urgent cleanup, settings writes, and low-priority item hydration behind `scheduler.yield()` when available, with a `setTimeout` fallback.
- Why: keeps input handling responsive while background work runs.
- Effort: medium.

### 3. Offline shell + smarter session caching
- Add a minimal service worker for the app shell and recent API responses, while leaving HN data freshness rules explicit.
- Why: faster repeat loads and better subway-mode behavior.
- Effort: medium.

## More Animated

### 4. View-transition dismiss and paging motion
- Wrap dismiss, `More`, and `Recently Read` moves in progressive-enhancement view transitions.
- Why: the river can feel alive without turning into a heavy UI.
- Effort: medium.

### 5. Rank-change microstates
- Show a subtle rise/fall treatment when a story moves due to refresh or sort changes.
- Why: helps users understand what changed between refreshes.
- Effort: medium.

## More Useful

### 6. Keyboard command layer
- Add `j/k` navigation, `o` to open, `x` to dismiss, `s` to share, and `/` to focus settings/search later.
- Why: makes the app materially faster for daily use on desktop.
- Effort: medium.

### 7. Save-for-later lane
- Add a separate non-expiring or longer-TTL bucket distinct from dismissed/read.
- Why: gives users a middle ground between “not now” and “never”.
- Effort: medium.

### 8. Story-state filters
- Add quick filters like `All`, `Unread`, `Ask`, `Show`, `Jobs`, and `Read`.
- Why: complements the new sort control and makes the river easier to scan intentionally.
- Effort: low.

### 9. Trending delta badge
- Track score/comment deltas between refreshes and mark stories that are accelerating.
- Why: surfaces momentum, not just current rank.
- Effort: medium.

### 10. Cross-device sync
- Optional accountless export/import first, then lightweight cloud sync later.
- Why: keeps the ledger useful across phone and desktop without forcing auth on v1.
- Effort: high.

## Suggested Order

1. Virtualize long sections
2. View-transition dismiss and paging motion
3. Keyboard command layer
4. Story-state filters
5. Trending delta badge
6. Offline shell + smarter session caching
7. Save-for-later lane
8. Cross-device sync

## Research Notes

- `content-visibility` is now broadly available across major engines and is specifically intended to skip offscreen rendering work: [web.dev](https://web.dev/content-visibility), [MDN](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/content-visibility)
- Same-document view transitions are supported in Chromium-class browsers and can be used as a progressive enhancement with a fallback path: [Chrome for Developers](https://developer.chrome.com/docs/web-platform/view-transitions/same-document)
- Service-worker caching can speed repeat visits, but cache policy needs to stay aligned with freshness rules: [web.dev](https://web.dev/articles/service-worker-caching-and-http-caching?hl=en)
- `scheduler.yield()` is useful for breaking up long tasks, but still needs fallback handling for non-supporting browsers: [Chrome for Developers](https://developer.chrome.com/blog/use-scheduler-yield), [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Scheduler/yield)
- `requestIdleCallback()` remains non-baseline, so it should stay optional rather than required: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/Window/requestIdleCallback)
- Back/forward cache wins are worth preserving when adding future navigation/state features: [web.dev](https://web.dev/articles/bfcache?hl=en)
