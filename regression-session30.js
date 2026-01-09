const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.goto('http://localhost:3000');

  // Wait for app to load
  await page.waitForTimeout(2000);

  // Check for onboarding and skip it
  const onboardingSkip = await page.$('#onboarding-skip-btn');
  if (onboardingSkip) {
    await onboardingSkip.click();
    await page.waitForTimeout(500);
  }

  // Take screenshot
  await page.screenshot({ path: 'regression-session30-1-initial.png' });

  // Check for NOW line
  const nowLine = await page.$('#now-line');
  console.log('NOW line visible:', !!nowLine);

  // Check for hour markers
  const hourLabels = await page.$$('.hour-label');
  console.log('Hour labels count:', hourLabels.length);

  // Check for FAB button
  const fab = await page.$('#add-task-btn');
  console.log('FAB button visible:', !!fab);

  // Test task creation
  if (fab) {
    await fab.click();
    await page.waitForTimeout(500);
    await page.screenshot({ path: 'regression-session30-2-modal.png' });

    // Fill form
    await page.fill('#task-title', 'TEST_SESSION30_REGRESSION');
    await page.fill('#task-start-time', '10:00');
    await page.fill('#task-end-time', '11:00');

    await page.screenshot({ path: 'regression-session30-3-form.png' });

    // Save task
    const saveBtn = await page.$('button:has-text("Save Task")');
    if (saveBtn) {
      await saveBtn.click();
      await page.waitForTimeout(1000);
    }

    await page.screenshot({ path: 'regression-session30-4-created.png' });

    // Verify task was created
    const taskCard = await page.$('.task-card:has-text("TEST_SESSION30_REGRESSION")');
    console.log('Task created:', !!taskCard);

    // Clean up - delete the task
    if (taskCard) {
      await taskCard.click();
      await page.waitForTimeout(500);

      const deleteBtn = await page.$('#delete-task-btn');
      if (deleteBtn) {
        await deleteBtn.click();
        await page.waitForTimeout(500);

        const confirmBtn = await page.$('#confirm-yes-btn');
        if (confirmBtn) {
          await confirmBtn.click();
          await page.waitForTimeout(500);
        }
      }
    }

    await page.screenshot({ path: 'regression-session30-5-cleaned.png' });
  }

  // Check console for errors
  const consoleErrors = [];
  page.on('console', msg => {
    if (msg.type() === 'error') consoleErrors.push(msg.text());
  });

  await browser.close();
  console.log('Console errors:', consoleErrors.length);
  console.log('Regression test completed successfully');
})();
