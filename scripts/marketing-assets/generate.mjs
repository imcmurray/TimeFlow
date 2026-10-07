// Lays out the TimeFlow marketing and press kit with the app's Nunito font
// and the logo SVGs, and prints each design to a vector PDF. Run through
// ../generate_marketing_assets.sh, which provides Chromium (Playwright) in
// Docker and then rasterises every PDF to the PNG sizes listed here.
//
// Writes /work/pdf/<id>.pdf per design and /work/manifest.json:
//   [{ id, outputs: [{ path, w, h, dpi }] }]
import { chromium } from 'playwright';
import fs from 'fs';
import path from 'path';

const repo = '/repo';
const b64 = (f) => fs.readFileSync(path.join(repo, f)).toString('base64');
const font = b64('assets/fonts/Nunito.ttf');
const svgUrl = (text) => `data:image/svg+xml;base64,${Buffer.from(text).toString('base64')}`;
const read = (f) => fs.readFileSync(path.join(repo, f), 'utf8');

// Full-colour mark, and Ian's one-colour outline marks for single-ink print
// (the outline keeps the mark's two halves apart). Blue is the black outline
// mark with its ink swapped to AppColors.primaryInk.
const MARKS = {
  color: svgUrl(read('assets/branding/timeflow-logo.svg')),
  white: svgUrl(read('assets/branding/timeflow-logo-white.svg')),
  black: svgUrl(read('assets/branding/timeflow-logo-black.svg')),
  blue: svgUrl(read('assets/branding/timeflow-logo-black.svg').replaceAll('#000000', '#1a6fc8')),
};

const ink = '#1A6FC8';      // AppColors.primaryInk: wordmark text on light
const textDark = '#212121'; // body text colour on light backgrounds
const white = '#FFFFFF';
const black = '#000000';
const paper = '#FAFAFA';    // AppColors.backgroundLight
const night = '#121212';    // AppColors.backgroundDark

// Each layout is drawn at a reference size (mark = 100 px) and then scaled to
// fit its box, like the original AppKit generator.
const img = (mark) => `<img src="${MARKS[mark]}" style="width:100px;height:100px;display:block">`;
const LAYOUTS = {
  // Just the mark.
  mark: ({ mark = 'color' }) => ({ html: img(mark), nominal: () => [100, 100] }),
  // Mark + "TimeFlow" side by side: text at 0.62/0.72 of the mark height,
  // gap 0.28.
  wordmark: ({ mark = 'color', text }) => ({
    html: `<div style="display:flex;align-items:center">${img(mark)}
      <span style="margin-left:28px;font-weight:700;font-size:86.11px;line-height:1;letter-spacing:-0.01em;
        color:${text};white-space:nowrap;position:relative;top:-2px">TimeFlow</span></div>`,
    nominal: (w) => [w, 100],
  }),
  // Mark above "TimeFlow", optionally with the tagline.
  stacked: ({ mark = 'color', text, tagline = false, taglineColor }) => ({
    html: `<div style="display:flex;flex-direction:column;align-items:center;width:260px">${img(mark)}
      <span style="margin-top:12px;font-weight:700;font-size:46px;line-height:1.36;letter-spacing:-0.01em;color:${text}">TimeFlow</span>
      ${tagline ? `<span style="margin-top:2px;font-weight:600;font-size:16px;line-height:1.36;letter-spacing:-0.01em;
        color:${taglineColor ?? text};white-space:nowrap">Your day as a gentle river</span>` : ''}</div>`,
    nominal: () => [260, tagline ? 195 : 162],
  }),
};

const designs = [];
// id: PDF name. w×h: canvas aspect (CSS px). inset: fraction of each side
// left empty. bg: optional full-bleed background. outputs: PNGs to rasterise.
const add = (id, w, h, layout, opts, outputs, { inset = 0, bg } = {}) =>
  designs.push({ id, w, h, layout, opts, outputs, inset, bg });

const screen = (p, w, h) => ({ path: p, w, h, dpi: 72 });
// Print artwork at a fixed physical size, once per DPI into print/<dpi>dpi/.
const PRINT_DPIS = [300, 800, 1000, 1500];
const print = (name, wIn, hIn, dpis = PRINT_DPIS) => dpis.map((dpi) => {
  const w = Math.round(wIn * dpi), h = Math.round(hIn * dpi);
  return { path: `print/${dpi}dpi/${name}-${w}x${h}.png`, w, h, dpi };
});

// 1. Logo mark, transparent, screen and print sizes.
add('mark-color', 600, 600, 'mark', {}, [
  ...[256, 512, 1024, 2048, 4096].map((px) => screen(`logo/mark/timeflow-mark-${px}.png`, px, px)),
  ...print('mark-color-6x6in', 6, 6),
]);
for (const c of ['white', 'black', 'blue']) {
  add(`mark-${c}`, 600, 600, 'mark', { mark: c }, print(`mark-${c}-6x6in`, 6, 6));
}

// 2. Horizontal wordmark: on light, on dark, one-colour.
const wordmarkSizes = [[1200, 320], [2400, 640], [4800, 1280]];
add('wordmark-light', 1200, 320, 'wordmark', { text: ink }, [
  ...wordmarkSizes.map(([w, h]) => screen(`logo/wordmark/timeflow-wordmark-light-${w}.png`, w, h)),
], { inset: 0.04 });
add('wordmark-dark', 1200, 320, 'wordmark', { text: white },
  wordmarkSizes.map(([w, h]) => screen(`logo/wordmark/timeflow-wordmark-dark-${w}.png`, w, h)), { inset: 0.04 });
