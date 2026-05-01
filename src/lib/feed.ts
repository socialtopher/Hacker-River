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
  maxItems = 300,
  unseenTtlMs = HOUR_MS,
): HnItem[] {
  return items
    .filter((item) => item && !item.dead && !item.deleted && item.type === 'story' && item.title)
    .filter((item) => isUntappedVisible(ledger[String(item.id)], now, unseenTtlMs))
    .sort((a, b) => (b.score ?? 0) - (a.score ?? 0) || b.time - a.time)
    .slice(0, maxItems);
}

export function findNewIds(ids: number[], ledger: SeenLedger): number[] {
  return ids.filter((id) => !ledger[String(id)]);
}
