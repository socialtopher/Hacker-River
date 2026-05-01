# Hacker River — Product Requirements Document

**Version:** 1.0  
**Author:** Chris Stewart  
**Date:** April 30, 2026  
**Status:** Draft

---

## 1. Problem Statement

Hacker News is a firehose. Every time you open it, you're re-scanning the same 30 posts you already decided you don't care about, hunting for the 2–3 new links that showed up since your last visit. There's no concept of "read" or "dismissed"—just a static ranked list that churns slowly.

**Hacker River** solves this by treating HN like a river of news: new items flow in, items you ignore flow out after 1 hour, items you read flow out after 5 days. You never see the same post twice unless you chose to read it—and even then, it clears itself. The feed is always fresh.

---

## 2. Product Overview

| Attribute | Detail |
|---|---|
| **Name** | Hacker River |
| **Type** | Single-page web application (React + Vite) |
| **Data Source** | [Hacker News Firebase API](https://github.com/HackerNews/API) |
| **Auth** | None (v1). All state is local (`localStorage`). |
| **Hosting Target** | Vercel (free tier), with portability to Netlify / Cloudflare Pages |
| **Look & Feel** | Hacker News clone aesthetic — monospace, dense, minimal chrome |
| **License** | Personal / TangibleClick LLC |

---

## 3. Core Mechanics

### 3.1 Feed Construction

1. On load, fetch up to **300 items** from the HN API by merging results from the `/topstories`, `/newstories`, `/askstories`, `/showstories`, and `/jobstories` endpoints.
2. Deduplicate by item ID.
3. If the combined set exceeds 300, prioritize by score (descending), then by time (newest first) as a tiebreaker.
4. Filter out any item whose ID exists in the **seen ledger** (see §3.2).
5. Render the remaining items as the feed.

### 3.2 The Seen Ledger

A `localStorage` object keyed by HN item ID, with the following shape:

```json
{
  "42012345": { "firstSeen": "2026-04-30T14:00:00Z", "tapped": false },
  "42012399": { "firstSeen": "2026-04-30T13:15:00Z", "tapped": true, "tappedAt": "2026-04-30T13:20:00Z" }
}
```

**Rules:**

| State | TTL | Behavior |
|---|---|---|
| **Unseen** (not in ledger) | — | Show in feed. Add to ledger with `firstSeen = now`, `tapped = false` on first render. |
| **Seen, not tapped** | 1 hour from `firstSeen` | Visible in feed until TTL expires, then hidden. Clock does **not** reset on re-render or app reopen. |
| **Tapped** | 5 days from `tappedAt` | Moves to a "Recently Read" section (collapsed by default). Hidden entirely after 5 days. |
| **Expired** | — | Purged from ledger on next cleanup pass to prevent unbounded storage growth. |

**Cleanup:** On every app load, iterate the ledger and delete entries whose TTL has fully elapsed.

### 3.3 Interaction Model

| Element | Action | Result |
|---|---|---|
| **Post title** | Tap / click | Opens the article URL in a new tab. Marks the item as `tapped = true` in the ledger. Item moves to "Recently Read." |
| **Comments link** | Tap / click | Opens `https://news.ycombinator.com/item?id={id}` in a new tab. Does **not** count as tapped. |
| **Points / meta line** | Display only | Shows score, author, time ago, and comment count. |

### 3.4 Feed Refresh

- **Manual pull-to-refresh** (or refresh button) re-fetches the API, deduplicates against the ledger, and appends genuinely new items to the top of the feed.
- **Auto-refresh** every 5 minutes in the background (configurable). New items appear with a subtle "N new posts" banner at the top; the feed does not jump.
- Expired items are removed from the DOM on each refresh cycle.

---

## 4. Information Architecture

```
┌─────────────────────────────────────┐
│  Hacker River               [⟳] [⚙] │
├─────────────────────────────────────┤
│  ● 3 new posts — tap to load        │  ← appears on background refresh
├─────────────────────────────────────┤
│  1. Post title (domain.com)          │
│     142 pts · user · 2h · 87 cmnts  │
│  2. Post title (domain.com)          │
│     ...                              │
├─────────────────────────────────────┤
│  ▸ Recently Read (4)                 │  ← collapsed by default
│     Post title · read 3h ago         │
│     Post title · read 1d ago         │
└─────────────────────────────────────┘
```

**Sections:**
1. **New banner** — appears only when background refresh finds items not yet in the ledger.
2. **Fresh feed** — unseen and seen-but-not-expired items, sorted by HN score descending.
3. **Recently Read** — tapped items within their 5-day TTL, sorted by `tappedAt` descending.

---

## 5. Visual Design

Stick close to the Hacker News aesthetic with minor quality-of-life upgrades:

- **Font:** `Verdana, Geneva, sans-serif` for body (HN's actual font), monospace for metadata.
- **Colors:** `#ff6600` header bar, `#f6f6ef` background, `#828282` metadata text — the classic HN palette.
- **Layout:** Single column, max-width ~85ch, left-aligned numbering.
- **Tapped items:** Visited-link purple (`#828282` text) with strikethrough on the domain tag, then fade-slide into the "Recently Read" bucket.
- **Expiring items:** No visual countdown. They simply disappear on the next refresh cycle. Clean and silent.
- **Mobile:** Fully responsive. Tap targets ≥ 44px. Feed is the entire viewport.

---

## 6. Technical Architecture

### 6.1 Stack

| Layer | Choice | Rationale |
|---|---|---|
| Framework | React 18 + Vite | Fast builds, Vercel-native, you know React |
| Styling | Tailwind CSS | Utility-first, minimal custom CSS needed for the HN look |
| State | React state + `localStorage` | No server, no DB — all client-side for v1 |
| Hosting | Vercel (free tier) | Git-push deploy, custom domain, edge CDN |
| API | HN Firebase REST API | No auth required, public, free |

### 6.2 API Usage

The HN API returns item IDs from list endpoints, then requires a per-item fetch for details. For 300 items, that's 300+ requests.

**Mitigation:**
- Fetch IDs from all list endpoints in parallel.
- Batch item detail fetches using `Promise.allSettled` in chunks of 50 with a concurrency limiter.
- Cache item details in `sessionStorage` (keyed by item ID) to avoid re-fetching within a session.
- On background refresh, only fetch IDs and diff against the ledger — skip detail fetches for known IDs.

### 6.3 localStorage Schema

```
hackerriver_ledger  → JSON object (seen ledger, §3.2)
hackerriver_settings → JSON object (auto-refresh interval, theme, etc.)
```

Estimated storage: ~300 entries × ~150 bytes = ~45KB. Well within the 5–10MB localStorage limit. Cleanup on load prevents unbounded growth.

### 6.4 Deployment

```
repo (GitHub)
  └── push to main
       └── Vercel auto-deploy
            └── static SPA served from edge CDN
```

No server-side code. No environment variables. No API keys. Pure client-side SPA.

---

## 7. Settings (v1)

Accessible via a gear icon in the header. Stored in `localStorage`.

| Setting | Default | Options |
|---|---|---|
| Auto-refresh interval | 5 min | 1 / 5 / 15 / 30 min / Off |
| Unseen TTL | 1 hour | 30 min / 1 hr / 2 hr / 4 hr |
| Tapped TTL | 5 days | 1 / 3 / 5 / 7 days |
| Feed sources | All | Toggle: Top / New / Ask / Show / Jobs |
| Max items | 300 | 100 / 200 / 300 / 500 |

---

## 8. Edge Cases & Landmines

| Scenario | Handling |
|---|---|
| **localStorage cleared** | Ledger resets. All posts appear as new. Acceptable for v1 — user is anonymous. |
| **HN API rate limiting** | The Firebase API has no documented rate limit, but be defensive: exponential backoff on 429/5xx, and surface a toast ("HN is slow right now") rather than failing silently. |
| **Post deleted on HN** | Item fetch returns `null` or `dead: true`. Skip it. |
| **300+ items across endpoints** | Deduplicate first, then trim by score. Don't fetch details for items that will be trimmed. |
| **Browser tab left open overnight** | Background refresh keeps running. Items expire per their TTL. On next interaction, the feed is fresh. This is a feature. |
| **Multiple tabs** | `localStorage` is shared across tabs in the same origin. Reads in one tab update the ledger for all tabs. No cross-tab sync needed — the next refresh in any tab picks up the latest ledger. |

---

## 9. Out of Scope (v1)

- User accounts / authentication
- Server-side storage or sync
- Comment rendering in-app
- Upvoting or interacting with HN
- Search
- Notifications / push alerts
- Dark mode (add in v1.1 — it's trivial with Tailwind)

---

## 10. Future Roadmap

| Phase | Scope | Purpose |
|---|---|---|
| **v1.1** | Dark mode, keyboard shortcuts (j/k navigation, o to open), export read history as JSON | Polish |
| **v1.2** | Optional lightweight auth (email magic link or GitHub OAuth) + cloud sync of ledger via Supabase or Vercel KV | Cross-device sync |
| **v1.3** | "Save for later" bookmarks with a separate TTL (30 days), shareable read lists | Retention |
| **v2.0** | AI-powered relevance scoring — rank incoming posts by your read history patterns, surface posts you're *likely* to tap | Personalization |

---

## 11. Success Criteria

This is a personal tool. Success is simple:

1. **I actually use it daily** instead of going to news.ycombinator.com.
2. **Zero re-scanning** — every item in the feed is either new or something I chose to read.
3. **Deploys in < 5 minutes** from a fresh `git push`.
4. **Works on my phone** without pinch-zooming or fighting the UI.

---

## 12. Open Questions

1. Should there be a "snooze" action — dismiss a post now but resurface it in N hours? (Leaning no — if you don't care now, you won't care later. Per your own words.)
2. Should "Recently Read" be a separate route (`/read`) instead of a collapsed section? Depends on how cluttered it feels in practice.
3. Is there value in a "trending up" indicator for posts whose score jumped significantly between refreshes? Low effort, might be useful.

---

*This document is the starting point. Build the v1, ship it to Vercel, use it for a week, then revise.*