add('wordmark-color-print', 1200, 320, 'wordmark', { text: ink }, print('wordmark-color-12x3.2in', 12, 3.2), { inset: 0.04 });
add('wordmark-white-print', 1200, 320, 'wordmark', { text: white, mark: 'white' }, print('wordmark-white-12x3.2in', 12, 3.2), { inset: 0.04 });
add('wordmark-black-print', 1200, 320, 'wordmark', { text: black, mark: 'black' }, print('wordmark-black-12x3.2in', 12, 3.2), { inset: 0.04 });

// 3. Stacked lockup, with and without tagline.
for (const [name, opts] of [
  ['light', { text: ink }],
  ['dark', { text: white }],
  ['tagline-light', { text: ink, tagline: true, taglineColor: textDark }],
  ['tagline-dark', { text: white, tagline: true }],
]) {
  add(`stacked-${name}`, 1024, 1024, 'stacked', opts,
    [1024, 2048].map((px) => screen(`logo/stacked/timeflow-stacked-${name}-${px}.png`, px, px)), { inset: 0.08 });
}

// 4. T-shirt artwork, transparent. The 15×18 in full front is 300 DPI only:
// at 1500 DPI it would be 22500×27000 px, more than print shops accept.
for (const [name, opts] of [
  ['for-light-shirts', { text: ink, tagline: true, taglineColor: textDark }],
  ['for-dark-shirts', { text: white, tagline: true }],
  ['one-color-white', { text: white, mark: 'white', tagline: true }],
  ['one-color-black', { text: black, mark: 'black', tagline: true }],
]) {
  add(`tshirt-front-${name}`, 750, 900, 'stacked', opts, print(`tshirt-front-15x18in-${name}`, 15, 18, [300]), { inset: 0.1 });
}
add('tshirt-chest-color', 600, 600, 'mark', {}, print('tshirt-chest-4x4in-color', 4, 4), { inset: 0.05 });
add('tshirt-chest-white', 600, 600, 'mark', { mark: 'white' }, print('tshirt-chest-4x4in-white', 4, 4), { inset: 0.05 });
add('tshirt-back-light', 1200, 300, 'wordmark', { text: ink }, print('tshirt-back-12x3in-wordmark-for-light-shirts', 12, 3));
add('tshirt-back-dark', 1200, 300, 'wordmark', { text: white }, print('tshirt-back-12x3in-wordmark-for-dark-shirts', 12, 3));

// 5. App icon (mark on white at 70%, as on iOS) and press backgrounds.
add('app-icon', 1024, 1024, 'mark', {},
  [512, 1024, 2048].map((px) => screen(`press/app-icon-${px}.png`, px, px)), { inset: 0.15, bg: white });
add('banner-light', 1600, 900, 'stacked', { text: ink, tagline: true, taglineColor: textDark },
  [screen('press/banner-1600x900-light.png', 1600, 900)], { inset: 0.12, bg: paper });
add('banner-dark', 1600, 900, 'stacked', { text: white, tagline: true },
  [screen('press/banner-1600x900-dark.png', 1600, 900)], { inset: 0.12, bg: night });
add('social', 1200, 630, 'wordmark', { text: ink },
  [screen('press/social-1200x630.png', 1200, 630)], { inset: 0.18, bg: paper });

fs.mkdirSync('/work/pdf', { recursive: true });
const browser = await chromium.launch();
for (const d of designs) {
  const { html, nominal } = LAYOUTS[d.layout](d.opts);
  const page = await browser.newPage({ viewport: { width: d.w, height: d.h } });
  await page.setContent(`<html><head><style>
    @font-face { font-family: Nunito; src: url(data:font/ttf;base64,${font}); font-weight: 200 1000; }
    @page { size: ${d.w}px ${d.h}px; margin: 0; }
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: ${d.w}px; height: ${d.h}px; background: ${d.bg ?? 'transparent'}; font-family: Nunito, sans-serif;
      overflow: hidden; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
    #c { position: absolute; left: 0; top: 0; transform-origin: 0 0; display: inline-block; }
  </style></head><body><div id="c">${html}</div></body></html>`);
  await page.evaluate(() => document.fonts.ready);
  // Fit the nominal box inside the inset rect and centre the content in it.
  const box = await page.evaluate(() => {
    const r = document.getElementById('c').getBoundingClientRect();
    return { w: r.width, h: r.height };
  });
  const [nw, nh] = nominal(box.w);
  const iw = d.w * (1 - 2 * d.inset), ih = d.h * (1 - 2 * d.inset);
  const s = Math.min(iw / nw, ih / nh);
  const x = (d.w - box.w * s) / 2, y = (d.h - box.h * s) / 2;
  await page.evaluate(([x, y, s]) => {
    document.getElementById('c').style.transform = `translate(${x}px, ${y}px) scale(${s})`;
  }, [x, y, s]);
  await page.waitForTimeout(100);
  await page.pdf({ path: `/work/pdf/${d.id}.pdf`, width: `${d.w}px`, height: `${d.h}px`,
    printBackground: true, pageRanges: '1' });
  await page.close();
  console.log(d.id);
}
await browser.close();
fs.writeFileSync('/work/manifest.json', JSON.stringify(designs.map(({ id, outputs }) => ({ id, outputs }))));
