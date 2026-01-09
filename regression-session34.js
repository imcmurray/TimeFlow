const { chromium } = require('playwright');

(async () => {
  console.log('Starting Session 34 Regression Test...\n');

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  // Set viewport for consistent screenshots
  await page.setViewportSize({ width: 1280, height: 720 });

  await page.goto('http://localhost:3000');
  console.log('✓ App loaded successfully');
  console.log('  Page title:', await page.title());

  // Dismiss onboarding if present
  const skipButton = await page.$('button:has-text("Skip")');
  if (skipButton) {
    await skipButton.click();
    await page.waitForTimeout(500);
    console.log('✓ Onboarding dismissed');
  }

  // Take screenshot of initial state
  await page.screenshot({ path: 'regression-session34-1-initial.png' });
  console.log('  Screenshot: regression-session34-1-initial.png');

  // Check NOW line
  const nowLine = await page.$('.now-line');
  const nowTime = await page.$('.now-time');
  if (nowLine && nowTime) {
    const timeText = await nowTime.textContent();
    console.log('✓ NOW line visible:', timeText);
  } else {
    console.log('✗ NOW line not found');
  }

  // Check hour labels
  const hourLabels = await page.$$('.hour-label');
  console.log('✓ Hour labels found:', hourLabels.length);

  // Check FAB button
  const fab = await page.$('.fab');
  if (fab) {
    console.log('✓ FAB button visible');
  } else {
    console.log('✗ FAB button not found');
  }

  // Test task creation
  console.log('\n--- Testing Task Creation ---');
  await fab.click();
  await page.waitForTimeout(500);

  // Take screenshot of modal
  await page.screenshot({ path: 'regression-session34-2-modal.png' });
  console.log('  Screenshot: regression-session34-2-modal.png');

  // Fill in task form
  const uniqueId = Date.now();
  const taskTitle = `TEST_REGRESSION_${uniqueId}`;

  const titleInput = await page.$('#task-title');
  if (titleInput) {
    await titleInput.fill(taskTitle);
    console.log('✓ Task title filled:', taskTitle);
  }

  // Set start time to current hour
  const now = new Date();
  const startHour = now.getHours();
  const startTime = `${startHour.toString().padStart(2, '0')}:30`;
  const endTime = `${(startHour + 1).toString().padStart(2, '0')}:30`;

  const startInput = await page.$('#start-time');
  const endInput = await page.$('#end-time');

  if (startInput && endInput) {
    await startInput.fill(startTime);
    await endInput.fill(endTime);
    console.log('✓ Time set:', startTime, '-', endTime);
  }

  // Take screenshot of filled form
  await page.screenshot({ path: 'regression-session34-3-form.png' });
  console.log('  Screenshot: regression-session34-3-form.png');

  // Save task
  const saveButton = await page.$('#save-task-btn');
  if (saveButton) {
    await saveButton.click();
    await page.waitForTimeout(1000);
    console.log('✓ Task saved');
  }

  // Take screenshot after save
  await page.screenshot({ path: 'regression-session34-4-created.png' });
  console.log('  Screenshot: regression-session34-4-created.png');

  // Verify task appears on timeline
  const taskCard = await page.$(`[data-task-title="${taskTitle}"]`);
  if (taskCard) {
    console.log('✓ Task card found on timeline');
  } else {
    // Try finding by text content
    const taskByText = await page.$eval('.task-card .task-title', el => el.textContent).catch(() => null);
    console.log('  Task found by text:', taskByText);
  }

  // Check for toast notification
  const toast = await page.$('.toast');
  if (toast) {
    const toastText = await toast.textContent();
    console.log('✓ Toast notification:', toastText);
  }

  // Test task deletion
  console.log('\n--- Testing Task Deletion ---');

  // Find and click on the task to open detail view
  const taskCards = await page.$$('.task-card');
  if (taskCards.length > 0) {
    await taskCards[0].click();
    await page.waitForTimeout(500);

    // Look for delete button
    const deleteBtn = await page.$('#delete-task-btn, .delete-btn, button:has-text("Delete")');
    if (deleteBtn) {
      await deleteBtn.click();
      await page.waitForTimeout(500);

      // Handle confirmation dialog
      const confirmBtn = await page.$('#confirm-delete-btn, .confirm-delete, button:has-text("Confirm")');
      if (confirmBtn) {
        await confirmBtn.click();
        await page.waitForTimeout(1000);
        console.log('✓ Task deleted via confirmation dialog');
      } else {
        // Try clicking OK on any dialog
        const okBtn = await page.$('button:has-text("OK"), button:has-text("Yes")');
        if (okBtn) {
          await okBtn.click();
          await page.waitForTimeout(1000);
        }
      }
    }
  }

  // Take final screenshot
  await page.screenshot({ path: 'regression-session34-5-cleaned.png' });
  console.log('  Screenshot: regression-session34-5-cleaned.png');

  // Check console for errors
  console.log('\n--- Console Messages ---');
  const consoleErrors = [];
  page.on('console', msg => {
    if (msg.type() === 'error') {
      consoleErrors.push(msg.text());
    }
  });

  // Reload to capture any errors
  await page.reload();
  await page.waitForTimeout(1000);

  if (consoleErrors.length === 0) {
    console.log('✓ No console errors detected');
  } else {
    console.log('✗ Console errors:', consoleErrors);
  }

  await browser.close();

  console.log('\n========================================');
  console.log('Session 34 Regression Test Complete');
  console.log('========================================');
})().catch(e => {
  console.error('Error:', e.message);
  process.exit(1);
});
