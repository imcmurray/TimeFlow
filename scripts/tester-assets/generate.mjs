// Renders the TimeFlow beta-tester badges, banners and stickers with the
// app's Nunito font and logo. Run through ../generate_tester_assets.sh,
// which provides Chromium (Playwright) in Docker.
//
//   SINCE_VERSION=1.0.0 SINCE_BUILD=183 ./scripts/generate_tester_assets.sh
import { chromium } from 'playwright';
import fs from 'fs';
import path from 'path';

const repo = '/repo';
const out = path.join(repo, 'marketing/testers');
const version = process.env.SINCE_VERSION || '1.0.0';
const build = process.env.SINCE_BUILD || '183';
const since = `v${version} (${build})`;

const font = fs.readFileSync(path.join(repo, 'assets/fonts/Nunito.ttf')).toString('base64');
const logo = fs.readFileSync(path.join(repo, 'assets/branding/timeflow-logo.svg')).toString('base64');
const mark = `<img class="mark" src="data:image/svg+xml;base64,${logo}">`;
// One-colour marks (Ian's outline versions) for single-ink designs.
const mono = (c) => `<img class="mark" src="data:image/svg+xml;base64,${fs
  .readFileSync(path.join(repo, `assets/branding/timeflow-logo-${c}.svg`)).toString('base64')}">`;

const C = {
  river: '#42A5F5', deep: '#1976D2', ink: '#1A6FC8', navy: '#0D3C61',
  paper: '#FAFAFA', night: '#121212', caution: '#FFC83D', black: '#1B1B1B',
  now: '#1976D2',
};

const base = `
  @font-face { font-family: Nunito; src: url(data:font/ttf;base64,${font}); font-weight: 200 1000; }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  html, body { background: transparent; font-family: Nunito, sans-serif; }
  .mark { display: block; }
`;

// Hazard-tape stripes as a real SVG pattern (CSS repeating gradients don't
// survive the PDF → SVG conversion). Fills its positioned parent.
const stripes = (band) => `<svg class="stripes" width="100%" height="100%" preserveAspectRatio="none"
  style="position:absolute;inset:0;display:block"><defs>
  <pattern id="hz${band}" width="${band * 2}" height="${band * 2}" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
    <rect width="${band * 2}" height="${band * 2}" fill="${C.caution}"/><rect width="${band}" height="${band * 2}" fill="${C.black}"/>
  </pattern></defs><rect width="100%" height="100%" fill="url(#hz${band})"/></svg>`;

// Each design: name, size (CSS px), html. Rendered at 1x for screens and
// at higher pixel ratios for print/large use.
const designs = [];
const add = (name, w, h, css, html, scales = [1, 2]) =>
  designs.push({ name, w, h, css, html, scales });

// 1. Round seal: "TimeFlow Tester — since v1.0.0 (183)"
add('seal-since', 512, 512, `
  .seal { width: 512px; height: 512px; border-radius: 50%; position: relative;
    background: radial-gradient(circle at 35% 30%, #fff 0%, ${C.paper} 60%, #e3f2fd 100%);
    border: 18px solid ${C.ink}; box-shadow: inset 0 0 0 8px #fff, inset 0 0 0 12px ${C.river}; }
  .seal svg.ring { position: absolute; inset: 0; }
  .seal .mark { position: absolute; left: 50%; top: 50%; width: 150px; transform: translate(-50%, -68%); }
  .seal .since { position: absolute; left: 0; right: 0; top: 286px; text-align: center;
    font-weight: 900; font-size: 32px; color: ${C.navy}; letter-spacing: .5px; }
`, `<div class="seal">
  <svg class="ring" viewBox="0 0 512 512">
    <defs><path id="top" d="M 86 256 A 170 170 0 0 1 426 256"/>
          <path id="bottom" d="M 74 262 A 182 182 0 0 0 438 262"/></defs>
    <text font-family="Nunito" font-weight="900" font-size="44" fill="${C.ink}" letter-spacing="6">
      <textPath href="#top" startOffset="50%" text-anchor="middle">TIMEFLOW TESTER</textPath></text>
    <text font-family="Nunito" font-weight="800" font-size="26" fill="${C.deep}" letter-spacing="8">
      <textPath href="#bottom" startOffset="50%" text-anchor="middle">★ BETA CREW ★</textPath></text>
  </svg>
  ${mark}<div class="since">Since ${since}</div></div>`, [1, 2, 4]);

