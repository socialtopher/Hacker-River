import { HOUR_MS } from './constants';
import { isUntappedVisible } from './ledger';
import type { HnItem, SeenLedger, SortBy, StorySource } from '../types';

type BuildFeedOptions = {
  maxItems?: number;
  sortBy?: SortBy;
  unseenTtlMs?: number;
};

function compareByHnRank(a: HnItem, b: HnItem) {
  return (a.hnRank ?? Number.MAX_SAFE_INTEGER) - (b.hnRank ?? Number.MAX_SAFE_INTEGER);
}

function compareBySourceRank(source: StorySource, a: HnItem, b: HnItem) {
  const sourceRankA = a.sourceRanks?.[source];
  const sourceRankB = b.sourceRanks?.[source];

  if (sourceRankA !== undefined && sourceRankB !== undefined) return sourceRankA - sourceRankB;
  if (sourceRankA !== undefined) return -1;
  if (sourceRankB !== undefined) return 1;
  return compareByHnRank(a, b);
}

function sortFeedItems(items: HnItem[], sortBy: SortBy): HnItem[] {
  if (sortBy === 'newest') {
    return [...items].sort((a, b) => b.time - a.time || compareByHnRank(a, b));
  }

  if (sortBy === 'ask' || sortBy === 'show' || sortBy === 'job') {
    return [...items].sort((a, b) => compareBySourceRank(sortBy, a, b));
  }

  return [...items].sort(compareByHnRank);
}

export function mergeStoryIds(idGroups: number[][]): number[] {
  const seen = new Set<number>();
  const merged: number[] = [];

  for (const ids of idGroups) {
    for (const id of ids) {
      if (!seen.has(id)) {
        seen.add(id);
        merged.push(id);
      }
    }
  }

  return merged;
}

export function buildFeed(
  items: HnItem[],
  ledger: SeenLedger,
  now = new Date(),
  options: BuildFeedOptions = {},
): HnItem[] {
  const { maxItems, sortBy = 'hnRank', unseenTtlMs = HOUR_MS } = options;
  const sorted = sortFeedItems(
    items.filter((item) => item && !item.dead && !item.deleted && item.type === 'story' && item.title),
    sortBy,
  );
  const capped = maxItems === undefined ? sorted : sorted.slice(0, maxItems);

  return capped.filter((item) => isUntappedVisible(ledger[String(item.id)], now, unseenTtlMs));
}

export function findNewIds(ids: number[], ledger: SeenLedger): number[] {
  return ids.filter((id) => !ledger[String(id)]);
}
