const { chromium } = require('playwright');

(async () => {
  console.log('Starting regression test session 37...');

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  // Test 1: App launches successfully (Feature 1)
  console.log('\n=== Test 1: App launches successfully (Feature 1) ===');
  await page.goto('http://localhost:8080');
  await page.waitForTimeout(2000);

  // Dismiss onboarding modal if present
  const onboardingModal = await page.$('#onboarding-modal');
  if (onboardingModal) {
    const isVisible = await onboardingModal.isVisible();
    if (isVisible) {
      console.log('Onboarding modal detected, dismissing...');
      const skipBtn = await page.$('#onboarding-skip-btn');
      if (skipBtn) {
        await skipBtn.click();
        await page.waitForTimeout(500);
        console.log('Onboarding dismissed via Skip button');
      }
    }
  }

  await page.screenshot({ path: 'regression-session37-1-initial.png' });
  console.log('Screenshot saved: regression-session37-1-initial.png');

  // Check core elements
  const nowLine = await page.$('.now-line');
  const fabButton = await page.$('.fab');
  const timeline = await page.$('.timeline');
  const hourMarkers = await page.$$('.hour-marker');

  console.log('NOW line visible:', nowLine !== null ? 'PASS' : 'FAIL');
  console.log('FAB button visible:', fabButton !== null ? 'PASS' : 'FAIL');
  console.log('Timeline visible:', timeline !== null ? 'PASS' : 'FAIL');
  console.log('Hour markers count:', hourMarkers.length);

  // Test 2: Create a task for testing Feature 18 (Completed task visual state)
  console.log('\n=== Test 2: Create task and complete it (Feature 18) ===');
  await page.click('.fab');
  await page.waitForTimeout(500);
  await page.screenshot({ path: 'regression-session37-2-modal.png' });
  console.log('Screenshot saved: regression-session37-2-modal.png');

  // Fill the form with unique test data
  const testTitle = 'REGTEST_37_' + Date.now();
  await page.fill('#task-title', testTitle);
  await page.fill('#task-start-time', '10:00');
  await page.fill('#task-end-time', '11:00');
  await page.screenshot({ path: 'regression-session37-3-form.png' });
  console.log('Screenshot saved: regression-session37-3-form.png');

  // Save task - the save button is type="submit" in .form-actions
  await page.click('.form-actions button[type="submit"]');
  await page.waitForTimeout(1000);
  await page.screenshot({ path: 'regression-session37-4-created.png' });
  console.log('Screenshot saved: regression-session37-4-created.png');

  // Verify task was created
  const taskCard = await page.$('.task-card');
  console.log('Task card created:', taskCard !== null ? 'PASS' : 'FAIL');

  // Test 3: Complete the task via swipe (Feature 18)
  console.log('\n=== Test 3: Complete task via swipe (Feature 18) ===');
  if (taskCard) {
    const box = await taskCard.boundingBox();
    if (box) {
      // Simulate swipe right to complete
      await page.mouse.move(box.x + 10, box.y + box.height / 2);
      await page.mouse.down();
      await page.mouse.move(box.x + 200, box.y + box.height / 2, { steps: 10 });
      await page.mouse.up();
      await page.waitForTimeout(1000);
      await page.screenshot({ path: 'regression-session37-5-completed.png' });
      console.log('Screenshot saved: regression-session37-5-completed.png');

      // Check if task has completed styling
      const completedTask = await page.$('.task-card.completed');
      console.log('Task has completed class:', completedTask !== null ? 'PASS' : 'FAIL');
    }
  }

  // Test 4: Check rounded corners (Feature 42)
  console.log('\n=== Test 4: Check task card styling (Feature 42) ===');
  const taskCards = await page.$$('.task-card');
  if (taskCards.length > 0) {
    const borderRadius = await page.evaluate(() => {
      const card = document.querySelector('.task-card');
      if (card) {
        return window.getComputedStyle(card).borderRadius;
      }
      return null;
    });
    console.log('Task card border-radius:', borderRadius);
    console.log('Rounded corners:', borderRadius && borderRadius !== '0px' ? 'PASS' : 'FAIL');
  }

  // Test 5: Cleanup - delete the test task
  console.log('\n=== Test 5: Cleanup ===');

  // First close any open modal by clicking outside or close button
  const closeModalBtn = await page.$('.modal .close-btn');
  if (closeModalBtn) {
    await closeModalBtn.click();
    await page.waitForTimeout(500);
  }

  // Now click on the task card to open edit modal
  const remainingTask = await page.$('.task-card');
  if (remainingTask) {
    await remainingTask.click();
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
      }
    }
  }

  await page.screenshot({ path: 'regression-session37-6-cleaned.png' });
  console.log('Screenshot saved: regression-session37-6-cleaned.png');

  // Final verification - no test tasks remaining
  const finalTasks = await page.$$('.task-card');
  const testTasksRemaining = [];
  for (const task of finalTasks) {
    const text = await task.textContent();
    if (text && text.includes('REGTEST_37')) {
      testTasksRemaining.push(text);
    }
  }
  console.log('Test tasks remaining:', testTasksRemaining.length === 0 ? 'PASS (none)' : 'FAIL (' + testTasksRemaining.length + ')');

  // Check console errors
  console.log('\n=== Console Error Check ===');
  const consoleErrors = [];
  page.on('console', msg => {
    if (msg.type() === 'error') {
      consoleErrors.push(msg.text());
    }
  });
  await page.reload();
  await page.waitForTimeout(2000);
  console.log('Console errors:', consoleErrors.length === 0 ? 'PASS (none)' : 'FAIL (' + consoleErrors.length + ')');

  console.log('\n=== Regression Test Complete ===');
  await browser.close();
})();