// 2. Caution tape banner: "CAUTION: BETA TESTER"
const tape = (w, h, size, insetY, insetX) => `
  .tape { width: ${w}px; height: ${h}px; position: relative; overflow: hidden; border-radius: ${h * 0.12}px; }
  .label { position: absolute; inset: ${insetY}px ${insetX}px; background: ${C.caution};
    border: ${h * 0.03}px solid ${C.black}; border-radius: ${h * 0.08}px;
    display: flex; align-items: center; justify-content: center; gap: ${h * 0.12}px; }
  .label .mark { height: ${h * 0.46}px; }
  .label .words { color: ${C.black}; font-weight: 1000; font-size: ${size}px; letter-spacing: 2px; line-height: 1.02; white-space: nowrap; }
  .label .words small { display: block; font-weight: 800; font-size: ${size * 0.42}px; letter-spacing: 1px; margin-top: ${size * 0.12}px; }
`;
add('caution-beta-tester-banner', 1600, 400, tape(1600, 400, 88, 60, 90),
  `<div class="tape">${stripes(56)}<div class="label">${mark}<div class="words">CAUTION: BETA TESTER<small>Things may wobble. That's the point.</small></div></div></div>`);
add('caution-beta-tester-square', 800, 800, tape(800, 800, 92, 90, 90) + `
  .label { flex-direction: column; text-align: center; gap: 24px; }
  .label .mark { height: 150px; }`,
  `<div class="tape">${stripes(56)}<div class="label">${mark}<div class="words">CAUTION<br>BETA<br>TESTER<small>Since ${since}</small></div></div></div>`, [1, 2]);

// 3. Pill badge styled like the app's NOW line: "Since v1.0.0 (183)"
const pill = (text, bg, fg) => `
  <div class="pill" style="background:${bg};color:${fg}">${mark}<span class="k">TESTER</span><span class="v">${text}</span></div>`;
add('pill-since', 900, 200, `
  body { display: flex; align-items: center; justify-content: center; height: 200px; }
  .pill { height: 140px; padding: 0 56px 0 28px; border-radius: 70px; display: flex; align-items: center; gap: 24px;
    box-shadow: 0 10px 30px rgba(13,60,97,.25); }
  .pill .mark { height: 96px; background: #fff; border-radius: 50%; padding: 10px; }
  .k { font-weight: 1000; font-size: 54px; letter-spacing: 4px; }
  .v { font-weight: 700; font-size: 50px; opacity: .92; }
`, pill(`since ${since}`, C.ink, '#fff'));
add('pill-since-dark', 900, 200, designs.at(-1).css, pill(`since ${since}`, '#64B5F6', '#0B1E33'));

// 4. "I saw it before NOW" sticker: a NOW line across a river card
add('saw-it-before-now', 600, 600, `
  .card { width: 600px; height: 600px; border-radius: 120px; position: relative; overflow: hidden;
    background: linear-gradient(180deg, #E3F2FD 0%, ${C.paper} 55%, #E8F5E9 100%); border: 14px solid ${C.ink}; }
  .card .mark { position: absolute; left: 50%; top: 70px; width: 150px; transform: translateX(-50%); }
  .line { position: absolute; left: 0; right: 0; top: 330px; height: 6px; background: ${C.now};
    box-shadow: 0 0 22px 6px rgba(25,118,210,.45); }
  .now { position: absolute; left: 36px; top: 308px; background: ${C.now}; color: #fff; border-radius: 16px;
    font-weight: 900; font-size: 34px; letter-spacing: 3px; padding: 4px 18px; }
  .t1 { position: absolute; left: 0; right: 0; top: 236px; text-align: center; font-weight: 900; font-size: 54px; color: ${C.navy}; }
  .t2 { position: absolute; left: 0; right: 0; top: 380px; text-align: center; font-weight: 1000; font-size: 92px; color: ${C.ink}; letter-spacing: 2px; }
  .t3 { position: absolute; left: 0; right: 0; bottom: 56px; text-align: center; font-weight: 700; font-size: 30px; color: #4a4a4a; }
`, `<div class="card">${mark}<div class="t1">I saw it before</div><div class="line"></div><div class="now">NOW</div><div class="t2">NOW</div><div class="t3">TimeFlow beta tester</div></div>`, [1, 2, 4]);

