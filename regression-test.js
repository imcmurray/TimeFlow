const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.goto('http://localhost:3000');
  await page.screenshot({ path: 'regression-test.png' });
  console.log('Screenshot saved to regression-test.png');

  // Check for NOW line
  const nowLine = await page.$('.now-line');
  console.log('NOW line found:', !!nowLine);

  // Check for hour markers
  const hourMarkers = await page.$$('.hour-marker');
  console.log('Hour markers count:', hourMarkers.length);

  await browser.close();
})();
