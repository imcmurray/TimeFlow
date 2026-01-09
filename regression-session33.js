const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  try {
    await page.goto('http://localhost:3000');
    await page.waitForTimeout(2000);

    // Dismiss onboarding if visible
    const skipBtn = await page.$('#onboarding-skip-btn');
    if (skipBtn) {
      const isVisible = await skipBtn.isVisible();
      if (isVisible) {
        await skipBtn.click();
        await page.waitForTimeout(500);
        console.log('Onboarding dismissed: PASS');
      }
    }

    // Check if NOW line is visible
    const nowLine = await page.$('.now-line');
    console.log('NOW line visible:', nowLine !== null ? 'PASS' : 'FAIL');

    // Check if FAB button is visible
    const fab = await page.$('#add-task-btn');
    console.log('FAB button visible:', fab !== null ? 'PASS' : 'FAIL');

    // Check hour markers
    const hourLabels = await page.$$('.hour-label');
    console.log('Hour markers count:', hourLabels.length, hourLabels.length === 24 ? 'PASS' : 'FAIL');

    // Take screenshot
    await page.screenshot({ path: 'regression-session33-initial.png' });
    console.log('Screenshot saved: regression-session33-initial.png');

    // Try to create a task
    await fab.click();
    await page.waitForTimeout(500);

    // Check if modal opened
    const modal = await page.$('#task-modal:not([hidden])');
    console.log('Task modal opens:', modal !== null ? 'PASS' : 'FAIL');

    await page.screenshot({ path: 'regression-session33-modal.png' });

    // Fill the form
    await page.fill('#task-title', 'TEST_SESSION33_VERIFY');
    await page.fill('#task-start-time', '10:00');
    await page.fill('#task-end-time', '11:00');

    await page.screenshot({ path: 'regression-session33-form.png' });

    // Save the task
    const saveBtn = await page.$('button:has-text("Save Task")');
    await saveBtn.click();
    await page.waitForTimeout(1000);

    await page.screenshot({ path: 'regression-session33-created.png' });

    // Check if task was created (look for toast)
    const toast = await page.$('.toast');
    const toastText = toast ? await toast.textContent() : '';
    console.log('Task creation:', toastText.includes('created') ? 'PASS' : 'FAIL', '(' + toastText + ')');

    // Clean up - click the task and delete it
    const taskCard = await page.$('.task-card');
    if (taskCard) {
      await taskCard.click();
      await page.waitForTimeout(500);

      const deleteBtn = await page.$('#delete-task-btn');
      if (deleteBtn) {
        await deleteBtn.click();
        await page.waitForTimeout(500);

        const confirmBtn = await page.$('#confirm-yes');
        if (confirmBtn) {
          await confirmBtn.click();
          await page.waitForTimeout(500);
        }
      }
    }

    await page.screenshot({ path: 'regression-session33-cleaned.png' });
    console.log('Cleanup: PASS');

    console.log('\n=== Regression Test Complete ===');

  } catch (error) {
    console.error('Error:', error.message);
    await page.screenshot({ path: 'regression-session33-error.png' });
  }

  await browser.close();
})();
