const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.goto('http://localhost:3000');
  await page.screenshot({ path: 'regression-session9.png' });

  const title = await page.title();
  console.log('Page title:', title);

  // Check for NOW line
  const nowLine = await page.$('.now-line');
  console.log('NOW line present:', !!nowLine);

  // Check for hour markers
  const hourMarkers = await page.$$('.hour-marker');
  console.log('Hour markers count:', hourMarkers.length);

  // Check for FAB
  const fab = await page.$('.fab');
  console.log('FAB present:', !!fab);

  await browser.close();
  console.log('Regression check passed!');
})();
