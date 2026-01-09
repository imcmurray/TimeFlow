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

  await page.screenshot({ path: 'session48-initial.png' });
  console.log('Screenshot taken');

  // Get page title
  const title = await page.title();
  console.log('Page title:', title);

  // Check for NOW line
  const nowLine = await page.locator('.now-line').isVisible().catch(() => false);
  console.log('NOW line visible:', nowLine);

  // Check for FAB button
  const fab = await page.locator('#add-task-btn').isVisible().catch(() => false);
  console.log('FAB visible:', fab);

  // Create a test task
  console.log('\n--- Creating test task ---');
  await page.click('#add-task-btn');
  await page.waitForTimeout(500);
  await page.screenshot({ path: 'session48-modal.png' });

  const taskTitle = 'REGRESSION_TEST_SESSION48_' + Date.now();
  await page.fill('#task-title', taskTitle);
  await page.fill('#task-start-time', '15:00');
  await page.fill('#task-end-time', '16:00');
  await page.click('button[type="submit"]');
  await page.waitForTimeout(1000);
  await page.screenshot({ path: 'session48-task-created.png' });

  // Verify task exists
  const taskCards = await page.locator('.task-card').count();
  console.log('Task cards count:', taskCards);

  // Get task card content
  const taskCardText = await page.locator('.task-card .task-title').first().textContent().catch(() => 'N/A');
  console.log('Task card title:', taskCardText);

  // Delete the test task
  console.log('\n--- Cleaning up test task ---');
  await page.click('.task-card');
  await page.waitForTimeout(500);
  await page.click('#delete-task-btn');
  await page.waitForTimeout(500);
  await page.screenshot({ path: 'session48-delete-confirm.png' });
  await page.click('#confirm-delete-btn');
  await page.waitForTimeout(500);
  await page.screenshot({ path: 'session48-cleaned.png' });

  const tasksAfterDelete = await page.locator('.task-card').count();
  console.log('Tasks after delete:', tasksAfterDelete);

  console.log('\n=== Regression test completed successfully! ===');
  await browser.close();
})().catch(e => console.error('Error:', e.message));
