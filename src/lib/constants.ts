import type { Settings } from '../types';

export const LEDGER_KEY = 'hackerriver_ledger';
export const SETTINGS_KEY = 'hackerriver_settings';
export const ITEM_CACHE_PREFIX = 'hackerriver_item_';

export const HOUR_MS = 60 * 60 * 1000;
export const DAY_MS = 24 * HOUR_MS;

export const DEFAULT_SETTINGS: Settings = {
  autoRefreshMinutes: 5,
  unseenTtlMs: HOUR_MS,
  tappedTtlMs: 5 * DAY_MS,
  sources: {
    top: true,
    new: true,
    ask: true,
    show: true,
    job: true,
  },
  maxItems: 300,
};
