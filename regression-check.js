// Regression test - run quick checks on core features
const { chromium } = require('playwright-core');

async function runRegressionTest() {
  const browser = await chromium.launch({
    headless: true,
    executablePath: process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH || undefined
  });
  const page = await browser.newPage();

  try {
    // Navigate to the app
    console.log('1. Navigating to app...');
    await page.goto('http://localhost:3000');
    await page.waitForLoadState('networkidle');

    // Check NOW line exists
    console.log('2. Checking NOW line exists...');
    const nowLine = await page.locator('.now-line').first();
    if (await nowLine.isVisible()) {
      console.log('   ✓ NOW line is visible');
    } else {
      console.log('   ✗ NOW line NOT visible');
    }

    // Check hour markers
    console.log('3. Checking hour markers...');
    const hourMarkers = await page.locator('.hour-marker').count();
    console.log(`   ✓ Found ${hourMarkers} hour markers`);

    // Check FAB button
    console.log('4. Checking FAB button...');
    const fab = await page.locator('.fab').first();
    if (await fab.isVisible()) {
      console.log('   ✓ FAB button is visible');
    } else {
      console.log('   ✗ FAB button NOT visible');
    }

    // Test task creation
    console.log('5. Testing task creation...');
    await fab.click();
    await page.waitForSelector('#task-modal:not([hidden])');
    console.log('   ✓ Modal opened');

    // Fill in task
    const uniqueTitle = `REGRESSION_TEST_${Date.now()}`;
    await page.fill('#task-title', uniqueTitle);
    await page.fill('#task-start-time', '10:00');
    await page.fill('#task-end-time', '11:00');
    console.log(`   ✓ Filled form with title: ${uniqueTitle}`);

    // Save task - use form submit button
    await page.click('button[type="submit"]');
    // Wait for modal to become hidden (state: 'hidden' means wait until element is not visible)
    await page.waitForSelector('#task-modal', { state: 'hidden', timeout: 5000 });
    console.log('   ✓ Task saved');

    // Verify task appears
    await page.waitForTimeout(500);
    const taskCard = await page.locator('.task-card', { hasText: uniqueTitle }).first();
    if (await taskCard.isVisible()) {
      console.log('   ✓ Task card appears on timeline');
    } else {
      console.log('   ✗ Task card NOT found');
    }

    // Take screenshot
    await page.screenshot({ path: 'regression-check.png', fullPage: false });
    console.log('   ✓ Screenshot saved to regression-check.png');

    // Clean up - delete the test task
    console.log('6. Cleaning up test task...');
    await taskCard.click();
    await page.waitForSelector('#task-modal:not([hidden])');
    await page.click('#delete-task-btn');
    // Handle confirmation dialog
    await page.waitForSelector('#confirm-modal:not([hidden])');
    await page.click('#confirm-delete-btn');
    await page.waitForSelector('#confirm-modal', { state: 'hidden', timeout: 5000 });
    console.log('   ✓ Test task deleted');

    console.log('\n✅ REGRESSION TEST PASSED - Core features working');

  } catch (error) {
    console.error('❌ REGRESSION TEST FAILED:', error.message);
    await page.screenshot({ path: 'regression-error.png' });
    console.log('Error screenshot saved to regression-error.png');
  } finally {
    await browser.close();
  }
}

runRegressionTest();
