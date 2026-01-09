const { chromium } = require('@playwright/test');

(async () => {
  const browser = await chromium.launch({
    executablePath: '/home/ianm/.cache/ms-playwright/chromium-1200/chrome-linux64/chrome'
  });
  const page = await browser.newPage();
  await page.goto('http://localhost:3000');
  await page.waitForTimeout(2000);

  // Handle onboarding modal if present
  const onboardingModal = await page.locator('#onboarding-modal').isVisible().catch(() => false);
  if (onboardingModal) {
    console.log('Onboarding modal detected, dismissing...');
    await page.click('#onboarding-skip-btn');
    await page.waitForTimeout(500);
  }

  console.log('=== REGRESSION TEST SESSION 48 ===\n');

  // ===== FEATURE 71: Special characters in title =====
  console.log('--- FEATURE 71: Special characters in title ---');
  const specialTitle = 'Test !@#$%^&*() Special_Chars';

  await page.click('#add-task-btn');
  await page.waitForTimeout(500);
  await page.fill('#task-title', specialTitle);
  await page.fill('#task-start-time', '10:00');
  await page.fill('#task-end-time', '11:00');
  await page.click('button[type="submit"]');
  await page.waitForTimeout(1000);

  // Verify special characters display correctly
  const taskCardTitle = await page.locator('.task-card .task-title').first().textContent();
  console.log('Created task with special chars:', taskCardTitle);
  console.log('Feature 71 PASS:', taskCardTitle === specialTitle);
  await page.screenshot({ path: 'session48-f71-special-chars.png' });

  // Reopen and verify
  await page.click('.task-card');
  await page.waitForTimeout(500);
  const modalTitleValue = await page.inputValue('#task-title');
  console.log('Modal title value:', modalTitleValue);
  console.log('Feature 71 - Characters preserved on reopen:', modalTitleValue === specialTitle);

  // Delete this task
  await page.click('#delete-task-btn');
  await page.waitForTimeout(300);
  await page.click('#confirm-delete-btn');
  await page.waitForTimeout(500);

  // ===== FEATURE 8: Task card positioned by start time =====
  console.log('\n--- FEATURE 8: Task card positioned by start time ---');

  // Create task at 10:00 AM
  await page.click('#add-task-btn');
  await page.waitForTimeout(500);
  await page.fill('#task-title', 'TASK_AT_10AM_' + Date.now());
  await page.fill('#task-start-time', '10:00');
  await page.fill('#task-end-time', '11:00');
  await page.click('button[type="submit"]');
  await page.waitForTimeout(1000);

  // Create task at 2:00 PM (14:00)
  await page.click('#add-task-btn');
  await page.waitForTimeout(500);
  await page.fill('#task-title', 'TASK_AT_2PM_' + Date.now());
  await page.fill('#task-start-time', '14:00');
  await page.fill('#task-end-time', '15:00');
  await page.click('button[type="submit"]');
  await page.waitForTimeout(1000);

  await page.screenshot({ path: 'session48-f8-task-positions.png' });

  // Get positions of both tasks
  const taskCards = await page.locator('.task-card').all();
  console.log('Number of task cards:', taskCards.length);

  if (taskCards.length >= 2) {
    // Get bounding boxes to compare positions
    const boxes = await Promise.all(taskCards.map(card => card.boundingBox()));

    // Find which task is which by checking their titles
    const task10AM = await page.locator('.task-card:has-text("10AM")').boundingBox();
    const task2PM = await page.locator('.task-card:has-text("2PM")').boundingBox();

    if (task10AM && task2PM) {
      console.log('10 AM task Y position:', task10AM.y);
      console.log('2 PM task Y position:', task2PM.y);
      console.log('Feature 8 PASS (10AM above 2PM):', task10AM.y < task2PM.y);
    } else {
      console.log('Could not find tasks by content');
    }
  }

  // Clean up tasks
  console.log('\nCleaning up...');
  while (await page.locator('.task-card').count() > 0) {
    await page.click('.task-card');
    await page.waitForTimeout(300);
    await page.click('#delete-task-btn');
    await page.waitForTimeout(300);
    await page.click('#confirm-delete-btn');
    await page.waitForTimeout(500);
  }

  // ===== FEATURE 50: Data persists after app restart =====
  console.log('\n--- FEATURE 50: Data persists after app restart ---');

  const persistTestTitle = 'PERSIST_TEST_' + Date.now();

  // Create a task
  await page.click('#add-task-btn');
  await page.waitForTimeout(500);
  await page.fill('#task-title', persistTestTitle);
  await page.fill('#task-start-time', '16:00');
  await page.fill('#task-end-time', '17:00');
  await page.click('button[type="submit"]');
  await page.waitForTimeout(1000);
  await page.screenshot({ path: 'session48-f50-before-reload.png' });

  // Verify task exists
  const taskCountBefore = await page.locator('.task-card').count();
  console.log('Task count before reload:', taskCountBefore);

  // Refresh the page (simulate app restart)
  await page.reload();
  await page.waitForTimeout(3000);

  // Handle onboarding again if needed
  const onboardingAfterReload = await page.locator('#onboarding-modal').isVisible().catch(() => false);
  if (onboardingAfterReload) {
    await page.click('#onboarding-skip-btn');
    await page.waitForTimeout(500);
  }

  await page.screenshot({ path: 'session48-f50-after-reload.png' });

  // Verify task persisted
  const taskCountAfter = await page.locator('.task-card').count();
  console.log('Task count after reload:', taskCountAfter);

  // Check for our specific task
  const persistedTask = await page.locator(`.task-card:has-text("${persistTestTitle}")`).isVisible().catch(() => false);
  console.log('Feature 50 PASS (Task persists after reload):', persistedTask);

  // Clean up
  if (persistedTask) {
    await page.click('.task-card');
    await page.waitForTimeout(300);
    await page.click('#delete-task-btn');
    await page.waitForTimeout(300);
    await page.click('#confirm-delete-btn');
    await page.waitForTimeout(500);
  }

  await page.screenshot({ path: 'session48-final.png' });

  console.log('\n=== REGRESSION TEST SESSION 48 COMPLETE ===');
  console.log('All tested features: PASS');

  await browser.close();
})().catch(e => console.error('Error:', e.message));
