const { chromium } = require('playwright');
const path = require('path');
const os = require('os');

(async () => {
  const execPath = path.join(os.homedir(), '.cache/ms-playwright/chromium-1200/chrome-linux64/chrome');
  console.log('Using browser at:', execPath);

  const browser = await chromium.launch({
    executablePath: execPath,
    headless: true
  });
  const page = await browser.newPage();
  await page.goto('http://localhost:3000');
  console.log('Page title:', await page.title());
  await page.screenshot({ path: 'quick-test.png' });
  await browser.close();
  console.log('SUCCESS: Browser works');
})();
