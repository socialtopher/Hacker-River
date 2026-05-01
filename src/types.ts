export type StorySource = 'top' | 'new' | 'ask' | 'show' | 'job';
export type SortBy = 'hnRank' | 'newest' | 'ask' | 'show' | 'job';

export type HnItem = {
  id: number;
  by?: string;
  descendants?: number;
  score?: number;
  time: number;
  title: string;
  type: string;
  url?: string;
  dead?: boolean;
  deleted?: boolean;
  hnRank?: number;
  sourceRanks?: Partial<Record<StorySource, number>>;
};

export type LedgerEntry = {
  firstSeen: string;
  tapped: boolean;
  tappedAt?: string;
  dismissed?: boolean;
  dismissedAt?: string;
};

export type SeenLedger = Record<string, LedgerEntry>;

export type Settings = {
  autoRefreshMinutes: number | 'off';
  sortBy: SortBy;
  unseenTtlMs: number;
  tappedTtlMs: number;
  sources: Record<StorySource, boolean>;
};
