// Debug current state of the app
const { chromium } = require('playwright');
const path = require('path');
const os = require('os');

const BROWSER_PATH = path.join(os.homedir(), '.cache/ms-playwright/chromium-1200/chrome-linux64/chrome');
const BASE_URL = 'http://localhost:3000';

async function debugState() {
  const browser = await chromium.launch({
    executablePath: BROWSER_PATH,
    headless: true
  });

  const page = await browser.newPage();
  await page.setViewportSize({ width: 375, height: 667 });

  await page.goto(BASE_URL);
  await page.waitForTimeout(2000);

  // Take screenshot of initial state
  await page.screenshot({ path: 'debug-1-initial.png' });
  console.log('Screenshot 1: Initial state saved');

  // Log console messages
  page.on('console', msg => console.log('Browser console:', msg.text()));

  // Check what elements exist
  const hourMarkers = await page.$$('.hour-marker');
  console.log('Hour markers found:', hourMarkers.length);

  const timeline = await page.$('.timeline-content');
  console.log('Timeline content exists:', !!timeline);

  // Get timeline HTML
  const timelineHTML = await page.evaluate(() => {
    const tc = document.querySelector('.timeline-content');
    return tc ? tc.innerHTML.substring(0, 500) : 'NOT FOUND';
  });
  console.log('Timeline content (first 500 chars):', timelineHTML);

  // Try clicking FAB
  const fab = await page.$('.fab');
  console.log('FAB exists:', !!fab);

  if (fab) {
    await fab.click();
    await page.waitForTimeout(1000);
    await page.screenshot({ path: 'debug-2-after-fab-click.png' });
    console.log('Screenshot 2: After FAB click');

    // Check for modal
    const modal = await page.$('.modal');
    console.log('Modal exists:', !!modal);

    const modalActive = await page.$('.modal.active');
    console.log('Modal active:', !!modalActive);

    // Get modal state
    const modalClasses = await page.evaluate(() => {
      const m = document.querySelector('.modal');
      return m ? m.className : 'NOT FOUND';
    });
    console.log('Modal classes:', modalClasses);
  }

  await browser.close();
}

debugState().catch(console.error);
