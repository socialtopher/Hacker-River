# Project Notes

These are repo-specific preferences and product decisions taught during development.

## Workflow

- Use test-driven development for product behavior: add failing tests first, then implement.
- Keep changes small and commit independent features separately.
- Run `npm test` and `npm run build` before considering app changes ready.

## Product Decisions

- A checkmark control (`✓`) to the left of each feed item number dismisses the item immediately.
- Dismissed items are stored in the local ledger with `dismissed: true` and should not reappear in the feed.
- Dismissal is separate from reading: dismissed items do not move into Recently Read.
- A `Share` control belongs in the metadata line to the right of the comments link.
- Sharing copies the story URL when available, falling back to the Hacker News comments URL.
