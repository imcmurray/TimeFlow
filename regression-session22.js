const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  console.log('Starting regression test...');

  await page.goto('http://localhost:8080');
  const title = await page.title();
  console.log('Page title:', title);

  // Skip onboarding if present
  const onboardingVisible = await page.locator('#onboarding-modal:not([hidden])').isVisible().catch(() => false);
  if (onboardingVisible) {
    console.log('Onboarding modal detected - clicking Skip');
    await page.click('#onboarding-skip-btn');
    await page.waitForTimeout(500);
  } else {
    // Check if it's showing without :not([hidden])
    const onboardingAlt = await page.locator('#onboarding-modal').isVisible().catch(() => false);
    if (onboardingAlt) {
      console.log('Onboarding modal detected (alt check) - clicking Skip');
      await page.click('#onboarding-skip-btn');
      await page.waitForTimeout(500);
    }
  }

  // Check NOW line
  const nowLine = await page.locator('.now-line').isVisible();
  console.log('NOW line visible:', nowLine);

  // Check FAB button
  const fab = await page.locator('.fab, #add-task-btn').isVisible();
  console.log('FAB visible:', fab);

  // Check hour markers
  const hourLabels = await page.locator('.hour-label').count();
  console.log('Hour markers count:', hourLabels);

  // Take screenshot
  await page.screenshot({ path: 'regression-session22-initial.png' });
  console.log('Screenshot saved: regression-session22-initial.png');

  // Test task creation
  console.log('\n--- Testing Task Creation ---');
  await page.click('#add-task-btn');
  await page.waitForSelector('#task-modal:not([hidden])');
  console.log('Task modal opened: PASS');

  // Fill in task form
  const testTitle = 'REGRESSION_TEST_' + Date.now();
  await page.fill('#task-title', testTitle);
  await page.fill('#task-start-time', '14:00');
  await page.fill('#task-end-time', '15:00');

  await page.screenshot({ path: 'regression-session22-form.png' });
  console.log('Form filled with test data');

  // Save task
  await page.click('button:has-text("Save Task")');
  await page.waitForTimeout(500);

  // Verify task was created
  const taskCard = await page.locator('.task-card', { hasText: testTitle });
  const taskVisible = await taskCard.isVisible();
  console.log('Task created and visible:', taskVisible);

  await page.screenshot({ path: 'regression-session22-created.png' });

  // Clean up - delete the task
  await taskCard.click();
  await page.waitForSelector('#task-modal:not([hidden])');
  await page.click('#delete-task-btn');

  // Handle confirmation dialog
  await page.waitForSelector('#confirm-modal:not([hidden])');
  await page.click('#confirm-delete-btn');
  await page.waitForTimeout(500);

  // Verify task is gone
  const taskGone = !(await page.locator('.task-card', { hasText: testTitle }).isVisible());
  console.log('Task deleted successfully:', taskGone);

  await page.screenshot({ path: 'regression-session22-cleaned.png' });

  await browser.close();

  console.log('\n=== REGRESSION TEST SUMMARY ===');
  console.log('NOW line visible:', nowLine ? 'PASS' : 'FAIL');
  console.log('FAB visible:', fab ? 'PASS' : 'FAIL');
  console.log('Hour markers (24):', hourLabels === 24 ? 'PASS' : 'FAIL');
  console.log('Task creation:', taskVisible ? 'PASS' : 'FAIL');
  console.log('Task deletion:', taskGone ? 'PASS' : 'FAIL');
  console.log('================================');

  if (nowLine && fab && hourLabels === 24 && taskVisible && taskGone) {
    console.log('ALL REGRESSION TESTS PASSED!');
  } else {
    console.log('SOME TESTS FAILED - investigate');
  }
})();
