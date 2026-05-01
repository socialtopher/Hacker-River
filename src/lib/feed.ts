import { HOUR_MS } from './constants';
import { isUntappedVisible } from './ledger';
import type { HnItem, SeenLedger } from '../types';

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
  maxItems?: number,
  unseenTtlMs = HOUR_MS,
): HnItem[] {
  const sorted = items
    .filter((item) => item && !item.dead && !item.deleted && item.type === 'story' && item.title)
    .sort((a, b) => (b.score ?? 0) - (a.score ?? 0) || b.time - a.time);
  const capped = maxItems === undefined ? sorted : sorted.slice(0, maxItems);

  return capped
    .filter((item) => isUntappedVisible(ledger[String(item.id)], now, unseenTtlMs));
}

export function findNewIds(ids: number[], ledger: SeenLedger): number[] {
  return ids.filter((id) => !ledger[String(id)]);
}
