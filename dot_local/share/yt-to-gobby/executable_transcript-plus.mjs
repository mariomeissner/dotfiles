#!/usr/bin/env node
import { fetchTranscript } from 'youtube-transcript-plus';

function argValue(name, fallback = '') {
  const i = process.argv.indexOf(name);
  return i >= 0 && i + 1 < process.argv.length ? process.argv[i + 1] : fallback;
}
function hasFlag(name) {
  return process.argv.includes(name);
}
function timestamp(seconds) {
  const n = Math.max(0, Number(seconds || 0));
  const h = Math.floor(n / 3600);
  const m = Math.floor((n % 3600) / 60);
  const s = Math.floor(n % 60);
  return h > 0
    ? `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`
    : `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
}
function cleanText(text, keepBrackets) {
  let s = String(text || '')
    .replace(/<[^>]+>/g, '')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/\s+/g, ' ')
    .trim();
  if (!keepBrackets) s = s.replace(/\s*\[[^\]]+\]\s*/g, ' ').replace(/\s+/g, ' ').trim();
  return s;
}

const url = argValue('--url');
if (!url) {
  console.error('missing --url');
  process.exit(2);
}
const lang = argValue('--lang', 'en');
const timestamps = hasFlag('--timestamps');
const keepBrackets = hasFlag('--keep-brackets');

try {
  const result = await fetchTranscript(url, { lang, retries: 1, retryDelay: 750 });
  const items = Array.isArray(result) ? result : (result?.transcript || result?.items || []);
  if (!Array.isArray(items) || items.length === 0) throw new Error('empty transcript');

  const chunks = [];
  let last = '';
  for (const item of items) {
    const text = cleanText(item.text ?? item.snippet ?? item.content ?? '', keepBrackets);
    if (!text || text === last) continue;
    if (timestamps) {
      const start = item.offset ?? item.start ?? item.startTime ?? 0;
      chunks.push(`[${timestamp(start)}] ${text}`);
    } else {
      chunks.push(text);
    }
    last = text;
  }
  const body = timestamps ? chunks.join('\n') : chunks.join(' ').replace(/\s+/g, ' ').trim();
  if (!body) throw new Error('empty transcript after cleaning');
  console.log(body);
} catch (err) {
  console.error(err?.message || String(err));
  process.exit(1);
}
