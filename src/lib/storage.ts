import { DEFAULT_SETTINGS, SETTINGS_KEY } from './constants';
import type { Settings } from '../types';

export function readSettings(storage: Storage): Settings {
  try {
    const parsed = JSON.parse(storage.getItem(SETTINGS_KEY) ?? '{}');
    return {
      ...DEFAULT_SETTINGS,
      ...parsed,
      sources: { ...DEFAULT_SETTINGS.sources, ...parsed.sources },
    };
  } catch {
    return DEFAULT_SETTINGS;
  }
}

export function writeSettings(storage: Storage, settings: Settings) {
  storage.setItem(SETTINGS_KEY, JSON.stringify(settings));
}
