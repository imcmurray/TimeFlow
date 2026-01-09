// Debug script to analyze page structure
const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();

  await page.goto('http://localhost:3000');
  await page.waitForTimeout(2000);

  // Get page content
  const html = await page.content();
  console.log('Page loaded, content length:', html.length);

  // Take screenshot
  await page.screenshot({ path: 'debug-session47-initial.png' });
  console.log('Screenshot saved');

  // Look for any buttons
  const buttons = await page.$$eval('button', els => els.map(e => ({
    id: e.id,
    class: e.className,
    text: e.textContent.trim().substring(0, 50)
  })));
  console.log('\nButtons found:', JSON.stringify(buttons, null, 2));

  // Look for FAB-related elements
  const fabElements = await page.$$eval('[class*="fab"], [id*="fab"], [class*="Fab"], [id*="Fab"], .add-button, #add-button',
    els => els.map(e => ({
      tag: e.tagName,
      id: e.id,
      class: e.className
    })));
  console.log('\nFAB-related elements:', JSON.stringify(fabElements, null, 2));

  // Look for all clickable elements
  const clickables = await page.$$eval('button, a, [role="button"], [onclick]', els => els.map(e => ({
    tag: e.tagName,
    id: e.id,
    class: e.className,
    text: e.textContent.trim().substring(0, 30)
  })));
  console.log('\nAll clickable elements:', JSON.stringify(clickables.slice(0, 20), null, 2));

  await browser.close();
})();
