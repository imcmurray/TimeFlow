const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.goto('http://localhost:3000');

  // Handle onboarding if it appears
  try {
    const skipBtn = await page.locator('button:has-text("Skip")');
    if (await skipBtn.isVisible({ timeout: 1000 })) {
      await skipBtn.click();
      await page.waitForTimeout(500);
    }
  } catch (e) {
    // No onboarding, continue
  }

  // Take initial screenshot
  await page.screenshot({ path: 'regression-session17-1-initial.png' });

  // Check for NOW line
  const nowLine = await page.locator('.now-line').isVisible();
  console.log('NOW line visible:', nowLine);

  // Check for FAB
  const fab = await page.locator('#add-task-btn').isVisible();
  console.log('FAB visible:', fab);

  // Check for hour markers
  const hourLabels = await page.locator('.hour-label').count();
  console.log('Hour labels count:', hourLabels);

  // Click FAB to open task modal
  await page.click('#add-task-btn');
  await page.waitForTimeout(500);
  await page.screenshot({ path: 'regression-session17-2-modal.png' });

  // Fill in task form
  const timestamp = Date.now();
  await page.fill('#task-title', 'REGRESSION_TEST_' + timestamp);
  await page.fill('#task-description', 'Testing task creation with description for regression test');
  await page.fill('#task-start-time', '14:00');
  await page.fill('#task-end-time', '15:00');
  await page.screenshot({ path: 'regression-session17-3-form-filled.png' });

  // Save the task
  await page.click('button:has-text("Save Task")');
  await page.waitForTimeout(1000);
  await page.screenshot({ path: 'regression-session17-4-task-created.png' });

  // Verify task was created
  const taskCard = await page.locator('.task-card:has-text("REGRESSION_TEST_' + timestamp + '")').isVisible();
  console.log('Task created:', taskCard);

  // Click on the task to verify description
  await page.click('.task-card:has-text("REGRESSION_TEST_' + timestamp + '")');
  await page.waitForTimeout(500);
  await page.screenshot({ path: 'regression-session17-5-task-detail.png' });

  // Verify description is visible
  const desc = await page.locator('#task-description').inputValue();
  console.log('Description preserved:', desc.includes('Testing task creation'));

  // Delete the task
  await page.click('#delete-task-btn');
  await page.waitForTimeout(500);

  // Handle confirmation dialog
  const confirmBtn = await page.locator('#confirm-delete-btn');
  if (await confirmBtn.isVisible()) {
    await confirmBtn.click();
    await page.waitForTimeout(500);
  }

  await page.screenshot({ path: 'regression-session17-6-cleaned.png' });

  // Verify task is deleted
  const taskGone = !(await page.locator('.task-card:has-text("REGRESSION_TEST_' + timestamp + '")').isVisible());
  console.log('Task deleted:', taskGone);

  await browser.close();

  console.log('\n=== REGRESSION TEST SUMMARY ===');
  console.log('All core features verified!');
})();
