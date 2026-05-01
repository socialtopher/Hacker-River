import { act, fireEvent, render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import App from './App';
import type { HnItem } from './types';

const response = (body: unknown) => Promise.resolve(new Response(JSON.stringify(body)));
const item = (id: number, title: string, score: number): HnItem => ({
  id,
  title,
  score,
  time: 1777557600,
  type: 'story',
  by: 'pg',
  descendants: 7,
  url: `https://example.com/${id}`,
});

function mockFeed(count: number) {
  vi.stubGlobal(
    'fetch',
    vi.fn((url: string) => {
      if (url.includes('topstories')) return response(Array.from({ length: count }, (_, index) => index + 1));
      if (url.includes('newstories')) return response([]);
      if (url.includes('askstories')) return response([]);
      if (url.includes('showstories')) return response([]);
      if (url.includes('jobstories')) return response([]);
      const match = url.match(/\/item\/(\d+)\.json/);
      if (match) {
        const id = Number(match[1]);
        return response(item(id, `Story ${id}`, 1000 - id));
      }
      return Promise.reject(new Error(`Unexpected URL ${url}`));
    }),
  );
}

describe('Hacker River app', () => {
  beforeEach(() => {
    localStorage.clear();
    sessionStorage.clear();
    vi.restoreAllMocks();
    vi.useRealTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('renders fetched stories and records first render in the ledger', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn((url: string) => {
        if (url.includes('topstories')) return response([1]);
        if (url.includes('newstories')) return response([]);
        if (url.includes('askstories')) return response([]);
        if (url.includes('showstories')) return response([]);
        if (url.includes('jobstories')) return response([]);
        if (url.includes('/item/1.json')) return response(item(1, 'A useful post', 88));
        return Promise.reject(new Error(`Unexpected URL ${url}`));
      }),
    );

    render(<App />);

    expect(await screen.findByRole('link', { name: /A useful post/ })).toBeInTheDocument();
    await waitFor(() => {
      const ledger = JSON.parse(localStorage.getItem('hackerriver_ledger') ?? '{}');
      expect(ledger['1'].tapped).toBe(false);
    });
  });

  it('moves title-clicked stories into Recently Read', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn((url: string) => {
        if (url.includes('topstories')) return response([1]);
        if (url.includes('newstories')) return response([]);
        if (url.includes('askstories')) return response([]);
        if (url.includes('showstories')) return response([]);
        if (url.includes('jobstories')) return response([]);
        if (url.includes('/item/1.json')) return response(item(1, 'Read me', 88));
        return Promise.reject(new Error(`Unexpected URL ${url}`));
      }),
    );
    vi.spyOn(window, 'open').mockImplementation(() => null);

    render(<App />);
    await userEvent.click(await screen.findByRole('link', { name: /Read me/ }));

    expect(window.open).toHaveBeenCalledWith('https://example.com/1', '_blank', 'noopener,noreferrer');
    expect(await screen.findByRole('button', { name: /Recently Read \(1\)/ })).toBeInTheDocument();
  });

  it('dismisses a story when its check control is clicked', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn((url: string) => {
        if (url.includes('topstories')) return response([1]);
        if (url.includes('newstories')) return response([]);
        if (url.includes('askstories')) return response([]);
        if (url.includes('showstories')) return response([]);
        if (url.includes('jobstories')) return response([]);
        if (url.includes('/item/1.json')) return response(item(1, 'Skip me', 88));
        return Promise.reject(new Error(`Unexpected URL ${url}`));
      }),
    );

    render(<App />);
    expect(await screen.findByRole('link', { name: /Skip me/ })).toBeInTheDocument();

    await userEvent.click(screen.getByRole('button', { name: /Dismiss Skip me/ }));

    expect(screen.queryByRole('link', { name: /Skip me/ })).not.toBeInTheDocument();
    const ledger = JSON.parse(localStorage.getItem('hackerriver_ledger') ?? '{}');
    expect(ledger['1'].dismissed).toBe(true);
  });

  it('copies the story URL when its Share link is clicked', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn((url: string) => {
        if (url.includes('topstories')) return response([1]);
        if (url.includes('newstories')) return response([]);
        if (url.includes('askstories')) return response([]);
        if (url.includes('showstories')) return response([]);
        if (url.includes('jobstories')) return response([]);
        if (url.includes('/item/1.json')) return response(item(1, 'Share me', 88));
        return Promise.reject(new Error(`Unexpected URL ${url}`));
      }),
    );
    const writeText = vi.fn().mockResolvedValue(undefined);
    Object.defineProperty(navigator, 'clipboard', {
      value: { writeText },
      configurable: true,
    });

    render(<App />);
    await screen.findByRole('link', { name: /Share me/ });
    await userEvent.click(screen.getByRole('button', { name: /Share Share me/ }));

    expect(writeText).toHaveBeenCalledWith('https://example.com/1');
    expect(screen.queryByText('Link copied.')).not.toBeInTheDocument();
  });

  it('shows Copied for 3 seconds after sharing', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn((url: string) => {
        if (url.includes('topstories')) return response([1]);
        if (url.includes('newstories')) return response([]);
        if (url.includes('askstories')) return response([]);
        if (url.includes('showstories')) return response([]);
        if (url.includes('jobstories')) return response([]);
        if (url.includes('/item/1.json')) return response(item(1, 'Copy state', 88));
        return Promise.reject(new Error(`Unexpected URL ${url}`));
      }),
    );
    Object.defineProperty(navigator, 'clipboard', {
      value: { writeText: vi.fn().mockResolvedValue(undefined) },
      configurable: true,
    });

    render(<App />);
    await screen.findByRole('link', { name: /Copy state/ });
    vi.useFakeTimers();
    fireEvent.click(screen.getByRole('button', { name: /Share Copy state/ }));
    await act(async () => {
      await Promise.resolve();
    });

    expect(screen.getByRole('button', { name: /Share Copy state/ })).toHaveTextContent('Copied!');

    act(() => {
      vi.advanceTimersByTime(3000);
    });

    expect(screen.getByRole('button', { name: /Share Copy state/ })).toHaveTextContent('Share');
  });

  it('shows only 30 feed items at a time', async () => {
    mockFeed(31);

    render(<App />);

    expect(await screen.findByRole('link', { name: 'Story 1 (example.com)' })).toBeInTheDocument();
    expect(screen.getByRole('link', { name: 'Story 30 (example.com)' })).toBeInTheDocument();
    expect(screen.queryByRole('link', { name: 'Story 31 (example.com)' })).not.toBeInTheDocument();
    expect(screen.getByRole('button', { name: /More/ })).toBeInTheDocument();
  });

  it('shows the unclicked and unhidden inbox count in the title', async () => {
    mockFeed(31);

    render(<App />);

    expect(await screen.findByRole('heading', { name: 'Hacker River (31)' })).toBeInTheDocument();
    vi.spyOn(window, 'open').mockImplementation(() => null);
    await userEvent.click(screen.getByRole('link', { name: 'Story 1 (example.com)' }));
    expect(screen.getByRole('heading', { name: 'Hacker River (30)' })).toBeInTheDocument();

    await userEvent.click(screen.getByRole('button', { name: 'Dismiss Story 2' }));
    expect(screen.getByRole('heading', { name: 'Hacker River (29)' })).toBeInTheDocument();
  });

  it('clears the current page when moving to the next page', async () => {
    mockFeed(31);

    render(<App />);
    expect(await screen.findByRole('link', { name: 'Story 1 (example.com)' })).toBeInTheDocument();

    await userEvent.click(screen.getByRole('button', { name: /More/ }));

    expect(screen.getByRole('heading', { name: 'Hacker River (1)' })).toBeInTheDocument();
    expect(screen.queryByRole('link', { name: 'Story 1 (example.com)' })).not.toBeInTheDocument();
    expect(screen.getByRole('link', { name: 'Story 31 (example.com)' })).toBeInTheDocument();
    const ledger = JSON.parse(localStorage.getItem('hackerriver_ledger') ?? '{}');
    expect(Array.from({ length: 30 }, (_, index) => ledger[String(index + 1)]?.dismissed)).toEqual(Array(30).fill(true));
  });
});
