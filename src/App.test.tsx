import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { beforeEach, describe, expect, it, vi } from 'vitest';
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

describe('Hacker River app', () => {
  beforeEach(() => {
    localStorage.clear();
    sessionStorage.clear();
    vi.restoreAllMocks();
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
});
