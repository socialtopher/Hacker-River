import { ITEM_CACHE_PREFIX } from './constants';
import { mergeStoryIds } from './feed';
import type { HnItem, Settings, StorySource } from '../types';

const BASE_URL = 'https://hacker-news.firebaseio.com/v0';
type StoryMetadataById = Record<number, Pick<HnItem, 'hnRank' | 'sourceRanks'>>;

const ENDPOINTS: Record<StorySource, string> = {
  top: 'topstories',
  new: 'newstories',
  ask: 'askstories',
  show: 'showstories',
  job: 'jobstories',
};

async function fetchJson<T>(url: string, retries = 2): Promise<T> {
  const response = await fetch(url);
  if ((response.status === 429 || response.status >= 500) && retries > 0) {
    await new Promise((resolve) => setTimeout(resolve, 300 * (3 - retries)));
    return fetchJson<T>(url, retries - 1);
  }
  if (!response.ok) throw new Error(`HN request failed: ${response.status}`);
  return response.json() as Promise<T>;
}

async function fetchItem(id: number): Promise<HnItem | null> {
  const cacheKey = `${ITEM_CACHE_PREFIX}${id}`;
  const cached = sessionStorage.getItem(cacheKey);
  if (cached) return JSON.parse(cached) as HnItem;

  const item = await fetchJson<HnItem | null>(`${BASE_URL}/item/${id}.json`);
  if (item) sessionStorage.setItem(cacheKey, JSON.stringify(item));
  return item;
}

export async function fetchStoryPlan(settings: Settings): Promise<{ ids: number[]; metadataById: StoryMetadataById }> {
  const enabledSources = (Object.keys(settings.sources) as StorySource[]).filter((source) => settings.sources[source]);
  const sourceEntries = await Promise.all(
    enabledSources.map(async (source) => [source, await fetchJson<number[]>(`${BASE_URL}/${ENDPOINTS[source]}.json`)] as const),
  );
  const groups = sourceEntries.map(([, ids]) => ids);
  const ids = mergeStoryIds(groups);
  const metadataById: StoryMetadataById = {};

  ids.forEach((id, hnRank) => {
    metadataById[id] = { hnRank, sourceRanks: {} };
  });

  sourceEntries.forEach(([source, sourceIds]) => {
    sourceIds.forEach((id, sourceRank) => {
      if (!metadataById[id]) metadataById[id] = { hnRank: Number.MAX_SAFE_INTEGER, sourceRanks: {} };
      metadataById[id].sourceRanks = { ...metadataById[id].sourceRanks, [source]: sourceRank };
    });
  });

  return { ids, metadataById };
}

export async function fetchStoryIds(settings: Settings): Promise<number[]> {
  const { ids } = await fetchStoryPlan(settings);
  return ids;
}

export async function fetchStoryItems(ids: number[], metadataById: StoryMetadataById = {}): Promise<HnItem[]> {
  const selected = ids;
  const chunks: number[][] = [];
  for (let index = 0; index < selected.length; index += 50) {
    chunks.push(selected.slice(index, index + 50));
  }

  const items: HnItem[] = [];
  for (const chunk of chunks) {
    const results = await Promise.all(
      chunk.map(async (id) => {
        try {
          return await fetchItem(id);
        } catch {
          return null;
        }
      }),
    );
    for (const item of results) {
      if (item) items.push({ ...item, ...metadataById[item.id] });
    }
  }
  return items;
}
