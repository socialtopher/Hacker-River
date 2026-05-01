import { describe, expect, it } from 'vitest';
import { buildFeed, findNewIds, mergeStoryIds } from './feed';
import type { HnItem, SeenLedger } from '../types';

const story = (id: number, score: number, time: number): HnItem => ({
  id,
  score,
  time,
  title: `Story ${id}`,
  type: 'story',
});

describe('feed construction', () => {
  it('deduplicates story ids while preserving first source order', () => {
    expect(mergeStoryIds([[3, 2, 1], [2, 4], [4, 5]])).toEqual([3, 2, 1, 4, 5]);
  });

  it('preserves HN rank by default after trimming dead items', () => {
    const items = [
      { ...story(1, 10, 100), hnRank: 1 },
      { ...story(2, 20, 50), hnRank: 0 },
      { ...story(3, 20, 200), hnRank: 2 },
      { ...story(4, 100, 400), dead: true, hnRank: 3 },
    ];

    expect(buildFeed(items, {}, new Date('2026-04-30T14:00:00Z'), { maxItems: 2 }).map((item) => item.id)).toEqual([2, 1]);
  });

  it('sorts by newest when requested', () => {
    const items = [
      { ...story(1, 10, 100), hnRank: 2 },
      { ...story(2, 20, 50), hnRank: 1 },
      { ...story(3, 20, 200), hnRank: 0 },
    ];

    expect(buildFeed(items, {}, new Date('2026-04-30T14:00:00Z'), { sortBy: 'newest' }).map((item) => item.id)).toEqual([3, 1, 2]);
  });

  it('prioritizes matching source rank when sorting by Ask', () => {
    const items = [
      { ...story(1, 10, 100), hnRank: 0, sourceRanks: { top: 0 } },
      { ...story(2, 20, 50), hnRank: 1, sourceRanks: { ask: 1, top: 5 } },
      { ...story(3, 20, 200), hnRank: 2, sourceRanks: { ask: 0 } },
    ];

    expect(buildFeed(items, {}, new Date('2026-04-30T14:00:00Z'), { sortBy: 'ask' }).map((item) => item.id)).toEqual([3, 2, 1]);
  });

  it('keeps seen-but-unexpired stories visible and hides tapped stories', () => {
    const now = new Date('2026-04-30T14:00:00Z');
    const ledger: SeenLedger = {
      '1': { firstSeen: '2026-04-30T13:30:00Z', tapped: false },
      '2': { firstSeen: '2026-04-30T13:30:00Z', tapped: true, tappedAt: '2026-04-30T13:35:00Z' },
      '3': { firstSeen: '2026-04-30T12:00:00Z', tapped: false },
    };

    expect(buildFeed([story(1, 3, 1), story(2, 4, 2), story(3, 5, 3)], ledger, now, { maxItems: 10 }).map((item) => item.id)).toEqual([1]);
  });

  it('hides dismissed stories even when their seen TTL has not expired', () => {
    const now = new Date('2026-04-30T14:00:00Z');
    const ledger: SeenLedger = {
      '1': { firstSeen: '2026-04-30T13:59:00Z', tapped: false, dismissed: true, dismissedAt: '2026-04-30T13:59:30Z' },
    };

    expect(buildFeed([story(1, 100, 1)], ledger, now, { maxItems: 10 })).toEqual([]);
  });

  it('does not backfill capped feed items after stories are hidden', () => {
    const now = new Date('2026-04-30T14:00:00Z');
    const ledger: SeenLedger = {
      '1': { firstSeen: '2026-04-30T13:59:00Z', tapped: false, dismissed: true, dismissedAt: '2026-04-30T13:59:30Z' },
      '2': { firstSeen: '2026-04-30T13:59:00Z', tapped: true, tappedAt: '2026-04-30T13:59:30Z' },
    };

    expect(buildFeed([story(1, 100, 1), story(2, 90, 2), story(3, 80, 3), story(4, 70, 4)], ledger, now, { maxItems: 3 }).map((item) => item.id)).toEqual([
      3,
    ]);
  });

  it('returns every visible item when no limit is provided', () => {
    expect(buildFeed([story(1, 100, 1), story(2, 90, 2), story(3, 80, 3)], {}, new Date('2026-04-30T14:00:00Z')).map((item) => item.id)).toEqual([
      1,
      2,
      3,
    ]);
  });

  it('diffs fetched ids against the ledger for background refresh banners', () => {
    const ledger: SeenLedger = {
      '1': { firstSeen: '2026-04-30T13:00:00Z', tapped: false },
      '2': { firstSeen: '2026-04-30T13:00:00Z', tapped: true, tappedAt: '2026-04-30T13:05:00Z' },
    };

    expect(findNewIds([2, 3, 4, 1], ledger)).toEqual([3, 4]);
  });
});
