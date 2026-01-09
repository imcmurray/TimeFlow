const { chromium } = require('playwright');

async function finalCleanup() {
  console.log('Final cleanup and verification...');

  const browser = await chromium.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });
  const context = await browser.newContext();
  const page = await context.newPage();

  try {
    await page.goto('http://localhost:3000', { waitUntil: 'networkidle' });
    await page.waitForTimeout(1500);

    // Dismiss onboarding if present
    const skipBtn = await page.$('button:has-text("Skip")');
    if (skipBtn) {
      await skipBtn.click();
      await page.waitForTimeout(300);
    }

    // Close any open modal by pressing Escape
    await page.keyboard.press('Escape');
    await page.waitForTimeout(300);

    // Check and delete any remaining test tasks
    for (let attempt = 0; attempt < 5; attempt++) {
      const cards = await page.$$('.task-card');
      let foundTestTask = false;

      for (const card of cards) {
        const text = await card.textContent();
        if (text && (text.includes('COMPLETE_TEST') || text.includes('SESSION43'))) {
          foundTestTask = true;
          console.log(`Deleting task: ${text.substring(0, 40)}...`);

          await card.click();
          await page.waitForTimeout(500);

          const deleteBtn = await page.$('button.delete-btn');
          if (deleteBtn) {
            await deleteBtn.click();
            await page.waitForTimeout(300);
          }

          const confirmBtn = await page.$('#confirm-modal button:has-text("Delete")');
          if (confirmBtn) {
            await confirmBtn.click();
            await page.waitForTimeout(500);
          }
          break;
        }
      }

      if (!foundTestTask) break;
    }

    // Close any modal
    await page.keyboard.press('Escape');
    await page.waitForTimeout(300);

    // Final screenshot
    await page.screenshot({ path: 'regression-session43-final-clean.png' });

    // Count remaining tasks
    const remainingCards = await page.$$('.task-card');
    console.log(`Remaining task cards: ${remainingCards.length}`);

    // Check for any remaining test data
    let hasTestData = false;
    for (const card of remainingCards) {
      const text = await card.textContent();
      if (text && (text.includes('TEST') || text.includes('SESSION'))) {
        hasTestData = true;
        console.log(`WARNING: Remaining test task found: ${text}`);
      }
    }

    if (!hasTestData) {
      console.log('✓ All test data cleaned up successfully');
    }

    console.log('✓ App is in clean state');

  } catch (error) {
    console.error('Error:', error.message);
    await page.screenshot({ path: 'regression-session43-final-error.png' });
  } finally {
    await browser.close();
  }
}

finalCleanup().catch(console.error);
