import { describe, expect, it } from 'vitest';
import { cleanupLedger, markItemsSeen, markTapped, recentlyRead } from './ledger';
import type { HnItem, SeenLedger } from '../types';

const now = new Date('2026-04-30T14:00:00Z');
const item = (id: number): HnItem => ({ id, title: `Story ${id}`, type: 'story', time: 1 });

describe('seen ledger', () => {
  it('adds first-rendered items without resetting existing firstSeen timestamps', () => {
    const ledger: SeenLedger = {
      '1': { firstSeen: '2026-04-30T13:10:00Z', tapped: false },
    };

    expect(markItemsSeen(ledger, [item(1), item(2)], now)).toEqual({
      '1': { firstSeen: '2026-04-30T13:10:00Z', tapped: false },
      '2': { firstSeen: '2026-04-30T14:00:00.000Z', tapped: false },
    });
  });

  it('marks title taps without treating comment taps as reads', () => {
    const ledger = markTapped({}, 42, now);

    expect(ledger['42']).toEqual({
      firstSeen: '2026-04-30T14:00:00.000Z',
      tapped: true,
      tappedAt: '2026-04-30T14:00:00.000Z',
    });
  });

  it('purges untapped and tapped entries after their distinct TTLs', () => {
    const ledger: SeenLedger = {
      fresh: { firstSeen: '2026-04-30T13:30:00Z', tapped: false },
      ignored: { firstSeen: '2026-04-30T12:59:59Z', tapped: false },
      readFresh: { firstSeen: '2026-04-25T14:00:00Z', tapped: true, tappedAt: '2026-04-26T14:00:01Z' },
      readExpired: { firstSeen: '2026-04-20T14:00:00Z', tapped: true, tappedAt: '2026-04-25T13:59:59Z' },
    };

    expect(cleanupLedger(ledger, now)).toEqual({
      fresh: { firstSeen: '2026-04-30T13:30:00Z', tapped: false },
      readFresh: { firstSeen: '2026-04-25T14:00:00Z', tapped: true, tappedAt: '2026-04-26T14:00:01Z' },
    });
  });

  it('returns recently read stories sorted by tappedAt descending', () => {
    const ledger: SeenLedger = {
      '1': { firstSeen: '2026-04-30T13:00:00Z', tapped: true, tappedAt: '2026-04-30T13:10:00Z' },
      '2': { firstSeen: '2026-04-30T13:00:00Z', tapped: true, tappedAt: '2026-04-30T13:20:00Z' },
      '3': { firstSeen: '2026-04-30T13:00:00Z', tapped: false },
    };

    expect(recentlyRead([item(1), item(2), item(3)], ledger, now).map(({ item }) => item.id)).toEqual([2, 1]);
  });
});
