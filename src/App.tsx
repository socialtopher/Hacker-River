import { useCallback, useEffect, useMemo, useState } from 'react';
import { DEFAULT_SETTINGS, LEDGER_KEY } from './lib/constants';
import { buildFeed, findNewIds } from './lib/feed';
import { fetchStoryIds, fetchStoryItems } from './lib/hnApi';
import { cleanupLedger, markDismissed, markItemsSeen, markTapped, readLedger, recentlyRead, writeLedger } from './lib/ledger';
import { readSettings, writeSettings } from './lib/storage';
import { domainFromUrl, timeAgo } from './lib/time';
import type { HnItem, SeenLedger, Settings, StorySource } from './types';
import './styles.css';

type Status = 'idle' | 'loading' | 'refreshing' | 'error';
const PAGE_SIZE = 30;

const SOURCE_LABELS: Record<StorySource, string> = {
  top: 'Top',
  new: 'New',
  ask: 'Ask',
  show: 'Show',
  job: 'Jobs',
};

function commentsUrl(id: number) {
  return `https://news.ycombinator.com/item?id=${id}`;
}

export default function App() {
  const [settings, setSettings] = useState<Settings>(() => readSettings(localStorage));
  const [ledger, setLedger] = useState<SeenLedger>(() =>
    cleanupLedger(readLedger(localStorage), new Date(), settings.unseenTtlMs, settings.tappedTtlMs),
  );
  const [items, setItems] = useState<HnItem[]>([]);
  const [status, setStatus] = useState<Status>('idle');
  const [message, setMessage] = useState('');
  const [pendingNew, setPendingNew] = useState(0);
  const [readOpen, setReadOpen] = useState(false);
  const [settingsOpen, setSettingsOpen] = useState(false);
  const [copiedId, setCopiedId] = useState<number | null>(null);

  const persistLedger = useCallback((next: SeenLedger) => {
    setLedger(next);
    writeLedger(localStorage, next);
  }, []);

  const loadFeed = useCallback(
    async (mode: 'initial' | 'manual' | 'background' = 'manual') => {
      const now = new Date();
      const cleaned = cleanupLedger(readLedger(localStorage), now, settings.unseenTtlMs, settings.tappedTtlMs);
      persistLedger(cleaned);

      if (mode === 'background') {
        const ids = await fetchStoryIds(settings);
        setPendingNew(findNewIds(ids, cleaned).length);
        return;
      }

      setStatus(mode === 'initial' ? 'loading' : 'refreshing');
      setMessage('');
      try {
        const ids = await fetchStoryIds(settings);
        const fetched = await fetchStoryItems(ids, settings.maxItems);
        const feed = buildFeed(fetched, cleaned, now, settings.maxItems, settings.unseenTtlMs);
        const nextLedger = markItemsSeen(cleaned, feed, now);
        persistLedger(nextLedger);
        setItems(fetched);
        setPendingNew(0);
        setStatus('idle');
      } catch {
        setStatus('error');
        setMessage('HN is slow right now. Try refreshing again.');
      }
    },
    [persistLedger, settings],
  );

  useEffect(() => {
    writeLedger(localStorage, ledger);
  }, [ledger]);

  useEffect(() => {
    writeSettings(localStorage, settings);
  }, [settings]);

  useEffect(() => {
    void loadFeed('initial');
  }, [loadFeed]);

  useEffect(() => {
    if (settings.autoRefreshMinutes === 'off') return;
    const timer = window.setInterval(() => {
      void loadFeed('background');
    }, settings.autoRefreshMinutes * 60 * 1000);
    return () => window.clearInterval(timer);
  }, [loadFeed, settings.autoRefreshMinutes]);

  useEffect(() => {
    const onStorage = (event: StorageEvent) => {
      if (event.key === LEDGER_KEY) setLedger(cleanupLedger(readLedger(localStorage), new Date()));
    };
    window.addEventListener('storage', onStorage);
    return () => window.removeEventListener('storage', onStorage);
  }, []);

  const now = useMemo(() => new Date(), [ledger, items]);
  const feed = useMemo(
    () => buildFeed(items, ledger, now, settings.maxItems, settings.unseenTtlMs),
    [items, ledger, now, settings.maxItems, settings.unseenTtlMs],
  );
  const readItems = useMemo(() => recentlyRead(items, ledger, now, settings.tappedTtlMs), [items, ledger, now, settings.tappedTtlMs]);
  const visibleFeed = feed.slice(0, PAGE_SIZE);

  function openStory(item: HnItem, event?: React.MouseEvent<HTMLAnchorElement>) {
    event?.preventDefault();
    persistLedger(markTapped(ledger, item.id));
    window.open(item.url ?? commentsUrl(item.id), '_blank', 'noopener,noreferrer');
  }

  function dismissStory(item: HnItem) {
    persistLedger(markDismissed(ledger, item.id));
  }

  function nextPage() {
    const now = new Date();
    const nextLedger = visibleFeed.reduce((current, item) => markDismissed(current, item.id, now), ledger);
    persistLedger(nextLedger);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  async function shareStory(item: HnItem) {
    try {
      await navigator.clipboard.writeText(item.url ?? commentsUrl(item.id));
      setCopiedId(item.id);
      setMessage('Link copied.');
      window.setTimeout(() => setCopiedId((current) => (current === item.id ? null : current)), 3000);
    } catch {
      setMessage('Could not copy link.');
    }
  }

  function updateSettings(next: Settings) {
    setSettings(next);
    writeSettings(localStorage, next);
  }

  return (
    <main className="shell">
      <header className="topbar">
        <h1>Hacker River</h1>
        <div className="toolbar">
          <button className="icon-button" onClick={() => void loadFeed('manual')} aria-label="Refresh" title="Refresh">
            {status === 'refreshing' || status === 'loading' ? '...' : '↻'}
          </button>
          <button className="icon-button" onClick={() => setSettingsOpen((open) => !open)} aria-label="Settings" title="Settings">
            ⚙
          </button>
        </div>
      </header>

      {settingsOpen && <SettingsPanel settings={settings} onChange={updateSettings} />}

      {pendingNew > 0 && (
        <button className="new-banner" onClick={() => void loadFeed('manual')}>
          ● {pendingNew} new {pendingNew === 1 ? 'post' : 'posts'} - tap to load
        </button>
      )}

      {message && <p className="toast">{message}</p>}
      {status === 'loading' && <p className="empty">Fetching the river...</p>}

      <ol className="feed">
        {visibleFeed.map((item) => (
          <li className="post" key={item.id}>
            <button className="dismiss-button" onClick={() => dismissStory(item)} aria-label={`Dismiss ${item.title}`} title="Dismiss">
              ✓
            </button>
            <div className="post-body">
              <a className="title-link" href={item.url ?? commentsUrl(item.id)} onClick={(event) => openStory(item, event)}>
                <span>{item.title}</span> <span className="domain">({domainFromUrl(item.url)})</span>
              </a>
              <div className="meta">
                {item.score ?? 0} pts · {item.by ?? 'unknown'} · {timeAgo(item.time, now)} ·{' '}
                <a href={commentsUrl(item.id)} target="_blank" rel="noreferrer">
                  {item.descendants ?? 0} cmnts
                </a>{' '}
                ·{' '}
                <button className="meta-button" onClick={() => void shareStory(item)} aria-label={`Share ${item.title}`}>
                  {copiedId === item.id ? 'Copied!' : 'Share'}
                </button>
              </div>
            </div>
          </li>
        ))}
      </ol>

      {feed.length > PAGE_SIZE && (
        <div className="pager">
          <button className="more-button" onClick={nextPage}>
            More
          </button>
        </div>
      )}

      {status !== 'loading' && feed.length === 0 && <p className="empty">Nothing fresh right now.</p>}

      <section className="recent">
        <button className="recent-toggle" onClick={() => setReadOpen((open) => !open)}>
          {readOpen ? '▾' : '▸'} Recently Read ({readItems.length})
        </button>
        {readOpen && (
          <ol className="recent-list">
            {readItems.map(({ item, entry }) => (
              <li key={item.id}>
                <a href={item.url ?? commentsUrl(item.id)} target="_blank" rel="noreferrer">
                  {item.title}
                </a>{' '}
                <span>· read {timeAgo(entry.tappedAt ?? entry.firstSeen, now)} ago</span>
              </li>
            ))}
          </ol>
        )}
      </section>
    </main>
  );
}

function SettingsPanel({ settings, onChange }: { settings: Settings; onChange: (settings: Settings) => void }) {
  return (
    <section className="settings" aria-label="Settings panel">
      <label>
        Auto-refresh
        <select
          value={settings.autoRefreshMinutes}
          onChange={(event) =>
            onChange({
              ...settings,
              autoRefreshMinutes: event.target.value === 'off' ? 'off' : Number(event.target.value),
            })
          }
        >
          <option value={1}>1 min</option>
          <option value={5}>5 min</option>
          <option value={15}>15 min</option>
          <option value={30}>30 min</option>
          <option value="off">Off</option>
        </select>
      </label>

      <label>
        Max items
        <select value={settings.maxItems} onChange={(event) => onChange({ ...settings, maxItems: Number(event.target.value) })}>
          {[100, 200, 300, 500].map((value) => (
            <option key={value} value={value}>
              {value}
            </option>
          ))}
        </select>
      </label>

      <div className="source-grid" role="group" aria-label="Feed sources">
        {(Object.keys(DEFAULT_SETTINGS.sources) as StorySource[]).map((source) => (
          <label key={source}>
            <input
              type="checkbox"
              checked={settings.sources[source]}
              onChange={(event) =>
                onChange({
                  ...settings,
                  sources: { ...settings.sources, [source]: event.target.checked },
                })
              }
            />
            {SOURCE_LABELS[source]}
          </label>
        ))}
      </div>
    </section>
  );
}
