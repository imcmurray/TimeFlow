const { chromium } = require('playwright');

(async () => {
  console.log('Debug test for Session 21...\n');

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();

  // Listen for console messages
  page.on('console', msg => console.log('BROWSER LOG:', msg.text()));

  try {
    // Test 1: App loads correctly
    console.log('Loading app...');
    await page.goto('http://localhost:3000');
    await page.waitForLoadState('networkidle');

    // Skip onboarding if present
    const skipButton = page.locator('button:has-text("Skip")');
    if (await skipButton.isVisible({ timeout: 2000 }).catch(() => false)) {
      await skipButton.click();
      await page.waitForTimeout(500);
    }

    await page.screenshot({ path: 'debug-session21-1-initial.png' });
    console.log('  - App loaded');

    // Open FAB
    console.log('Clicking FAB...');
    const fab = page.locator('#add-task-btn');
    await fab.click();
    await page.waitForTimeout(1000);

    await page.screenshot({ path: 'debug-session21-2-modal.png' });

    // Check if modal is visible
    const modal = page.locator('#task-modal');
    const isModalHidden = await modal.getAttribute('hidden');
    console.log(`  - Modal hidden attribute: ${isModalHidden}`);

    // Fill form
    console.log('Filling form...');
    await page.fill('#task-title', 'Test Task');
    await page.fill('#task-start-time', '15:00');
    await page.fill('#task-end-time', '16:00');

    await page.screenshot({ path: 'debug-session21-3-filled.png' });

    // Check form state
    const titleValue = await page.inputValue('#task-title');
    const startValue = await page.inputValue('#task-start-time');
    const endValue = await page.inputValue('#task-end-time');
    console.log(`  - Title: ${titleValue}`);
    console.log(`  - Start: ${startValue}`);
    console.log(`  - End: ${endValue}`);

    // Try to submit
    console.log('Submitting form...');
    const submitBtn = page.locator('button[type="submit"]');
    const btnText = await submitBtn.textContent();
    console.log(`  - Submit button text: ${btnText}`);
    await submitBtn.click();

    await page.waitForTimeout(2000);
    await page.screenshot({ path: 'debug-session21-4-after-submit.png' });

    // Check modal state after submit
    const isModalHiddenAfter = await modal.getAttribute('hidden');
    console.log(`  - Modal hidden attribute after submit: ${isModalHiddenAfter}`);

    // Check for error messages
    const errorMessages = await page.locator('.error-message').allTextContents();
    console.log(`  - Error messages: ${JSON.stringify(errorMessages)}`);

  } catch (error) {
    console.error('Test error:', error);
    await page.screenshot({ path: 'debug-session21-error.png' });
  } finally {
    await browser.close();
  }
})();
