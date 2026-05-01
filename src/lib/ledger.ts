import { HOUR_MS, DAY_MS } from './constants';
import { ageMs } from './time';
import type { HnItem, LedgerEntry, SeenLedger } from '../types';

export function isUntappedVisible(entry: LedgerEntry | undefined, now: Date, unseenTtlMs = HOUR_MS): boolean {
  if (!entry) return true;
  if (entry.dismissed) return false;
  return !entry.tapped && ageMs(entry.firstSeen, now) < unseenTtlMs;
}

export function isTappedVisible(entry: LedgerEntry | undefined, now: Date, tappedTtlMs = 5 * DAY_MS): boolean {
  if (!entry?.tapped || !entry.tappedAt) return false;
  return ageMs(entry.tappedAt, now) < tappedTtlMs;
}

export function cleanupLedger(
  ledger: SeenLedger,
  now = new Date(),
  unseenTtlMs = HOUR_MS,
  tappedTtlMs = 5 * DAY_MS,
): SeenLedger {
  return Object.fromEntries(
    Object.entries(ledger).filter(([, entry]) => {
      if (entry.dismissed) return true;
      if (entry.tapped) return isTappedVisible(entry, now, tappedTtlMs);
      return ageMs(entry.firstSeen, now) < unseenTtlMs;
    }),
  );
}

export function markItemsSeen(ledger: SeenLedger, items: HnItem[], now = new Date()): SeenLedger {
  const next = { ...ledger };
  for (const item of items) {
    const key = String(item.id);
    next[key] ??= { firstSeen: now.toISOString(), tapped: false };
  }
  return next;
}

export function markTapped(ledger: SeenLedger, id: number, now = new Date()): SeenLedger {
  const key = String(id);
  return {
    ...ledger,
    [key]: {
      firstSeen: ledger[key]?.firstSeen ?? now.toISOString(),
      tapped: true,
      tappedAt: now.toISOString(),
    },
  };
}

export function markDismissed(ledger: SeenLedger, id: number, now = new Date()): SeenLedger {
  const key = String(id);
  return {
    ...ledger,
    [key]: {
      firstSeen: ledger[key]?.firstSeen ?? now.toISOString(),
      tapped: false,
      dismissed: true,
      dismissedAt: now.toISOString(),
    },
  };
}

export function recentlyRead(items: HnItem[], ledger: SeenLedger, now = new Date(), tappedTtlMs = 5 * DAY_MS) {
  return items
    .map((item) => ({ item, entry: ledger[String(item.id)] }))
    .filter(({ entry }) => isTappedVisible(entry, now, tappedTtlMs))
    .sort((a, b) => new Date(b.entry.tappedAt ?? 0).getTime() - new Date(a.entry.tappedAt ?? 0).getTime());
}

export function readLedger(storage: Storage): SeenLedger {
  try {
    const parsed = JSON.parse(storage.getItem('hackerriver_ledger') ?? '{}');
    return parsed && typeof parsed === 'object' ? parsed : {};
  } catch {
    return {};
  }
}

export function writeLedger(storage: Storage, ledger: SeenLedger) {
  storage.setItem('hackerriver_ledger', JSON.stringify(ledger));
}
