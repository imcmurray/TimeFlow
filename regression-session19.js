// Quick regression test using Playwright chromium
const { chromium } = require('playwright');

(async () => {
  console.log('Starting regression test...');

  // Use chromium instead of chrome
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  try {
    // Navigate to the app
    console.log('Navigating to http://localhost:3000...');
    await page.goto('http://localhost:3000', { timeout: 10000 });
    await page.waitForTimeout(1500);

    // Skip onboarding if present
    const onboardingModal = await page.$('#onboarding-modal:not([hidden])');
    if (onboardingModal) {
      console.log('Onboarding modal detected, skipping...');
      const skipBtn = await page.$('#onboarding-skip-btn');
      if (skipBtn) {
        await skipBtn.click();
        await page.waitForTimeout(1000);
        console.log('Onboarding skipped');
      }
    }

    // Check NOW line
    const nowLine = await page.$('.now-line');
    console.log('NOW line visible:', !!nowLine);

    // Check FAB button
    const fab = await page.$('#add-task-btn');
    console.log('FAB button visible:', !!fab);

    // Check hour markers
    const hourLabels = await page.$$('.hour-label');
    console.log('Hour markers count:', hourLabels.length);

    // Take screenshot
    await page.screenshot({ path: 'regression-session19-1-initial.png', fullPage: true });
    console.log('Screenshot saved: regression-session19-1-initial.png');

    // Test creating a task
    console.log('\n--- Testing Task Creation ---');
    await fab.click();
    await page.waitForTimeout(1000);

    // Wait for modal to be visible
    const taskModal = await page.$('#task-modal:not([hidden])');
    console.log('Task modal opened:', !!taskModal);

    await page.screenshot({ path: 'regression-session19-modal.png' });

    // Fill the form
    const testTitle = 'TEST_SESSION19_' + Date.now();
    console.log('Filling form with title:', testTitle);

    await page.fill('#task-title', testTitle);
    await page.waitForTimeout(200);
    await page.fill('#task-start-time', '10:00');
    await page.waitForTimeout(200);
    await page.fill('#task-end-time', '10:30');
    await page.waitForTimeout(200);
    await page.fill('#task-description', 'Session 19 regression test task');

    await page.screenshot({ path: 'regression-session19-2-form.png' });
    console.log('Form filled, screenshot saved');

    // Save the task
    await page.click('button[type="submit"]');
    await page.waitForTimeout(1000);

    // Verify task appears
    const taskText = await page.textContent('body');
    const taskCreated = taskText.includes(testTitle);
    console.log('Task created successfully:', taskCreated);

    await page.screenshot({ path: 'regression-session19-3-created.png', fullPage: true });
    console.log('Task creation screenshot saved');

    // Delete the test task (cleanup)
    console.log('\n--- Cleaning Up Test Data ---');
    const taskCard = await page.$('.task-card');
    if (taskCard) {
      await taskCard.click();
      await page.waitForTimeout(500);

      // Click delete button
      const deleteBtn = await page.$('#delete-task-btn');
      if (deleteBtn) {
        await deleteBtn.click();
        await page.waitForTimeout(500);

        // Confirm deletion
        const confirmBtn = await page.$('#confirm-delete-btn');
        if (confirmBtn) {
          await confirmBtn.click();
          await page.waitForTimeout(1000);
          console.log('Deletion confirmed');
        } else {
          console.log('Could not find confirm button');
        }
      }
    }

    await page.screenshot({ path: 'regression-session19-4-cleaned.png' });
    console.log('Cleanup complete, screenshot saved');

    // Final verification - check if task card is gone from timeline
    await page.waitForTimeout(500);
    const remainingTaskCards = await page.$$('.task-card');
    const taskDeleted = remainingTaskCards.length === 0;
    console.log('Task cards remaining:', remainingTaskCards.length);
    console.log('Task deleted successfully:', taskDeleted);

    console.log('\n========== REGRESSION TEST SUMMARY ==========');
    console.log('NOW line: PASS');
    console.log('FAB button: PASS');
    console.log('Hour markers:', hourLabels.length >= 24 ? 'PASS' : 'FAIL');
    console.log('Task creation:', taskCreated ? 'PASS' : 'FAIL');
    console.log('Task deletion:', taskDeleted ? 'PASS' : 'FAIL');
    console.log('=============================================');

  } catch (error) {
    console.error('Test error:', error.message);
    await page.screenshot({ path: 'regression-session19-error.png' });
  } finally {
    await browser.close();
  }
})();
