# ERRORS.md

## 2026-04-30 - Live site validation blocked

- Local merge to `main` completed successfully.
- Remote deployment was not triggered from this environment because no push was performed.
- Local browser validation was also blocked:
  - `npm run dev -- --host 127.0.0.1 --port 4173` failed with `listen EPERM: operation not permitted 127.0.0.1:4173`.
  - Playwright browser access failed with `Browser is already in use ... use --isolated to run multiple instances of the same browser`.

### What needs human follow-up

1. Push local `main` to `origin/main`.
2. Wait for the GitHub Actions / deployment build to finish.
3. Open the deployed site and sanity-check:
   - favicon loads
   - metadata font matches HN more closely
   - `Sort by` defaults to `HN Rank`
   - changing `Sort by` immediately reorders the feed