// 5. "BETA — expect ripples" sticker
add('beta-expect-ripples', 600, 600, `
  .disc { width: 600px; height: 600px; border-radius: 50%; position: relative; overflow: hidden;
    background: radial-gradient(circle at 50% 50%, ${C.river} 0 22%, #64B5F6 22% 34%, #90CAF9 34% 46%, #BBDEFB 46% 58%, #E3F2FD 58% 100%);
    border: 14px solid ${C.navy}; }
  .disc .mark { position: absolute; left: 50%; top: 50%; width: 120px; transform: translate(-50%, -50%);
    filter: drop-shadow(0 4px 8px rgba(0,0,0,.2)); }
  .b { position: absolute; left: 0; right: 0; top: 62px; text-align: center; font-weight: 1000; font-size: 96px; color: ${C.navy}; letter-spacing: 10px; }
  .e { position: absolute; left: 0; right: 0; bottom: 70px; text-align: center; font-weight: 900; font-size: 46px; color: ${C.navy}; }
`, `<div class="disc"><div class="b">BETA</div>${mark}<div class="e">expect ripples</div></div>`, [1, 2, 4]);

// 6. Founding tester ribbon
add('founding-tester', 600, 720, `
  .medal { width: 600px; height: 720px; position: relative; }
  .ribbon { position: absolute; top: 380px; width: 120px; height: 320px; background: ${C.deep}; }
  .ribbon.l { left: 150px; transform: skewX(12deg); } .ribbon.r { right: 150px; transform: skewX(-12deg); background: ${C.river}; }
  .ribbon::after { content: ''; position: absolute; bottom: 0; left: 0; border-left: 60px solid transparent;
    border-right: 60px solid transparent; border-bottom: 50px solid transparent; }
  .coin { position: absolute; left: 40px; top: 20px; width: 520px; height: 520px; border-radius: 50%;
    background: radial-gradient(circle at 35% 30%, #fff, ${C.paper} 55%, #dceefc); border: 20px solid ${C.ink};
    box-shadow: 0 16px 40px rgba(13,60,97,.3), inset 0 0 0 10px #fff; }
  .coin .mark { position: absolute; left: 50%; top: 70px; width: 150px; transform: translateX(-50%); }
  .f { position: absolute; left: 0; right: 0; top: 245px; text-align: center; font-weight: 1000; font-size: 64px; color: ${C.navy}; line-height: 1; }
  .s { position: absolute; left: 0; right: 0; top: 375px; text-align: center; font-weight: 800; font-size: 26px; line-height: 1.25; color: ${C.ink}; }
`, `<div class="medal"><div class="ribbon l"></div><div class="ribbon r"></div>
  <div class="coin">${mark}<div class="f">FOUNDING<br>TESTER</div><div class="s">TimeFlow<br>since ${since}</div></div></div>`, [1, 2, 4]);

// 7. Bug hunter badge
add('bug-hunter', 600, 600, `
  .hex { width: 600px; height: 600px; position: relative;
    clip-path: polygon(50% 0, 93% 25%, 93% 75%, 50% 100%, 7% 75%, 7% 25%);
    background: linear-gradient(160deg, ${C.navy}, ${C.ink}); }
  .hex .mark { position: absolute; left: 50%; top: 92px; width: 140px; transform: translateX(-50%); }
  .b { position: absolute; left: 0; right: 0; top: 270px; text-align: center; color: #fff; font-weight: 1000; font-size: 76px; line-height: 1; letter-spacing: 3px; }
  .s { position: absolute; left: 0; right: 0; top: 440px; text-align: center; color: #BBDEFB; font-weight: 800; font-size: 28px; }
`, `<div class="hex">${mark}<div class="b">BUG<br>HUNTER</div><div class="s">TimeFlow beta</div></div>`, [1, 2, 4]);

