import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

describe('index.html', () => {
  it('registers the SVG favicon', () => {
    const html = readFileSync(resolve(process.cwd(), 'index.html'), 'utf8');

    expect(html).toContain('<link rel="icon" type="image/svg+xml" href="/favicon.svg" />');
  });
});
