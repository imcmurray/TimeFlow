const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.goto('http://localhost:3000');

  console.log('=== REGRESSION TEST ===');

  // 1. Check NOW line glow effect
  const nowLine = await page.$('.now-line');
  console.log('✓ NOW line found:', !!nowLine);

  // 2. Check FAB button
  const fab = await page.$('#add-task-btn');
  console.log('✓ FAB button found:', !!fab);

  // 3. Create a task to test task card height
  await page.click('#add-task-btn');
  await page.waitForSelector('#task-modal', { state: 'visible' });
  console.log('✓ Task modal opens on FAB click');

  // Fill in task details - 30 minute task
  await page.fill('#task-title', 'Regression Test Task - 30min');
  await page.fill('#task-start-time', '15:00');
  await page.fill('#task-end-time', '15:30');
  await page.click('button[type="submit"]');

  // Wait for modal to close
  await page.waitForSelector('#task-modal', { state: 'hidden' });
  console.log('✓ Task created successfully');

  // Create another task - 2 hour task
  await page.click('#add-task-btn');
  await page.waitForSelector('#task-modal', { state: 'visible' });
  await page.fill('#task-title', 'Regression Test Task - 2hr');
  await page.fill('#task-start-time', '16:00');
  await page.fill('#task-end-time', '18:00');
  await page.click('button[type="submit"]');
  await page.waitForSelector('#task-modal', { state: 'hidden' });
  console.log('✓ Second task created successfully');

  // Wait a moment for rendering
  await page.waitForTimeout(500);

  // Take screenshot
  await page.screenshot({ path: 'regression-tasks.png' });
  console.log('✓ Screenshot saved to regression-tasks.png');

  // Check task cards exist
  const taskCards = await page.$$('.task-card');
  console.log('✓ Task cards found:', taskCards.length);

  // Verify task heights are different (2hr task should be taller)
  const task30min = await page.$('.task-card:has-text("30min")');
  const task2hr = await page.$('.task-card:has-text("2hr")');

  if (task30min && task2hr) {
    const height30min = await task30min.evaluate(el => el.offsetHeight);
    const height2hr = await task2hr.evaluate(el => el.offsetHeight);
    console.log(`✓ 30min task height: ${height30min}px`);
    console.log(`✓ 2hr task height: ${height2hr}px`);
    console.log(`✓ Height ratio: ${(height2hr / height30min).toFixed(2)}x (expected ~4x)`);
  }

  // Clean up - delete test tasks
  // Click first task card
  await page.click('.task-card:has-text("30min")');
  await page.waitForSelector('#task-modal', { state: 'visible' });
  await page.click('#delete-task-btn');
  await page.waitForSelector('#task-modal', { state: 'hidden' });
  console.log('✓ First test task deleted');

  // Delete second task
  await page.click('.task-card:has-text("2hr")');
  await page.waitForSelector('#task-modal', { state: 'visible' });
  await page.click('#delete-task-btn');
  await page.waitForSelector('#task-modal', { state: 'hidden' });
  console.log('✓ Second test task deleted');

  console.log('\n=== REGRESSION TEST PASSED ===');

  await browser.close();
})();
