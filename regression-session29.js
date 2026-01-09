const { chromium } = require('playwright');

(async () => {
  console.log('Starting regression test...');

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  try {
    // Navigate to app
    await page.goto('http://localhost:3000');
    console.log('Page loaded');

    // Check for onboarding and skip if present
    const onboardingSkip = page.locator('#onboarding-skip-btn');
    if (await onboardingSkip.isVisible({ timeout: 2000 }).catch(() => false)) {
      await onboardingSkip.click();
      console.log('Skipped onboarding');
      await page.waitForTimeout(500);
    }

    // Check NOW line
    const nowLine = await page.locator('#now-line').isVisible();
    console.log('NOW line visible:', nowLine ? 'PASS' : 'FAIL');

    // Check hour labels
    const hourLabels = await page.locator('.hour-label').count();
    console.log('Hour labels count:', hourLabels, hourLabels === 24 ? 'PASS' : 'FAIL');

    // Check FAB button
    const fab = await page.locator('#add-task-btn').isVisible();
    console.log('FAB button visible:', fab ? 'PASS' : 'FAIL');

    // Take screenshot
    await page.screenshot({ path: 'regression-session29-1-initial.png' });
    console.log('Screenshot saved: regression-session29-1-initial.png');

    // Test task creation
    await page.locator('#add-task-btn').click();
    await page.waitForTimeout(500);

    // Fill form
    const testId = `TEST_${Date.now()}`;
    await page.locator('#task-title').fill(testId);
    await page.locator('#task-start-time').fill('10:00');
    await page.locator('#task-end-time').fill('11:00');
    await page.locator('#task-description').fill('Regression test task');

    await page.screenshot({ path: 'regression-session29-2-form.png' });
    console.log('Screenshot saved: regression-session29-2-form.png');

    // Save task
    await page.locator('button:has-text("Save Task")').click();
    await page.waitForTimeout(1000);

    // Verify task created
    const taskCard = await page.locator(`.task-card:has-text("${testId}")`).isVisible();
    console.log('Task created:', taskCard ? 'PASS' : 'FAIL');

    await page.screenshot({ path: 'regression-session29-3-created.png' });
    console.log('Screenshot saved: regression-session29-3-created.png');

    // Delete task
    await page.locator(`.task-card:has-text("${testId}")`).click();
    await page.waitForTimeout(500);
    await page.locator('#delete-task-btn').click();
    await page.waitForTimeout(500);

    // Confirm delete
    const confirmBtn = page.locator('#confirm-delete-btn');
    if (await confirmBtn.isVisible({ timeout: 2000 }).catch(() => false)) {
      await confirmBtn.click();
      await page.waitForTimeout(500);
    }

    // Verify task deleted
    const taskGone = !(await page.locator(`.task-card:has-text("${testId}")`).isVisible().catch(() => false));
    console.log('Task deleted:', taskGone ? 'PASS' : 'FAIL');

    await page.screenshot({ path: 'regression-session29-4-cleaned.png' });
    console.log('Screenshot saved: regression-session29-4-cleaned.png');

    // Check console errors
    const consoleErrors = [];
    page.on('console', msg => {
      if (msg.type() === 'error') consoleErrors.push(msg.text());
    });
    console.log('Console errors:', consoleErrors.length === 0 ? 'PASS (none)' : `FAIL (${consoleErrors.length})`);

    console.log('\n=== REGRESSION TEST COMPLETE ===');

  } catch (error) {
    console.error('Test error:', error.message);
    await page.screenshot({ path: 'regression-session29-error.png' });
  } finally {
    await browser.close();
  }
})();
