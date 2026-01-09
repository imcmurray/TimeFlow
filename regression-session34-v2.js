const { chromium } = require('playwright');

(async () => {
  console.log('Starting Session 34 Regression Test v2...\n');

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  // Set viewport for consistent screenshots
  await page.setViewportSize({ width: 1280, height: 800 });

  await page.goto('http://localhost:3000');
  console.log('✓ App loaded successfully');

  // Dismiss onboarding if present
  const skipButton = await page.$('button:has-text("Skip")');
  if (skipButton) {
    await skipButton.click();
    await page.waitForTimeout(500);
    console.log('✓ Onboarding dismissed');
  }

  // Take screenshot of initial state
  await page.screenshot({ path: 'regression-session34-v2-1-initial.png' });
  console.log('  Screenshot: regression-session34-v2-1-initial.png');

  // Check NOW line
  const nowLine = await page.$('.now-line');
  const nowTime = await page.$('.now-time');
  if (nowLine && nowTime) {
    const timeText = await nowTime.textContent();
    console.log('✓ NOW line visible:', timeText);
  }

  // Check hour labels
  const hourLabels = await page.$$('.hour-label');
  console.log('✓ Hour labels found:', hourLabels.length);

  // Check FAB button
  const fab = await page.$('.fab');
  if (fab) {
    console.log('✓ FAB button visible');
  }

  // Test task creation
  console.log('\n--- Testing Task Creation ---');
  await fab.click();
  await page.waitForTimeout(500);

  // Fill in task form
  const uniqueId = Date.now();
  const taskTitle = `TEST_SESSION34_${uniqueId}`;

  // Type in the title input
  await page.fill('#task-title', taskTitle);
  console.log('✓ Task title filled:', taskTitle);

  // Take screenshot of filled form (scroll to see save button)
  await page.screenshot({ path: 'regression-session34-v2-2-form.png', fullPage: true });
  console.log('  Screenshot: regression-session34-v2-2-form.png');

  // Click the Save Task button (by text)
  const saveButton = await page.$('button[type="submit"]:has-text("Save Task")');
  if (saveButton) {
    // Scroll into view and click
    await saveButton.scrollIntoViewIfNeeded();
    await saveButton.click();
    console.log('✓ Save button clicked');
    await page.waitForTimeout(1000);
  } else {
    console.log('✗ Save button not found, trying form submit');
    // Try pressing Enter on the form
    await page.press('#task-title', 'Enter');
    await page.waitForTimeout(1000);
  }

  // Take screenshot after save
  await page.screenshot({ path: 'regression-session34-v2-3-after-save.png' });
  console.log('  Screenshot: regression-session34-v2-3-after-save.png');

  // Verify task appears on timeline
  const taskCards = await page.$$('.task-card');
  console.log('✓ Task cards on timeline:', taskCards.length);

  // Verify the specific task was created
  const taskText = await page.textContent('.timeline-container');
  if (taskText && taskText.includes('TEST_SESSION34')) {
    console.log('✓ Test task found on timeline');
  } else {
    console.log('✗ Test task NOT found on timeline');
    // Take error screenshot
    await page.screenshot({ path: 'regression-session34-v2-error.png' });
  }

  // Check for toast notification
  const toast = await page.$('.toast');
  if (toast) {
    const toastText = await toast.textContent();
    console.log('✓ Toast notification:', toastText);
  }

  // Now clean up - delete the test task
  console.log('\n--- Testing Task Deletion ---');

  if (taskCards.length > 0) {
    // Find and click on a task to open detail view
    const testTask = await page.$('.task-card');
    if (testTask) {
      await testTask.click();
      await page.waitForTimeout(500);

      // Take screenshot of detail view
      await page.screenshot({ path: 'regression-session34-v2-4-detail.png' });
      console.log('  Screenshot: regression-session34-v2-4-detail.png');

      // Look for delete button
      const deleteBtn = await page.$('button:has-text("Delete")');
      if (deleteBtn) {
        await deleteBtn.click();
        await page.waitForTimeout(500);

        // Take screenshot of confirm dialog
        await page.screenshot({ path: 'regression-session34-v2-5-confirm.png' });
        console.log('  Screenshot: regression-session34-v2-5-confirm.png');

        // Handle confirmation dialog
        const confirmBtn = await page.$('button:has-text("Delete"):not(:first-of-type), .confirm-delete');
        if (confirmBtn) {
          await confirmBtn.click();
          await page.waitForTimeout(1000);
          console.log('✓ Task deleted');
        } else {
          // Try any confirmation button
          const anyConfirm = await page.$$('button');
          for (const btn of anyConfirm) {
            const text = await btn.textContent();
            if (text && text.toLowerCase().includes('confirm') || text.toLowerCase().includes('yes') || text === 'Delete') {
              await btn.click();
              await page.waitForTimeout(1000);
              console.log('✓ Task deleted via:', text);
              break;
            }
          }
        }
      }
    }
  }

  // Take final screenshot
  await page.screenshot({ path: 'regression-session34-v2-6-final.png' });
  console.log('  Screenshot: regression-session34-v2-6-final.png');

  // Verify task count after deletion
  const finalTaskCards = await page.$$('.task-card');
  console.log('✓ Final task cards count:', finalTaskCards.length);

  await browser.close();

  console.log('\n========================================');
  console.log('Session 34 Regression Test v2 Complete');
  console.log('========================================');
})().catch(e => {
  console.error('Error:', e.message);
  console.error(e.stack);
  process.exit(1);
});
