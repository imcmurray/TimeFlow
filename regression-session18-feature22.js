const { chromium } = require('playwright');

(async () => {
  console.log('Testing Feature 22: Quick Add with duration picker...');

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  await page.goto('http://localhost:3000');
  await page.waitForTimeout(1000);

  // Dismiss onboarding if present
  const skipButton = await page.locator('button:has-text("Skip")').first();
  if (await skipButton.isVisible()) {
    await skipButton.click();
    await page.waitForTimeout(500);
  }

  // Click FAB to open task creation
  await page.locator('#add-task-btn').click();
  await page.waitForTimeout(500);

  // Fill in task title
  const uniqueId = Date.now();
  await page.locator('#task-title').fill(`Duration Test ${uniqueId}`);

  // Set start time to 10:00
  await page.locator('#task-start-time').fill('10:00');

  // Check for duration picker buttons
  const duration45 = await page.locator('button:has-text("45m")');
  const duration45Visible = await duration45.isVisible();
  console.log('Duration 45m button visible:', duration45Visible);

  if (duration45Visible) {
    await duration45.click();
    await page.waitForTimeout(300);
  }

  // Check end time
  const endTime = await page.locator('#task-end-time').inputValue();
  console.log('End time after 45m button:', endTime);

  await page.screenshot({ path: 'regression-feature22-duration.png' });

  // Save task
  await page.locator('button.btn-primary:has-text("Save Task")').click();
  await page.waitForTimeout(1000);

  // Find the task on timeline
  const taskCard = await page.locator(`.task-card:has-text("Duration Test ${uniqueId}")`).first();
  const taskVisible = await taskCard.isVisible();
  console.log('Task created:', taskVisible);

  if (taskVisible) {
    // Check task time display
    const timeRange = await taskCard.locator('.task-time').textContent();
    console.log('Task time range:', timeRange);
  }

  await page.screenshot({ path: 'regression-feature22-created.png' });

  // Clean up - delete the task
  await taskCard.click();
  await page.waitForTimeout(500);
  await page.locator('#delete-task-btn').click();
  await page.waitForTimeout(300);
  await page.locator('#confirm-delete-btn').click();
  await page.waitForTimeout(500);

  await browser.close();

  // Verify results
  const expectedEnd = '10:45';
  const success = duration45Visible && endTime === expectedEnd && taskVisible;

  console.log('\n=== FEATURE 22 REGRESSION TEST ===');
  console.log('Duration picker visible:', duration45Visible ? 'PASS' : 'FAIL');
  console.log('End time correct (10:45):', endTime === expectedEnd ? 'PASS' : 'FAIL');
  console.log('Task created:', taskVisible ? 'PASS' : 'FAIL');
  console.log('Overall:', success ? 'PASS' : 'FAIL');
})();
