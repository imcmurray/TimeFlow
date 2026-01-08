// Browser Helper - shared Playwright setup with working Chromium
const { chromium } = require('playwright');
const path = require('path');
const os = require('os');

const BROWSER_PATH = path.join(os.homedir(), '.cache/ms-playwright/chromium-1200/chrome-linux64/chrome');
const BASE_URL = 'http://localhost:3000';

async function launchBrowser() {
  return await chromium.launch({
    executablePath: BROWSER_PATH,
    headless: true
  });
}

async function newPage(browser) {
  const page = await browser.newPage();
  await page.setViewportSize({ width: 375, height: 667 }); // Mobile viewport
  return page;
}

async function screenshot(page, name) {
  await page.screenshot({ path: `${name}.png` });
  console.log(`Screenshot saved: ${name}.png`);
}

module.exports = { launchBrowser, newPage, screenshot, BASE_URL, BROWSER_PATH };
