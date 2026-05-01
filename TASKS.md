# TASKS.md — Hacker River Overnight Build Plan

## Mission

You are working on **Hacker River**, an application owned by Chris.

Your job is to make meaningful, reviewable progress while I am away/asleep. Work carefully, keep changes focused, and leave the project in a better state than you found it. Be brief. 

Do not make broad rewrites unless explicitly instructed. Prefer small, safe, incremental improvements that can be reviewed and merged confidently. Once a task is complete, remove from open tasks and add to a new section below called Closed Tasks.

---

## Open Tasks

1. Using this context: "Current sorting:

Score descending
Tie-breaker: newer story time first
Closest-to-HN sorting options:

Preserve API order: closest for each HN page, especially topstories, because HN already returns ranked IDs.
Preserve source order: top, then new, ask, show, jobs; closest if treating each HN section as a block.
Current score sort: good “river by popularity,” but not closest to HN because HN ranking is not just score.
Add a setting: HN order vs Score vs Newest.
I’d pick HN order as the default next.", make HN Rank the default, and create a drop-down in settings called "Sort by" with these choices: HN Rank, Newest, Ask, Show, and Jobs. Change the sort immediately when a new sort order is selected. 

2. Research a roadmap of additional features that would make Hacker River faster, more animated, or more usefu, and propose each idea in IDEAS.md for my review later. 

## Closed Tasks

1. I've dropped favicon.svg into the repo folder. Set it up as the favicon of the site.
2. Inspect the font actually used on hacker news and update the hacker river font to match (as long as there's not a copyright issue; if so, choose a similar alternative)
