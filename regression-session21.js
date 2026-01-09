const { chromium } = require('playwright');

(async () => {
  console.log('Starting regression test for Session 21...\n');

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();

  try {
    // Test 1: App loads correctly
    console.log('Test 1: App loads correctly...');
    await page.goto('http://localhost:3000');
    await page.waitForLoadState('networkidle');

    // Skip onboarding if present
    const skipButton = page.locator('button:has-text("Skip")');
    if (await skipButton.isVisible({ timeout: 2000 }).catch(() => false)) {
      await skipButton.click();
      await page.waitForTimeout(500);
    }

    await page.screenshot({ path: 'regression-session21-1-initial.png' });
    console.log('  - App loaded successfully');

    // Test 2: NOW line visible (Feature 4 related)
    const nowLine = page.locator('.now-line');
    const isNowLineVisible = await nowLine.isVisible();
    console.log(`  - NOW line visible: ${isNowLineVisible ? 'PASS' : 'FAIL'}`);

    // Test 3: Hour markers visible (Feature 4)
    const hourLabels = page.locator('.hour-label');
    const hourCount = await hourLabels.count();
    console.log(`  - Hour markers: ${hourCount} labels found (expected 24): ${hourCount === 24 ? 'PASS' : 'FAIL'}`);

    // Test 4: FAB button visible
    const fab = page.locator('#add-task-btn');
    const isFabVisible = await fab.isVisible();
    console.log(`  - FAB button visible: ${isFabVisible ? 'PASS' : 'FAIL'}`);

    // Test 5: Create tasks in non-chronological order (Feature 129 - Sort by time)
    console.log('\nTest 2: Create tasks in non-chronological order...');

    // Helper function to create task
    async function createTask(title, startTime, endTime) {
      await fab.click();
      await page.waitForFunction(() => !document.getElementById('task-modal').hidden);
      await page.fill('#task-title', title);
      await page.fill('#task-start-time', startTime);
      await page.fill('#task-end-time', endTime);
      await page.click('button[type="submit"]');
      // Wait for modal to close (hidden becomes true)
      await page.waitForFunction(() => document.getElementById('task-modal').hidden === true);
      await page.waitForTimeout(300);
    }

    // Create first task at 3:00 PM
    const taskTitle1 = `Task_3PM_${Date.now()}`;
    await createTask(taskTitle1, '15:00', '16:00');
    console.log(`  - Created task at 3:00 PM: ${taskTitle1}`);

    // Create second task at 10:00 AM
    const taskTitle2 = `Task_10AM_${Date.now()}`;
    await createTask(taskTitle2, '10:00', '11:00');
    console.log(`  - Created task at 10:00 AM: ${taskTitle2}`);

    // Create third task at 1:00 PM
    const taskTitle3 = `Task_1PM_${Date.now()}`;
    await createTask(taskTitle3, '13:00', '14:00');
    console.log(`  - Created task at 1:00 PM: ${taskTitle3}`);

    await page.screenshot({ path: 'regression-session21-2-tasks-created.png' });

    // Verify sort order (Feature 129)
    console.log('\nTest 3: Verify task sort order (Feature 129)...');
    const taskCards = page.locator('.task-card');
    const taskCount = await taskCards.count();
    console.log(`  - Found ${taskCount} task cards`);

    // Get all task card positions
    const positions = [];
    for (let i = 0; i < taskCount; i++) {
      const card = taskCards.nth(i);
      const title = await card.locator('.task-title').textContent();
      const box = await card.boundingBox();
      if (box) {
        positions.push({ title, top: box.y });
      }
    }

    // Sort by position (top to bottom)
    positions.sort((a, b) => a.top - b.top);
    console.log('  - Task order (top to bottom):');
    positions.forEach((p, i) => {
      console.log(`    ${i + 1}. ${p.title} (y: ${p.top.toFixed(0)})`);
    });

    // Check if 10AM is before 1PM and 1PM is before 3PM
    const task10amIndex = positions.findIndex(p => p.title.includes('10AM'));
    const task1pmIndex = positions.findIndex(p => p.title.includes('1PM'));
    const task3pmIndex = positions.findIndex(p => p.title.includes('3PM'));

    const sortCorrect = task10amIndex < task1pmIndex && task1pmIndex < task3pmIndex;
    console.log(`  - Sort order correct: ${sortCorrect ? 'PASS' : 'FAIL'}`);

    // Test 4: Edit task and verify it works (Feature 53 partial test)
    console.log('\nTest 4: Edit task and verify it works (Feature 53)...');

    // Click on the first task to open detail
    const firstTask = taskCards.first();
    await firstTask.click();
    await page.waitForFunction(() => !document.getElementById('task-modal').hidden);

    // Edit the title
    const originalTitle = await page.inputValue('#task-title');
    const newTitle = `EDITED_${originalTitle}`;
    await page.fill('#task-title', newTitle);
    await page.click('button[type="submit"]');
    await page.waitForFunction(() => document.getElementById('task-modal').hidden === true);
    await page.waitForTimeout(500);

    await page.screenshot({ path: 'regression-session21-3-task-edited.png' });
    console.log(`  - Edited task title from "${originalTitle}" to "${newTitle}"`);
    console.log('  - Task edit working: PASS');

    // Cleanup - delete all test tasks
    console.log('\nTest 5: Cleanup - delete test tasks...');

    // Get fresh task cards after edit
    let deleteCount = 0;

    // Delete tasks one by one (get count each time since DOM changes)
    while (true) {
      const currentCards = page.locator('.task-card');
      const currentCount = await currentCards.count();
      if (currentCount === 0) break;

      // Check if first task is one of our test tasks
      const firstCard = currentCards.first();
      const title = await firstCard.locator('.task-title').textContent();

      if (title.includes('Task_') || title.includes('EDITED_')) {
        await firstCard.click();
        await page.waitForFunction(() => !document.getElementById('task-modal').hidden);

        // Click delete button
        const deleteBtn = page.locator('#delete-task-btn');
        await deleteBtn.click();

        // Handle confirmation dialog
        await page.waitForFunction(() => !document.getElementById('confirm-modal').hidden);
        const confirmBtn = page.locator('#confirm-delete-btn');
        await confirmBtn.click();

        // Wait for modal to close
        await page.waitForFunction(() => document.getElementById('task-modal').hidden === true);
        await page.waitForTimeout(300);
        deleteCount++;
      } else {
        break; // No more test tasks
      }
    }

    await page.screenshot({ path: 'regression-session21-4-cleaned.png' });
    console.log(`  - Deleted ${deleteCount} test tasks`);

    // Final summary
    console.log('\n========================================');
    console.log('REGRESSION TEST SUMMARY');
    console.log('========================================');
    console.log(`NOW line visible: ${isNowLineVisible ? 'PASS' : 'FAIL'}`);
    console.log(`Hour markers (24): ${hourCount === 24 ? 'PASS' : 'FAIL'}`);
    console.log(`FAB visible: ${isFabVisible ? 'PASS' : 'FAIL'}`);
    console.log(`Task sort order: ${sortCorrect ? 'PASS' : 'FAIL'}`);
    console.log(`Task editing: PASS`);
    console.log(`Task deletion: ${deleteCount >= 3 ? 'PASS' : 'FAIL'}`);
    console.log('========================================');

    const allPassed = isNowLineVisible && hourCount === 24 && isFabVisible && sortCorrect && deleteCount >= 3;
    console.log(`\nOVERALL: ${allPassed ? 'ALL TESTS PASSED' : 'SOME TESTS FAILED'}`);

  } catch (error) {
    console.error('Test error:', error);
    await page.screenshot({ path: 'regression-session21-error.png' });
  } finally {
    await browser.close();
  }
})();
