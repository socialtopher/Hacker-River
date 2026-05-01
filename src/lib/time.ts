export function ageMs(iso: string, now: Date): number {
  return now.getTime() - new Date(iso).getTime();
}

export function timeAgo(unixSecondsOrIso: number | string, now = new Date()): string {
  const then = typeof unixSecondsOrIso === 'number' ? unixSecondsOrIso * 1000 : new Date(unixSecondsOrIso).getTime();
  const seconds = Math.max(0, Math.floor((now.getTime() - then) / 1000));

  if (seconds < 60) return 'now';
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes}m`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h`;
  const days = Math.floor(hours / 24);
  if (days < 30) return `${days}d`;
  const months = Math.floor(days / 30);
  if (months < 12) return `${months}mo`;
  return `${Math.floor(months / 12)}y`;
}

export function domainFromUrl(url?: string): string {
  if (!url) return 'news.ycombinator.com';

  try {
    const host = new URL(url).hostname.replace(/^www\./, '');
    return host;
  } catch {
    return 'news.ycombinator.com';
  }
}
