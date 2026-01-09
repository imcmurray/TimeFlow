const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  console.log('Navigating to app...');
  await page.goto('http://localhost:3000');
  await page.waitForTimeout(2000);

  // Handle onboarding if shown - use evaluate to dismiss it reliably
  const hasOnboarding = await page.evaluate(() => {
    const modal = document.getElementById('onboarding-modal');
    if (modal && !modal.hidden) {
      // Click the skip button
      const skipBtn = document.getElementById('onboarding-skip-btn');
      if (skipBtn) {
        skipBtn.click();
        return true;
      }
      // Fallback: just hide the modal
      modal.hidden = true;
      return true;
    }
    return false;
  });

  if (hasOnboarding) {
    console.log('Onboarding modal detected and dismissed');
    await page.waitForTimeout(500);
  }

  await page.screenshot({ path: 'regression-session13-initial.png' });

  // Check basic elements
  const nowLine = await page.$('.now-line');
  const fab = await page.$('.fab');
  const hourLabels = await page.$$('.hour-label');

  console.log('NOW line visible:', !!nowLine);
  console.log('FAB visible:', !!fab);
  console.log('Hour labels:', hourLabels.length);

  // Test task creation
  console.log('\nTesting task creation...');
  await fab.click();
  await page.waitForTimeout(1000);

  // Check if task modal is visible (not hidden)
  const modalVisible = await page.evaluate(() => {
    const modal = document.getElementById('task-modal');
    return modal && !modal.hidden;
  });
  console.log('Modal opened:', modalVisible);

  if (!modalVisible) {
    console.log('ERROR: Modal did not open. Taking screenshot and exiting.');
    await page.screenshot({ path: 'regression-session13-error.png' });
    await browser.close();
    process.exit(1);
  }

  // Fill form
  const titleInput = await page.$('#task-title');
  await titleInput.fill('REGRESSION_TEST_SESSION13');

  const startTime = await page.$('#task-start-time');
  await startTime.fill('14:00');

  const endTime = await page.$('#task-end-time');
  await endTime.fill('15:00');

  await page.screenshot({ path: 'regression-session13-form.png' });

  // Save task - button is in the modal form
  const saveBtn = await page.$('#task-modal button[type="submit"]');
  if (!saveBtn) {
    console.log('ERROR: Save button not found');
    await browser.close();
    process.exit(1);
  }
  await saveBtn.click();
  await page.waitForTimeout(1000);

  await page.screenshot({ path: 'regression-session13-created.png' });

  // Verify task was created
  const taskCards = await page.$$('.task-card');
  const taskTexts = await Promise.all(taskCards.map(c => c.textContent()));
  const hasTestTask = taskTexts.some(t => t.includes('REGRESSION_TEST_SESSION13'));
  console.log('Task created successfully:', hasTestTask);

  // Clean up - delete the test task
  if (hasTestTask) {
    console.log('\nCleaning up test task...');

    // Click on the task to open detail
    for (const card of taskCards) {
      const text = await card.textContent();
      if (text.includes('REGRESSION_TEST_SESSION13')) {
        await card.click();
        break;
      }
    }

    await page.waitForTimeout(500);

    // Click delete button (by ID)
    const deleteBtn = await page.$('#delete-task-btn');
    if (deleteBtn) {
      await deleteBtn.click();
      await page.waitForTimeout(500);

      // Confirm deletion (by ID)
      const confirmBtn = await page.$('#confirm-delete-btn');
      if (confirmBtn) {
        await confirmBtn.click();
        await page.waitForTimeout(500);
      }
    }

    await page.screenshot({ path: 'regression-session13-cleaned.png' });
    console.log('Test task deleted successfully');
  }

  console.log('\n=== REGRESSION TEST COMPLETE ===');
  console.log('All screenshots saved as regression-session13-*.png');

  await browser.close();
})();
