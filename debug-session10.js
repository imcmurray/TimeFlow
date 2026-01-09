const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });

  try {
    console.log('Debug: Checking app state...\n');

    // Navigate to app
    await page.goto('http://localhost:3000');
    await page.waitForTimeout(2000);

    // Take a screenshot
    await page.screenshot({ path: 'debug-session10-initial.png' });
    console.log('Screenshot saved: debug-session10-initial.png');

    // Check what elements exist
    console.log('\nChecking elements:');

    const timeline = await page.locator('#timeline').count();
    console.log('  #timeline:', timeline > 0 ? 'exists' : 'MISSING');

    const nowLine = await page.locator('#now-line').count();
    console.log('  #now-line:', nowLine > 0 ? 'exists' : 'MISSING');

    const fab = await page.locator('#fab').count();
    console.log('  #fab:', fab > 0 ? 'exists' : 'MISSING');

    const fabByClass = await page.locator('.fab').count();
    console.log('  .fab class:', fabByClass > 0 ? 'exists' : 'MISSING');

    const anyButton = await page.locator('button').count();
    console.log('  buttons:', anyButton);

    // Get page HTML
    const html = await page.content();
    console.log('\n  Page contains FAB in HTML:', html.includes('fab') ? 'yes' : 'no');
    console.log('  Page contains "Add Task":', html.includes('Add Task') ? 'yes' : 'no');

    // Check console for errors
    const consoleLogs = [];
    page.on('console', msg => consoleLogs.push(msg.text()));

    // Check if any errors
    const errors = await page.locator('text=error').count();
    console.log('  Error text on page:', errors);

    // Check body content
    const bodyText = await page.locator('body').textContent();
    console.log('\n  Body text (first 500 chars):');
    console.log('  ', bodyText.substring(0, 500).replace(/\s+/g, ' '));

  } catch (error) {
    console.error('Debug failed:', error.message);
    await page.screenshot({ path: 'debug-session10-error.png' });
  } finally {
    await browser.close();
  }
})();
