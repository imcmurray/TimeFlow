const { chromium } = require('playwright');

(async () => {
  console.log('Starting regression test...');

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  // Navigate to app
  await page.goto('http://localhost:3000');
  await page.waitForTimeout(1000);

  // Dismiss onboarding if present
  const skipButton = await page.locator('button:has-text("Skip")').first();
  if (await skipButton.isVisible()) {
    await skipButton.click();
    await page.waitForTimeout(500);
  }

  await page.screenshot({ path: 'regression-session18-1-initial.png' });
  console.log('Screenshot 1: Initial state');

  // Check NOW line is visible
  const nowLine = await page.locator('.now-line').isVisible();
  console.log('NOW line visible:', nowLine);

  // Check FAB button is visible
  const fabBtn = await page.locator('#add-task-btn').isVisible();
  console.log('FAB button visible:', fabBtn);

  // Check hour markers (uses hour-label class)
  const hourMarkers = await page.locator('.hour-label').count();
  console.log('Hour markers count:', hourMarkers);

  // Test task creation
  await page.locator('#add-task-btn').click();
  await page.waitForTimeout(500);
  await page.screenshot({ path: 'regression-session18-2-modal.png' });
  console.log('Screenshot 2: Task modal open');

  // Fill in task details
  const uniqueId = Date.now();
  await page.locator('#task-title').fill(`Regression Test Task ${uniqueId}`);
  await page.locator('#task-description').fill('This is a regression test task description');
  await page.screenshot({ path: 'regression-session18-3-form-filled.png' });
  console.log('Screenshot 3: Form filled');

  // Save task
  await page.locator('button.btn-primary:has-text("Save Task")').click();
  await page.waitForTimeout(1000);
  await page.screenshot({ path: 'regression-session18-4-task-created.png' });
  console.log('Screenshot 4: Task created');

  // Verify task exists
  const taskCard = await page.locator(`.task-card:has-text("Regression Test Task ${uniqueId}")`).first();
  const taskVisible = await taskCard.isVisible();
  console.log('Task visible on timeline:', taskVisible);

  // Click on the task to view details
  await taskCard.click();
  await page.waitForTimeout(500);
  await page.screenshot({ path: 'regression-session18-5-task-detail.png' });
  console.log('Screenshot 5: Task detail view');

  // Delete the task
  await page.locator('#delete-task-btn').click();
  await page.waitForTimeout(500);

  // Confirm deletion
  const confirmBtn = await page.locator('#confirm-delete-btn');
  if (await confirmBtn.isVisible()) {
    await confirmBtn.click();
    await page.waitForTimeout(500);
  }

  await page.screenshot({ path: 'regression-session18-6-cleaned.png' });
  console.log('Screenshot 6: Task deleted');

  // Check for console errors
  const consoleMessages = [];
  page.on('console', msg => {
    if (msg.type() === 'error') {
      consoleMessages.push(msg.text());
    }
  });

  await browser.close();

  console.log('\n=== REGRESSION TEST RESULTS ===');
  console.log('NOW line visible:', nowLine ? 'PASS' : 'FAIL');
  console.log('FAB button visible:', fabBtn ? 'PASS' : 'FAIL');
  console.log('Hour markers (24):', hourMarkers === 24 ? 'PASS' : 'FAIL');
  console.log('Task creation:', taskVisible ? 'PASS' : 'FAIL');
  console.log('Console errors:', consoleMessages.length === 0 ? 'NONE' : consoleMessages.join(', '));
  console.log('\nRegression test complete!');
})();