// 8. Tester-group social card / header (e.g. for the timeflow-testers group)
add('timeflow-testers-header', 1200, 630, `
  .card { width: 1200px; height: 630px; position: relative; overflow: hidden;
    background: linear-gradient(135deg, #E3F2FD 0%, ${C.paper} 55%, #E8F5E9 100%); }
  .stripe { position: absolute; left: 0; right: 0; top: 0; height: 36px; overflow: hidden; }
  .card .mark { position: absolute; left: 80px; top: 130px; width: 150px; }
  .h { position: absolute; left: 260px; top: 132px; font-weight: 1000; font-size: 92px; color: ${C.navy}; letter-spacing: -1px; }
  .t { position: absolute; left: 266px; top: 248px; font-weight: 800; font-size: 40px; color: ${C.ink}; }
  .p { position: absolute; left: 82px; top: 360px; right: 80px; font-weight: 600; font-size: 34px; line-height: 1.4; color: #3b3b3b; }
  .tag { position: absolute; right: 70px; bottom: 56px; background: ${C.ink}; color: #fff; border-radius: 40px;
    font-weight: 900; font-size: 30px; padding: 12px 30px; letter-spacing: 1px; }
`, `<div class="card"><div class="stripe">${stripes(13)}</div>${mark}
  <div class="h">timeflow-testers</div>
  <div class="t">Testing TimeFlow before everyone else</div>
  <div class="p">Try new builds first, tell us what wobbles, and help shape a calmer way to see your day.</div>
  <div class="tag">since ${since}</div></div>`, [1, 2]);

// 9. Small square icons for chat roles / avatars (Discord, Slack, ...)
add('role-icon-tester', 256, 256, `
  .i { width: 256px; height: 256px; border-radius: 56px; background: linear-gradient(160deg, ${C.ink}, ${C.navy});
    display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 6px; }
  .i .mark { width: 120px; background: #fff; border-radius: 50%; padding: 14px; }
  .i span { color: #fff; font-weight: 1000; font-size: 38px; letter-spacing: 4px; }
`, `<div class="i">${mark}<span>BETA</span></div>`, [1, 2]);

// 10. Name badges: "TimeFlow Tester", "TimeFlow Beta Tester" and friends.
// Horizontal lockups in full colour (for light and dark backgrounds) and in
// one colour (white / black, using the outline marks) for single-ink prints.
const lockupCss = (fg, sub) => `
  body { display: flex; align-items: center; justify-content: center; height: 360px; }
  .lock { display: flex; align-items: center; gap: 44px; }
  .lock .mark { height: 230px; }
  .lock .w { display: flex; flex-direction: column; line-height: .95; }
  .lock .n { font-weight: 900; font-size: 128px; color: ${fg}; letter-spacing: -2px; }
  .lock .r { font-weight: 1000; font-size: 88px; color: ${sub}; letter-spacing: 6px; }
`;
const lockup = (role, m = mark) =>
  `<div class="lock">${m}<div class="w"><span class="n">TimeFlow</span><span class="r">${role}</span></div></div>`;
for (const [slug, role, w] of [['timeflow-tester', 'TESTER', 1200], ['timeflow-beta-tester', 'BETA TESTER', 1400]]) {
  add(`${slug}-light`, w, 360, lockupCss(C.navy, C.ink), lockup(role), [1, 2, 4]);
  add(`${slug}-dark`, w, 360, lockupCss('#FFFFFF', '#90CAF9'), lockup(role), [1, 2, 4]);
  add(`${slug}-white`, w, 360, lockupCss('#FFFFFF', '#FFFFFF'), lockup(role, mono('white')), [1, 2, 4]);
  add(`${slug}-black`, w, 360, lockupCss('#000000', '#000000'), lockup(role, mono('black')), [1, 2, 4]);
}

// Stacked squares: mark above the words, for avatars and stickers.
const stackedCss = (bg, fg, sub, ring) => `
  .sq { width: 800px; height: 800px; border-radius: 160px; background: ${bg}; border: 16px solid ${ring};
    display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 18px; }
  .sq .mark { height: 300px; }
  .sq .n { font-weight: 900; font-size: 120px; color: ${fg}; letter-spacing: -2px; line-height: 1; }
  .sq .r { font-weight: 1000; font-size: 64px; color: ${sub}; letter-spacing: 6px; line-height: 1; }
`;
for (const [slug, role] of [['timeflow-tester-stacked', 'TESTER'], ['timeflow-beta-tester-stacked', 'BETA TESTER']]) {
  add(slug, 800, 800,
    stackedCss(`linear-gradient(160deg, #E3F2FD, ${C.paper} 60%, #E8F5E9)`, C.navy, C.ink, C.ink),
    `<div class="sq">${mark}<span class="n">TimeFlow</span><span class="r">${role}</span></div>`, [1, 2, 4]);
  add(`${slug}-dark`, 800, 800, stackedCss(`linear-gradient(160deg, ${C.navy}, #0B1E33)`, '#FFFFFF', '#90CAF9', '#64B5F6'),
    `<div class="sq">${mark}<span class="n">TimeFlow</span><span class="r">${role}</span></div>`, [1, 2, 4]);
}

