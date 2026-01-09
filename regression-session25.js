const { chromium } = require('playwright');

(async () => {
    console.log('Launching browser...');
    const browser = await chromium.launch({ headless: true });
    const page = await browser.newPage();

    console.log('Navigating to app...');
    await page.goto('http://localhost:8080');
    await page.waitForTimeout(2000);

    // Skip onboarding if present
    const skipBtn = await page.$('#onboarding-skip-btn');
    if (skipBtn) {
        console.log('Skipping onboarding...');
        await skipBtn.click();
        await page.waitForTimeout(500);
    }

    // Check NOW line
    const nowLine = await page.$('#now-line');
    const nowLineVisible = nowLine && await nowLine.isVisible();
    console.log('NOW line visible:', nowLineVisible ? 'PASS' : 'FAIL');

    // Check FAB button
    const fab = await page.$('#add-task-btn');
    const fabVisible = fab && await fab.isVisible();
    console.log('FAB button visible:', fabVisible ? 'PASS' : 'FAIL');

    // Check hour markers
    const hourLabels = await page.$$('.hour-label');
    console.log('Hour markers:', hourLabels.length >= 20 ? 'PASS' : 'FAIL', '(' + hourLabels.length + ' found)');

    // Test task creation
    console.log('Testing task creation...');
    await fab.click();
    await page.waitForTimeout(500);

    const modal = await page.$('#task-modal');
    const modalHidden = await modal.getAttribute('hidden');
    console.log('Task modal opens:', modalHidden === null ? 'PASS' : 'FAIL');

    // Fill form
    await page.fill('#task-title', 'REGRESSION_TEST_SESSION25');
    await page.fill('#task-start-time', '14:00');
    await page.fill('#task-end-time', '15:00');

    // Save
    await page.click('button:has-text("Save Task")');
    await page.waitForTimeout(1000);

    // Check task created
    const taskCard = await page.$('.task-card:has-text("REGRESSION_TEST_SESSION25")');
    console.log('Task created:', taskCard ? 'PASS' : 'FAIL');

    // Take screenshot
    await page.screenshot({ path: 'regression-session25-created.png' });
    console.log('Screenshot saved: regression-session25-created.png');

    // Delete the task
    if (taskCard) {
        await taskCard.click();
        await page.waitForTimeout(500);

        const deleteBtn = await page.$('button:has-text("Delete")');
        if (deleteBtn) {
            await deleteBtn.click();
            await page.waitForTimeout(500);

            // Confirm delete
            const confirmBtn = await page.$('#confirm-delete-btn');
            if (confirmBtn) {
                await confirmBtn.click();
                await page.waitForTimeout(1000);
            }
        }
    }

    // Check task deleted
    const taskCardAfter = await page.$('.task-card:has-text("REGRESSION_TEST_SESSION25")');
    console.log('Task deleted:', !taskCardAfter ? 'PASS' : 'FAIL');

    await page.screenshot({ path: 'regression-session25-final.png' });

    console.log('\n=== REGRESSION TEST COMPLETE ===');

    await browser.close();
})();
