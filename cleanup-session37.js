const { chromium } = require('playwright');

(async () => {
  console.log('Cleaning up test tasks from session 37...');

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  await page.goto('http://localhost:8080');
  await page.waitForTimeout(2000);

  // Dismiss onboarding if present
  const skipBtn = await page.$('#onboarding-skip-btn');
  if (skipBtn) {
    const isVisible = await skipBtn.isVisible();
    if (isVisible) {
      await skipBtn.click();
      await page.waitForTimeout(500);
    }
  }

  // Find and delete any REGTEST tasks
  let tasksDeleted = 0;
  let maxAttempts = 10;

  for (let i = 0; i < maxAttempts; i++) {
    const taskCards = await page.$$('.task-card');
    let foundTestTask = false;

    for (const card of taskCards) {
      const text = await card.textContent();
      if (text && text.includes('REGTEST')) {
        console.log('Found test task:', text.substring(0, 50));
        foundTestTask = true;

        // Click to open edit modal
        await card.click();
        await page.waitForTimeout(500);

        // Click delete button
        const deleteBtn = await page.$('#delete-task-btn');
        if (deleteBtn) {
          await deleteBtn.click();
          await page.waitForTimeout(500);

          // Confirm deletion
          const confirmBtn = await page.$('.confirm-btn');
          if (confirmBtn) {
            await confirmBtn.click();
            await page.waitForTimeout(1000);
            tasksDeleted++;
            console.log('Task deleted');
          }
        }
        break;
      }
    }

    if (!foundTestTask) {
      console.log('No more test tasks found');
      break;
    }
  }

  console.log('Total tasks deleted:', tasksDeleted);
  await page.screenshot({ path: 'regression-session37-cleanup-final.png' });
  console.log('Final screenshot saved');

  await browser.close();
})();
