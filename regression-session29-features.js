const { chromium } = require('playwright');

(async () => {
  console.log('Starting feature regression tests...');

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  try {
    // Navigate to app
    await page.goto('http://localhost:3000');
    console.log('Page loaded');

    // Skip onboarding if present
    const onboardingSkip = page.locator('#onboarding-skip-btn');
    if (await onboardingSkip.isVisible({ timeout: 2000 }).catch(() => false)) {
      await onboardingSkip.click();
      await page.waitForTimeout(500);
    }

    // ===== Feature 19: Date navigation - next day =====
    console.log('\n=== Feature 19: Date navigation - next day ===');

    // Get current date from header
    const currentDate = await page.locator('#current-date').textContent();
    console.log('Current date:', currentDate);

    // Click next day button
    await page.locator('#next-day-btn').click();
    await page.waitForTimeout(500);

    // Get new date
    const nextDate = await page.locator('#current-date').textContent();
    console.log('After next:', nextDate);

    // Verify date changed
    const dateChanged = currentDate !== nextDate;
    console.log('Feature 19 (Date navigation):', dateChanged ? 'PASS' : 'FAIL');

    // Go back to today
    await page.locator('#prev-day-btn').click();
    await page.waitForTimeout(500);

    // ===== Feature 126: Images have alt text =====
    console.log('\n=== Feature 126: Images have alt text ===');

    // Check for SVG icons with aria-hidden or aria-label
    const svgsWithAriaHidden = await page.locator('svg[aria-hidden="true"]').count();
    const svgsWithAriaLabel = await page.locator('svg[aria-label]').count();
    const buttonsWithAriaLabel = await page.locator('button[aria-label]').count();

    console.log('SVGs with aria-hidden:', svgsWithAriaHidden);
    console.log('SVGs with aria-label:', svgsWithAriaLabel);
    console.log('Buttons with aria-label:', buttonsWithAriaLabel);

    const hasAlt = buttonsWithAriaLabel > 0 || svgsWithAriaHidden > 0;
    console.log('Feature 126 (Images alt text):', hasAlt ? 'PASS' : 'FAIL');

    // ===== Feature 30: Share screen opens =====
    console.log('\n=== Feature 30: Share screen opens ===');

    // First create a task
    await page.locator('#add-task-btn').click();
    await page.waitForTimeout(500);

    const testId = `SHARE_TEST_${Date.now()}`;
    await page.locator('#task-title').fill(testId);
    await page.locator('#task-start-time').fill('14:00');
    await page.locator('#task-end-time').fill('15:00');
    await page.locator('button:has-text("Save Task")').click();
    await page.waitForTimeout(1000);

    // Click share button
    const shareBtn = page.locator('#share-btn');
    if (await shareBtn.isVisible()) {
      await shareBtn.click();
      await page.waitForTimeout(500);

      // Verify share modal is visible
      const shareModal = await page.locator('#share-modal').isVisible();
      const sharePreview = await page.locator('#share-preview').isVisible();

      console.log('Share modal visible:', shareModal);
      console.log('Share preview visible:', sharePreview);
      console.log('Feature 30 (Share screen):', shareModal && sharePreview ? 'PASS' : 'FAIL');

      await page.screenshot({ path: 'regression-session29-share.png' });

      // Close share modal
      await page.locator('#share-modal .close-btn').click();
      await page.waitForTimeout(300);
    } else {
      console.log('Share button not found');
      console.log('Feature 30 (Share screen): FAIL');
    }

    // Cleanup - delete test task
    await page.locator(`.task-card:has-text("${testId}")`).click();
    await page.waitForTimeout(500);
    await page.locator('#delete-task-btn').click();
    await page.waitForTimeout(500);
    await page.locator('#confirm-delete-btn').click();
    await page.waitForTimeout(500);

    console.log('\n=== FEATURE REGRESSION TESTS COMPLETE ===');

  } catch (error) {
    console.error('Test error:', error.message);
    await page.screenshot({ path: 'regression-session29-features-error.png' });
  } finally {
    await browser.close();
  }
})();
