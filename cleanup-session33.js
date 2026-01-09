const { chromium } = require('playwright');

// Cleanup script - delete any test tasks
(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  try {
    await page.goto('http://localhost:3000');
    await page.waitForTimeout(2000);

    // Dismiss onboarding if visible
    const skipBtn = await page.$('#onboarding-skip-btn');
    if (skipBtn) {
      const isVisible = await skipBtn.isVisible();
      if (isVisible) {
        await skipBtn.click();
        await page.waitForTimeout(500);
      }
    }

    // Close any open modals with Escape
    await page.keyboard.press('Escape');
    await page.waitForTimeout(500);
    await page.keyboard.press('Escape');
    await page.waitForTimeout(500);

    // Delete all visible task cards
    let taskCards = await page.$$('.task-card');
    console.log('Found', taskCards.length, 'task cards to delete');

    while (taskCards.length > 0) {
      const taskCard = taskCards[0];
      await taskCard.click();
      await page.waitForTimeout(500);

      const deleteBtn = await page.$('#delete-task-btn');
      if (deleteBtn) {
        await deleteBtn.click();
        await page.waitForTimeout(500);

        const confirmBtn = await page.$('#confirm-yes');
        if (confirmBtn) {
          await confirmBtn.click();
          await page.waitForTimeout(500);
        }
      }

      // Refresh task cards list
      taskCards = await page.$$('.task-card');
    }

    console.log('Cleanup complete - all tasks deleted');
    await page.screenshot({ path: 'regression-session33-final-cleanup.png' });

  } catch (error) {
    console.error('Error:', error.message);
  }

  await browser.close();
})();
