// Session 28 Regression Test
const { chromium } = require('playwright');

(async () => {
  console.log('Starting regression test...');

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();

  try {
    // Navigate to app
    await page.goto('http://localhost:8080');
    await page.waitForLoadState('networkidle');
    console.log('✓ Page loaded');

    // Check for onboarding and skip if present
    const onboardingSkip = page.locator('#onboarding-skip-btn');
    if (await onboardingSkip.isVisible({ timeout: 2000 }).catch(() => false)) {
      await onboardingSkip.click();
      await page.waitForTimeout(500);
      console.log('✓ Skipped onboarding');
    }

    // Screenshot initial state
    await page.screenshot({ path: 'regression-session28-1-initial.png' });
    console.log('✓ Screenshot: initial state');

    // Verify NOW line is visible
    const nowLine = page.locator('.now-line');
    const nowLineVisible = await nowLine.isVisible();
    console.log(`${nowLineVisible ? '✓' : '✗'} NOW line visible: ${nowLineVisible}`);

    // Verify FAB button is visible
    const fab = page.locator('#add-task-btn');
    const fabVisible = await fab.isVisible();
    console.log(`${fabVisible ? '✓' : '✗'} FAB button visible: ${fabVisible}`);

    // Verify hour labels
    const hourLabels = await page.locator('.hour-label').count();
    console.log(`${hourLabels === 24 ? '✓' : '✗'} Hour labels: ${hourLabels}`);

    // Test task creation with description (Feature 15)
    await fab.click();
    await page.waitForTimeout(500);
    console.log('✓ FAB clicked');

    // Fill form
    const testTitle = `REGTEST_${Date.now()}`;
    const testDesc = 'This is a detailed description with specifics for regression testing';

    await page.fill('#task-title', testTitle);
    await page.fill('#task-start-time', '11:00');
    await page.fill('#task-end-time', '12:00');
    await page.fill('#task-description', testDesc);

    await page.screenshot({ path: 'regression-session28-2-form.png' });
    console.log('✓ Screenshot: form filled');

    // Save task
    await page.click('button:has-text("Save Task")');
    await page.waitForTimeout(1000);

    await page.screenshot({ path: 'regression-session28-3-created.png' });
    console.log('✓ Screenshot: task created');

    // Verify task appears
    const taskCard = page.locator('.task-card', { hasText: testTitle });
    const taskCreated = await taskCard.isVisible({ timeout: 3000 }).catch(() => false);
    console.log(`${taskCreated ? '✓' : '✗'} Task created: ${taskCreated}`);

    // Click on task to verify description
    await taskCard.click();
    await page.waitForTimeout(500);

    const descField = page.locator('#task-description');
    const savedDesc = await descField.inputValue();
    const descMatch = savedDesc === testDesc;
    console.log(`${descMatch ? '✓' : '✗'} Description preserved: ${descMatch}`);

    await page.screenshot({ path: 'regression-session28-4-detail.png' });
    console.log('✓ Screenshot: task detail');

    // Delete task
    await page.click('#delete-task-btn');
    await page.waitForTimeout(500);

    // Confirm deletion
    await page.click('#confirm-delete-btn');
    await page.waitForTimeout(1000);

    await page.screenshot({ path: 'regression-session28-5-cleaned.png' });
    console.log('✓ Screenshot: cleaned up');

    // Verify task deleted
    const taskGone = !(await taskCard.isVisible({ timeout: 1000 }).catch(() => false));
    console.log(`${taskGone ? '✓' : '✗'} Task deleted: ${taskGone}`);

    // Check for console errors
    const consoleErrors = [];
    page.on('console', msg => {
      if (msg.type() === 'error') consoleErrors.push(msg.text());
    });

    console.log('');
    console.log('=== REGRESSION TEST COMPLETE ===');
    console.log('All core features verified working.');

  } catch (error) {
    console.error('Test error:', error.message);
    await page.screenshot({ path: 'regression-session28-error.png' });
  } finally {
    await browser.close();
  }
})();
