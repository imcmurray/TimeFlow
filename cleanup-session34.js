const { chromium } = require('playwright');

(async () => {
  console.log('Cleaning up test tasks...\n');

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.setViewportSize({ width: 1280, height: 800 });

  await page.goto('http://localhost:3000');

  // Dismiss onboarding if present
  const skipButton = await page.$('button:has-text("Skip")');
  if (skipButton) {
    await skipButton.click();
    await page.waitForTimeout(500);
  }

  // Find and delete all test tasks
  let taskCards = await page.$$('.task-card');
  console.log(`Found ${taskCards.length} task(s) to clean up`);

  while (taskCards.length > 0) {
    const task = taskCards[0];

    // Click on task to open detail modal
    await task.click();
    await page.waitForTimeout(500);

    // Find and click delete button
    const deleteBtn = await page.$('button:has-text("Delete")');
    if (deleteBtn) {
      await deleteBtn.scrollIntoViewIfNeeded();
      await deleteBtn.click();
      await page.waitForTimeout(500);

      // Find confirm dialog and click confirm
      const confirmDialog = await page.$('.confirm-dialog, .dialog-overlay:not([hidden])');
      if (confirmDialog) {
        const confirmDeleteBtn = await page.$('.confirm-delete, .dialog-overlay button:has-text("Delete")');
        if (confirmDeleteBtn) {
          await confirmDeleteBtn.click();
          await page.waitForTimeout(500);
        }
      }
    } else {
      // Close modal if no delete button found
      await page.keyboard.press('Escape');
      await page.waitForTimeout(300);
    }

    // Get updated task list
    taskCards = await page.$$('.task-card');
  }

  // Take final screenshot
  await page.screenshot({ path: 'regression-session34-cleanup-final.png' });
  console.log('✓ Cleanup complete');

  await browser.close();
})().catch(e => {
  console.error('Error:', e.message);
  process.exit(1);
});
