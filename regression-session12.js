const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  console.log('Navigating to app...');
  await page.goto('http://localhost:3000');
  await page.waitForTimeout(2000);

  // Check for onboarding modal and skip it if present
  const skipButton = await page.$('#onboarding-skip-btn');
  if (skipButton) {
    const isVisible = await skipButton.isVisible();
    if (isVisible) {
      console.log('Skipping onboarding...');
      await skipButton.click();
      await page.waitForTimeout(500);
    }
  }

  // Take initial screenshot
  await page.screenshot({ path: 'regression-session12-1-initial.png' });
  console.log('Screenshot 1: Initial state');

  // Check NOW line
  const nowLine = await page.$('#now-line');
  console.log('NOW line visible:', !!nowLine);

  // Check FAB
  const fab = await page.$('#add-task-btn');
  console.log('FAB visible:', !!fab);

  // Check hour markers (they may be inside timeline)
  const timeline = await page.$('#timeline');
  const timelineHtml = timeline ? await timeline.innerHTML() : '';
  const hourMarkerCount = (timelineHtml.match(/hour-marker/g) || []).length;
  console.log('Hour markers count:', hourMarkerCount);

  // Create a test task
  console.log('Creating test task...');
  await fab.click();
  await page.waitForTimeout(500);

  // Fill in task details
  const taskTitle = 'REGRESSION_TEST_SESSION12_' + Date.now();
  await page.fill('#task-title', taskTitle);

  // Set time to current hour
  const now = new Date();
  const startHour = now.getHours().toString().padStart(2, '0');
  const startTime = `${startHour}:00`;
  const endTime = `${startHour}:30`;

  await page.fill('#task-start-time', startTime);
  await page.fill('#task-end-time', endTime);

  await page.screenshot({ path: 'regression-session12-2-form-filled.png' });
  console.log('Screenshot 2: Form filled');

  // Save task - find the submit button
  const saveButton = await page.$('#task-form button.btn-primary');
  if (saveButton) {
    await saveButton.click();
  } else {
    console.log('Save button not found, trying form submit...');
    await page.click('#task-form button[type="submit"]');
  }
  await page.waitForTimeout(1500);

  await page.screenshot({ path: 'regression-session12-3-task-created.png' });
  console.log('Screenshot 3: Task created');

  // Check task was created
  const taskCards = await page.$$('.task-card');
  console.log('Task cards count:', taskCards.length);

  // Verify task title in timeline
  const pageContent = await page.content();
  const hasTestTask = pageContent.includes('REGRESSION_TEST_SESSION12');
  console.log('Test task found in timeline:', hasTestTask);

  // Check for console errors
  const messages = [];
  page.on('console', msg => {
    if (msg.type() === 'error') {
      messages.push(msg.text());
    }
  });

  // Clean up - delete the test task
  if (taskCards.length > 0) {
    console.log('Cleaning up test task...');
    await taskCards[0].click();
    await page.waitForTimeout(500);

    // Find and click delete button
    const deleteButton = await page.$('#delete-task-btn');
    if (deleteButton) {
      const isVisible = await deleteButton.isVisible();
      if (isVisible) {
        await deleteButton.click();
        await page.waitForTimeout(300);

        // Confirm delete
        const confirmButton = await page.$('#confirm-delete-btn');
        if (confirmButton) {
          await confirmButton.click();
          await page.waitForTimeout(500);
        }
      }
    }
  }

  await page.screenshot({ path: 'regression-session12-4-cleaned.png' });
  console.log('Screenshot 4: Cleaned up');

  // Final task count
  const finalTaskCards = await page.$$('.task-card');
  const wasDeleted = finalTaskCards.length < taskCards.length;
  console.log('Task deleted successfully:', wasDeleted);

  // Summary
  console.log('\n=== REGRESSION TEST SUMMARY ===');
  console.log('NOW line: ' + (nowLine ? 'PASS' : 'FAIL'));
  console.log('FAB button: ' + (fab ? 'PASS' : 'FAIL'));
  console.log('Hour markers: ' + (hourMarkerCount >= 24 ? 'PASS' : 'FAIL') + ' (' + hourMarkerCount + ')');
  console.log('Task creation: ' + (hasTestTask ? 'PASS' : 'FAIL'));
  console.log('Task deletion: ' + (wasDeleted ? 'PASS' : 'FAIL'));
  console.log('===============================\n');

  await browser.close();
  console.log('Browser closed. Regression test complete.');
})();