// "Official TimeFlow Beta Tester" stamp.
add('official-timeflow-beta-tester', 600, 600, `
  .stamp { width: 600px; height: 600px; border-radius: 50%; position: relative; background: #fff;
    border: 16px solid ${C.ink}; box-shadow: inset 0 0 0 10px #fff, inset 0 0 0 16px ${C.river}; }
  .stamp svg { position: absolute; inset: 0; }
  .stamp .mark { position: absolute; left: 50%; top: 50%; width: 190px; transform: translate(-50%, -50%); }
`, `<div class="stamp"><svg viewBox="0 0 600 600">
    <defs><path id="ring" d="M 300 300 m -222 0 a 222 222 0 1 1 444 0 a 222 222 0 1 1 -444 0"/></defs>
    <text font-family="Nunito" font-weight="1000" font-size="44" fill="${C.navy}" letter-spacing="7">
      <textPath href="#ring" startOffset="0" textLength="1380" lengthAdjust="spacing">OFFICIAL • TIMEFLOW BETA TESTER •</textPath></text>
  </svg>${mark}</div>`, [1, 2, 4]);

// Plain "TimeFlow Tester" pills (no build number), NOW-line style.
add('pill-timeflow-tester', 1000, 200, designs.find((d) => d.name === 'pill-since').css,
  `<div class="pill" style="background:${C.ink};color:#fff">${mark}<span class="k">TIMEFLOW</span><span class="v">tester</span></div>`);
add('pill-timeflow-beta-tester', 1100, 200, designs.find((d) => d.name === 'pill-since').css,
  `<div class="pill" style="background:${C.ink};color:#fff">${mark}<span class="k">TIMEFLOW</span><span class="v">beta tester</span></div>`);

// "Hello, I'm a TimeFlow Beta Tester" name tag with a write-in line.
add('hello-timeflow-beta-tester', 1000, 700, `
  .tag { width: 1000px; height: 700px; border-radius: 48px; overflow: hidden; background: #fff;
    border: 10px solid ${C.ink}; display: flex; flex-direction: column; }
  .top { background: ${C.ink}; color: #fff; text-align: center; padding: 26px 0 30px; }
  .top .h { font-weight: 1000; font-size: 110px; letter-spacing: 6px; line-height: 1; }
  .top .s { font-weight: 800; font-size: 44px; margin-top: 8px; display: flex; align-items: center; justify-content: center; gap: 16px; }
  .top .mark { height: 56px; background: #fff; border-radius: 50%; padding: 6px; }
  .body { flex: 1; position: relative; }
  .line { position: absolute; left: 70px; right: 70px; bottom: 90px; border-bottom: 6px solid #cfd8dc; }
`, `<div class="tag"><div class="top"><div class="h">HELLO</div>
  <div class="s">I'm a ${mark} TimeFlow Beta Tester</div></div><div class="body"><div class="line"></div></div></div>`, [1, 2]);

fs.mkdirSync(out, { recursive: true });
const browser = await chromium.launch();
for (const d of designs) {
  for (const scale of d.scales) {
    const page = await browser.newPage({ viewport: { width: d.w, height: d.h }, deviceScaleFactor: scale });
    await page.setContent(`<html><head><style>${base}${d.css}</style></head><body>${d.html}</body></html>`);
    await page.evaluate(() => document.fonts.ready);
    await page.waitForTimeout(150);
    const file = path.join(out, `${d.name}-${d.w * scale}x${d.h * scale}.png`);
    await page.screenshot({ path: file, omitBackground: true });
    await page.close();
    console.log(path.relative(repo, file));
  }
  // A vector copy: Chromium prints the design to PDF (shapes and gradients
  // stay vector); generate_tester_assets.sh converts it to SVG.
  const page = await browser.newPage({ viewport: { width: d.w, height: d.h } });
  await page.setContent(`<html><head><style>${base}${d.css}
    @page { size: ${d.w}px ${d.h}px; margin: 0; }</style></head><body>${d.html}</body></html>`);
  await page.evaluate(() => document.fonts.ready);
  await page.waitForTimeout(150);
  fs.mkdirSync('/work/pdf', { recursive: true });
  await page.pdf({ path: `/work/pdf/${d.name}.pdf`, width: `${d.w}px`, height: `${d.h}px`,
    printBackground: true, pageRanges: '1' });
  await page.close();
}
await browser.close();
