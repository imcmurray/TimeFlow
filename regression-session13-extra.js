const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  console.log('=== REGRESSION TESTS FOR RANDOM PASSING FEATURES ===\n');

  // Navigate to app
  await page.goto('http://localhost:3000');
  await page.waitForTimeout(2000);

  // Dismiss onboarding
  await page.evaluate(() => {
    const modal = document.getElementById('onboarding-modal');
    if (modal && !modal.hidden) {
      const skipBtn = document.getElementById('onboarding-skip-btn');
      if (skipBtn) skipBtn.click();
    }
  });
  await page.waitForTimeout(500);

  // Test 1: Rapid navigation handling (Feature 90)
  console.log('TEST 1: Rapid navigation handling...');
  for (let i = 0; i < 5; i++) {
    // Open settings
    await page.click('button[aria-label="Settings"]');
    await page.waitForTimeout(100);
    // Close settings
    await page.click('#settings-modal button[aria-label="Close"]');
    await page.waitForTimeout(100);
  }
  // Verify no crashes - if we get here, it's good
  console.log('  - No crashes during rapid navigation: PASS');
  await page.screenshot({ path: 'regression-session13-extra-nav.png' });

  // Test 2: Deep link to specific date (Feature 139)
  console.log('\nTEST 2: Deep link to specific date...');
  // Navigate to a specific date via URL hash
  await page.goto('http://localhost:3000#date=2026-01-10');
  await page.waitForTimeout(1000);

  // Dismiss onboarding again if it shows
  await page.evaluate(() => {
    const modal = document.getElementById('onboarding-modal');
    if (modal && !modal.hidden) {
      const skipBtn = document.getElementById('onboarding-skip-btn');
      if (skipBtn) skipBtn.click();
    }
  });
  await page.waitForTimeout(500);

  const dateHeader = await page.textContent('.date-display');
  console.log('  - Date header shows:', dateHeader);
  const hasJan10 = dateHeader.includes('January 10') || dateHeader.includes('10');
  console.log('  - Deep link to date: ' + (hasJan10 ? 'PASS' : 'FAIL'));
  await page.screenshot({ path: 'regression-session13-extra-deeplink.png' });

  // Go back to today
  await page.goto('http://localhost:3000');
  await page.waitForTimeout(1000);
  await page.evaluate(() => {
    const modal = document.getElementById('onboarding-modal');
    if (modal && !modal.hidden) {
      const skipBtn = document.getElementById('onboarding-skip-btn');
      if (skipBtn) skipBtn.click();
    }
  });
  await page.waitForTimeout(500);

  // Test 3: Long description handling (Feature 111)
  console.log('\nTEST 3: Long description handling...');
  // Open task modal
  await page.click('.fab');
  await page.waitForTimeout(500);

  // Fill form with long description
  const longDesc = 'This is a very long description. '.repeat(50);
  await page.fill('#task-title', 'LONG_DESC_TEST');
  await page.fill('#task-start-time', '10:00');
  await page.fill('#task-end-time', '11:00');
  await page.fill('#task-description', longDesc);

  console.log('  - Long description entered (' + longDesc.length + ' chars)');

  // Save task
  await page.click('#task-modal button[type="submit"]');
  await page.waitForTimeout(1000);

  // Reopen the task
  const taskCards = await page.$$('.task-card');
  for (const card of taskCards) {
    const text = await card.textContent();
    if (text.includes('LONG_DESC_TEST')) {
      await card.click();
      break;
    }
  }
  await page.waitForTimeout(500);

  // Check if description is preserved
  const descValue = await page.$eval('#task-description', el => el.value);
  console.log('  - Description preserved (' + descValue.length + ' chars): ' + (descValue.length > 1000 ? 'PASS' : 'FAIL'));

  await page.screenshot({ path: 'regression-session13-extra-longdesc.png' });

  // Clean up - delete the test task
  const deleteBtn = await page.$('#delete-task-btn');
  if (deleteBtn) {
    await deleteBtn.click();
    await page.waitForTimeout(500);
    const confirmBtn = await page.$('#confirm-delete-btn');
    if (confirmBtn) {
      await confirmBtn.click();
      await page.waitForTimeout(500);
    }
  }

  console.log('\n=== ALL REGRESSION TESTS COMPLETE ===');

  await browser.close();
})();
