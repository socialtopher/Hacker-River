import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

describe('styles.css', () => {
  it('keeps feed metadata on the Hacker News font stack', () => {
    const css = readFileSync(resolve(process.cwd(), 'src/styles.css'), 'utf8');

    expect(css).toContain('font-family: Verdana, Geneva, sans-serif;');
    expect(css).not.toContain('font-family: ui-monospace');
  });
});
