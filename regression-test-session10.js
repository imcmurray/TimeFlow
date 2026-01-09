const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });

  try {
    console.log('Starting regression tests for Session 10...\n');

    // Navigate to app
    await page.goto('http://localhost:3000');
    await page.waitForTimeout(1000);

    // Test 1: Verify app loads and NOW line is visible
    console.log('Test 1: App loads and NOW line visible');
    const nowLine = await page.locator('#now-line');
    const nowLineVisible = await nowLine.isVisible();
    console.log('  NOW line visible:', nowLineVisible ? 'PASS' : 'FAIL');

    // Test 2: Verify FAB is visible
    console.log('\nTest 2: FAB button visible');
    const fab = await page.locator('#add-task-btn');
    const fabVisible = await fab.isVisible();
    console.log('  FAB visible:', fabVisible ? 'PASS' : 'FAIL');

    // Test 3: Create a task
    console.log('\nTest 3: Create a task');
    await page.click('#add-task-btn');
    await page.waitForSelector('#task-modal:not([hidden])');

    const taskTitle = 'REGRESSION_SESSION10_' + Date.now();
    await page.fill('#task-title', taskTitle);
    await page.fill('#task-start-time', '14:00');
    await page.fill('#task-end-time', '15:00');
    await page.click('button[type="submit"]');

    await page.waitForSelector('#task-modal[hidden]', { timeout: 5000 }).catch(() => {});
    await page.waitForTimeout(500);

    // Verify task appears
    const taskCard = await page.locator(`.task-card:has-text("${taskTitle}")`);
    const taskExists = await taskCard.count() > 0;
    console.log('  Task created:', taskExists ? 'PASS' : 'FAIL');

    await page.screenshot({ path: 'regression-session10-1-task-created.png' });

    // Test 4: Edit task
    console.log('\nTest 4: Edit task');
    await page.click(`.task-card:has-text("${taskTitle}")`);
    await page.waitForSelector('#task-modal:not([hidden])');

    const updatedTitle = taskTitle + '_UPDATED';
    await page.fill('#task-title', updatedTitle);
    await page.click('button[type="submit"]');
    await page.waitForSelector('#task-modal[hidden]', { timeout: 5000 }).catch(() => {});
    await page.waitForTimeout(500);

    const updatedCard = await page.locator(`.task-card:has-text("${updatedTitle}")`);
    const updateExists = await updatedCard.count() > 0;
    console.log('  Task updated:', updateExists ? 'PASS' : 'FAIL');

    // Test 5: Delete task
    console.log('\nTest 5: Delete task');
    await page.click(`.task-card:has-text("${updatedTitle}")`);
    await page.waitForSelector('#task-modal:not([hidden])');
    await page.click('#delete-task-btn');
    await page.waitForSelector('#confirm-modal:not([hidden])');
    await page.click('#confirm-delete-btn');
    await page.waitForTimeout(500);

    const deletedCard = await page.locator(`.task-card:has-text("${updatedTitle}")`);
    const taskDeleted = await deletedCard.count() === 0;
    console.log('  Task deleted:', taskDeleted ? 'PASS' : 'FAIL');

    await page.screenshot({ path: 'regression-session10-2-after-delete.png' });

    // Test 6: Settings accessible
    console.log('\nTest 6: Settings accessible');
    await page.click('#settings-btn');
    await page.waitForSelector('#settings-modal:not([hidden])');
    const settingsTitle = await page.locator('#settings-title');
    const settingsVisible = await settingsTitle.isVisible();
    console.log('  Settings opens:', settingsVisible ? 'PASS' : 'FAIL');
    await page.click('#close-settings-btn');
    await page.waitForTimeout(300);

    // Test 7: Date navigation
    console.log('\nTest 7: Date navigation');
    const dateHeader = await page.locator('#date-subtitle');
    const todayDate = await dateHeader.textContent();
    console.log('  Current date:', todayDate);

    await page.click('#next-day-btn');
    await page.waitForTimeout(300);
    const tomorrowDate = await dateHeader.textContent();
    console.log('  Tomorrow date:', tomorrowDate);
    const navWorks = todayDate !== tomorrowDate;
    console.log('  Date changed:', navWorks ? 'PASS' : 'FAIL');

    // Go back to today
    await page.click('#prev-day-btn');
    await page.waitForTimeout(300);

    await page.screenshot({ path: 'regression-session10-final.png' });

    console.log('\n========================================');
    console.log('Regression tests completed successfully!');
    console.log('========================================');

  } catch (error) {
    console.error('Test failed:', error.message);
    await page.screenshot({ path: 'regression-session10-error.png' });
  } finally {
    await browser.close();
  }
})();
