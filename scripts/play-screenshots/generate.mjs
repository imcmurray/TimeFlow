// Renders the Google Play phone screenshots (1080×1920, 9:16) from the
// release web build. Run through ../generate_play_screenshots.sh, which builds
// the web app and provides Chromium (Playwright) in Docker.
import { chromium } from 'playwright';
import http from 'http';
import fs from 'fs';
import path from 'path';
import zlib from 'zlib';

const root = '/web';
const types = { '.js': 'text/javascript', '.wasm': 'application/wasm', '.html': 'text/html', '.json': 'application/json', '.png': 'image/png', '.ttf': 'font/ttf', '.otf': 'font/otf' };
const server = http.createServer((req, res) => {
  let p = decodeURIComponent(req.url.split('?')[0]);
  if (p === '/') p = '/index.html';
  fs.readFile(path.join(root, p), (err, data) => {
    if (err) { res.writeHead(404); res.end(); return; }
    res.writeHead(200, { 'Content-Type': types[path.extname(p)] || 'application/octet-stream' });
    res.end(data);
  });
}).listen(8080);

const out = '/work/out';
fs.mkdirSync(out, { recursive: true });
const browser = await chromium.launch();
// 360x640 CSS px at 3x = 1080x1920. Play rejects screenshots longer than
// twice their width, and recommends 9:16 at 1080 px or more.
const W = 360, H = 640;
const now = new Date('2026-10-05T10:20:00-06:00');
const pad = n => String(n).padStart(2, '0');
const day = (off) => { const d = new Date(2026, 9, 5 + off); return d; };
const at = (d, h, m) => `${d.getFullYear()}-${pad(d.getMonth()+1)}-${pad(d.getDate())}T${pad(h)}:${pad(m)}:00.000`;
const iso = new Date('2026-10-01T12:00:00Z').toISOString();
const t = (id, title, d, h, m, mins, extra = {}) => {
  const end = new Date(d); end.setHours(h, m + mins);
  return { id, title, startTime: at(d, h, m), endTime: at(end, end.getHours(), end.getMinutes()),
    isImportant: false, isCompleted: false, category: 'none', createdAt: iso, updatedAt: iso, ...extra };
};
const d0 = day(0), d1 = day(1);
const tasks = [
  t('a', 'Morning walk with Biscuit', d0, 7, 0, 45, { category: 'health', isCompleted: true }),
  t('b', 'Breakfast & meds', d0, 8, 0, 20, { category: 'health', isCompleted: true, notes: 'Half a pill in peanut butter' }),
  t('c', 'Deep work: grant proposal', d0, 9, 0, 120, { category: 'deepWork' }),
  t('d', 'Team check-in', d0, 11, 30, 30, { category: 'meeting', reminderMinutes: 10 }),
  t('e', 'Lunch with Sam', d0, 12, 15, 60, { category: 'family', reminderMinutes: 15 }),
  t('f', 'Pick up dry cleaning', d0, 14, 0, 30, { category: 'personal', isImportant: true }),
  t('g', 'Biscuit to the vet', d0, 15, 30, 60, { category: 'health', isImportant: true, reminderMinutes: 30 }),
  t('h', 'Yoga', d0, 18, 0, 60, { category: 'health' }),
  t('i', 'Read', d0, 21, 0, 45, { category: 'learning' }),
  t('j', 'Morning walk with Biscuit', d1, 7, 0, 45, { category: 'health' }),
];

async function newPage(seed, fragment = '') {
  const ctx = await browser.newContext({ viewport: { width: W, height: H }, deviceScaleFactor: 3, timezoneId: 'America/Denver', colorScheme: 'light' });
  const page = await ctx.newPage();
  await page.clock.install({ time: now });
  if (seed) {
    await page.addInitScript(([tasks]) => {
      if (sessionStorage.getItem('seeded')) return;
      sessionStorage.setItem('seeded', '1');
      localStorage.setItem('flutter.timeflow_first_launch', 'false');
      localStorage.setItem('flutter.timeflow_has_seen_longpress_hint', 'true');
      localStorage.setItem('flutter.timeflow_tasks', JSON.stringify(JSON.stringify(tasks)));
    }, [tasks]);
  }
  await page.goto('http://localhost:8080/' + fragment);
  await page.clock.runFor(9000);
  await page.waitForTimeout(6000);
  // Turn on Flutter's accessibility tree so buttons can be found by name.
  await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
  await page.waitForTimeout(500);
  page.setDefaultTimeout(10000);
  return { ctx, page };
}
const button = (page, name) => page.getByRole('button', { name }).first();

let { ctx, page } = await newPage(true);
await page.screenshot({ path: `${out}/1-timeline.png` });
await button(page, /add|new task/i).click();
await page.waitForTimeout(2500);
await page.keyboard.type('Biscuit to the groomer');
await page.waitForTimeout(800);
await page.screenshot({ path: `${out}/3-new-task.png` });
await page.goBack().catch(() => {});
await ctx.close();

({ ctx, page } = await newPage(true));
await button(page, /share/i).click();
await page.waitForTimeout(2500);
await page.screenshot({ path: `${out}/5-share.png` });
await ctx.close();

// Settings → Categories, with usage counts from the seeded tasks.
({ ctx, page } = await newPage(true));
await button(page, /settings/i).click();
await page.waitForTimeout(1500);
await page.mouse.move(180, 400);
for (let i = 0; i < 30 && !(await page.getByText('Add, rename, recolour or remove').count()); i++) {
  await page.mouse.wheel(0, 300);
  await page.waitForTimeout(300);
}
await page.getByText('Add, rename, recolour or remove').first().click();
await page.waitForTimeout(2000);
await page.mouse.move(180, 12); // off the list, so no row shows a hover tint
await page.waitForTimeout(500);
await page.screenshot({ path: `${out}/4-categories.png` });
await ctx.close();

const json = JSON.stringify({ v: 1, n: "Biscuit's day", t: [
  ['Breakfast', '202610050800', 20, 0, 4, '1/2 cup kibble', 'Half a pill in peanut butter'],
  ['Walk around the park', '202610051000', 45, 1, 4, '', 'He pulls toward squirrels'],
  ['Lunch snack', '202610051230', 15, 0, 4, '', ''],
  ['Play time', '202610051500', 30, 0, 4, '', ''],
  ['Dinner', '202610051730', 20, 0, 4, '', ''],
  ['Evening walk', '202610051900', 30, 0, 4, '', ''],
]});
const data = zlib.deflateSync(Buffer.from(json)).toString('base64url');
({ ctx, page } = await newPage(false, '#/s/' + data));
await page.screenshot({ path: `${out}/6-shared-link.png` });
await ctx.close();

{
  const c = await browser.newContext({ viewport: { width: W, height: H }, deviceScaleFactor: 3, timezoneId: 'America/Denver' });
  const p = await c.newPage();
  await p.clock.install({ time: now });
  await p.goto('http://localhost:8080/');
  await p.clock.runFor(9000);
  await p.waitForTimeout(6000);
  await p.screenshot({ path: `${out}/2-welcome.png` });
  await c.close();
}

await browser.close();
server.close();
