const { chromium } = require('playwright');

// Test Feature 18: Completed task visual state
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
        console.log('Onboarding dismissed');
      }
    }

    // Create a task
    const fab = await page.$('#add-task-btn');
    await fab.click();
    await page.waitForTimeout(500);

    await page.fill('#task-title', 'FEATURE_18_COMPLETE_TEST');
    await page.fill('#task-start-time', '09:00');
    await page.fill('#task-end-time', '10:00');

    const saveBtn = await page.$('button:has-text("Save Task")');
    await saveBtn.click();
    await page.waitForTimeout(1000);

    await page.screenshot({ path: 'regression-session33-feature18-1-created.png' });
    console.log('Task created');

    // Find the task card and swipe to complete
    const taskCard = await page.$('.task-card');
    const box = await taskCard.boundingBox();

    // Simulate swipe right (drag gesture)
    await page.mouse.move(box.x + 10, box.y + box.height / 2);
    await page.mouse.down();
    await page.mouse.move(box.x + 150, box.y + box.height / 2, { steps: 10 });
    await page.mouse.up();
    await page.waitForTimeout(1000);

    await page.screenshot({ path: 'regression-session33-feature18-2-after-swipe.png' });

    // Check if task has completed class
    const completedTask = await page.$('.task-card.completed');
    console.log('Completed task has visual state:', completedTask !== null ? 'PASS' : 'FAIL');

    // Check for checkmark indicator
    const checkmark = await page.$('.task-card.completed .completion-indicator');
    console.log('Completion indicator present:', checkmark !== null ? 'PASS' : 'FAIL');

    // Clean up - delete the task
    const taskToDelete = await page.$('.task-card');
    if (taskToDelete) {
      await taskToDelete.click();
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
    }

    await page.screenshot({ path: 'regression-session33-feature18-3-cleaned.png' });
    console.log('Cleanup completed');
    console.log('\n=== Feature 18 Regression Test Complete ===');

  } catch (error) {
    console.error('Error:', error.message);
    await page.screenshot({ path: 'regression-session33-feature18-error.png' });
  }

  await browser.close();
})();
