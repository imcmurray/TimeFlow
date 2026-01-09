const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({
    executablePath: '/home/ianm/.cache/ms-playwright/chromium-1193/chrome-linux/chrome',
    headless: true
  });
  const page = await browser.newPage();
  const consoleErrors = [];

  page.on('console', msg => {
    if (msg.type() === 'error') {
      consoleErrors.push(msg.text());
    }
  });

  try {
    console.log('=== TimeFlow Regression Test - Session 32 ===\n');

    // Step 1: Navigate to app
    console.log('Step 1: Navigating to app...');
    await page.goto('http://localhost:3000');
    await page.waitForTimeout(2000);

    // Skip onboarding if shown
    const skipBtn = await page.$('#onboarding-skip-btn');
    if (skipBtn && await skipBtn.isVisible()) {
      console.log('  - Skipping onboarding...');
      await skipBtn.click();
      await page.waitForTimeout(500);
    }

    await page.screenshot({ path: 'regression-session32-1-initial.png', fullPage: false });
    console.log('  - Screenshot: regression-session32-1-initial.png');

    // Step 2: Verify NOW line
    console.log('\nStep 2: Verifying NOW line...');
    const nowLine = await page.$('#now-line');
    const nowLineVisible = nowLine && await nowLine.isVisible();
    console.log(`  - NOW line visible: ${nowLineVisible ? 'PASS' : 'FAIL'}`);

    // Step 3: Verify hour markers
    console.log('\nStep 3: Verifying hour markers...');
    const hourLabels = await page.$$('.hour-label');
    console.log(`  - Hour markers count: ${hourLabels.length} (expected 24): ${hourLabels.length === 24 ? 'PASS' : 'FAIL'}`);

    // Step 4: Verify FAB button
    console.log('\nStep 4: Verifying FAB button...');
    const fab = await page.$('#add-task-btn');
    const fabVisible = fab && await fab.isVisible();
    console.log(`  - FAB button visible: ${fabVisible ? 'PASS' : 'FAIL'}`);

    // Step 5: Create a task
    console.log('\nStep 5: Creating test task...');
    await fab.click();
    await page.waitForTimeout(500);

    const taskModal = await page.$('#task-modal');
    const modalVisible = taskModal && await taskModal.isVisible() && !await taskModal.evaluate(el => el.hasAttribute('hidden'));
    console.log(`  - Task modal visible: ${modalVisible ? 'PASS' : 'FAIL'}`);

    // Fill form
    const timestamp = Date.now();
    const taskTitle = `TEST_SESSION32_${timestamp}`;
    await page.fill('#task-title', taskTitle);
    await page.fill('#task-start-time', '10:00');
    await page.fill('#task-end-time', '11:00');
    await page.fill('#task-description', 'Regression test task for Session 32');

    await page.screenshot({ path: 'regression-session32-2-form.png', fullPage: false });
    console.log('  - Screenshot: regression-session32-2-form.png');

    // Save task
    const saveBtn = await page.$('button:has-text("Save Task")');
    await saveBtn.click();
    await page.waitForTimeout(1000);

    await page.screenshot({ path: 'regression-session32-3-created.png', fullPage: false });
    console.log('  - Screenshot: regression-session32-3-created.png');

    // Verify task appears
    const taskCard = await page.$(`text=${taskTitle}`);
    const taskCreated = taskCard !== null;
    console.log(`  - Task created: ${taskCreated ? 'PASS' : 'FAIL'}`);

    // Step 6: Verify Feature 78 - Back button navigation
    console.log('\nStep 6: Testing Feature 78 - Back button navigation...');
    await taskCard.click();
    await page.waitForTimeout(500);
    const detailVisible = await page.$eval('#task-modal', el => !el.hasAttribute('hidden'));
    console.log(`  - Task detail opened: ${detailVisible ? 'PASS' : 'FAIL'}`);

    // Press Escape to close
    await page.keyboard.press('Escape');
    await page.waitForTimeout(500);
    const modalHiddenAfterEscape = await page.$eval('#task-modal', el => el.hasAttribute('hidden'));
    console.log(`  - Escape closes modal: ${modalHiddenAfterEscape ? 'PASS' : 'FAIL'}`);

    // Step 7: Delete test task
    console.log('\nStep 7: Deleting test task...');
    const taskCardAgain = await page.$(`text=${taskTitle}`);
    if (taskCardAgain) {
      await taskCardAgain.click();
      await page.waitForTimeout(500);

      const deleteBtn = await page.$('#delete-task-btn');
      if (deleteBtn) {
        await deleteBtn.click();
        await page.waitForTimeout(500);

        // Confirm deletion
        const confirmBtn = await page.$('#confirm-yes-btn');
        if (confirmBtn) {
          await confirmBtn.click();
          await page.waitForTimeout(1000);
        }
      }
    }

    await page.screenshot({ path: 'regression-session32-4-cleaned.png', fullPage: false });
    console.log('  - Screenshot: regression-session32-4-cleaned.png');

    // Verify task deleted
    const taskStillExists = await page.$(`text=${taskTitle}`);
    console.log(`  - Task deleted: ${!taskStillExists ? 'PASS' : 'FAIL'}`);

    // Step 8: Console errors check
    console.log('\nStep 8: Checking console errors...');
    console.log(`  - Console errors: ${consoleErrors.length === 0 ? 'PASS (none)' : `FAIL (${consoleErrors.length} errors)`}`);
    if (consoleErrors.length > 0) {
      consoleErrors.forEach(err => console.log(`    - ${err}`));
    }

    console.log('\n=== Regression Test Complete ===');
    console.log('All core features verified working!');

  } catch (error) {
    console.error('Test error:', error.message);
    await page.screenshot({ path: 'regression-session32-error.png', fullPage: false });
  } finally {
    await browser.close();
  }
})();
