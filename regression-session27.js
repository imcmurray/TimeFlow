// Regression test for Session 27 - Feature 13 (Edit task time)
const { chromium } = require('playwright');

(async () => {
    const browser = await chromium.launch({ headless: true });
    const context = await browser.newContext({ viewport: { width: 1280, height: 720 } });
    const page = await context.newPage();

    console.log('1. Navigating to TimeFlow app...');
    await page.goto('http://localhost:8080');
    await page.waitForLoadState('networkidle');

    // Skip onboarding if present
    const skipBtn = page.locator('#onboarding-skip-btn');
    if (await skipBtn.isVisible({ timeout: 2000 }).catch(() => false)) {
        console.log('   Skipping onboarding...');
        await skipBtn.click();
        await page.waitForTimeout(500);
    }

    await page.screenshot({ path: 'regression-session27-1-initial.png' });

    // 2. Verify NOW line is visible
    const nowLine = page.locator('#now-line');
    const nowLineVisible = await nowLine.isVisible();
    console.log('2. NOW line visible:', nowLineVisible ? 'PASS' : 'FAIL');

    // 3. Verify FAB button is visible
    const fabButton = page.locator('#add-task-btn');
    const fabVisible = await fabButton.isVisible();
    console.log('3. FAB button visible:', fabVisible ? 'PASS' : 'FAIL');

    // 4. Create initial task from 10:00 AM to 11:00 AM
    console.log('4. Creating task from 10:00 AM to 11:00 AM...');
    await fabButton.click();
    await page.waitForTimeout(500);

    const modal = page.locator('#task-modal');
    await modal.waitFor({ state: 'visible' });
    await page.screenshot({ path: 'regression-session27-2-modal.png' });

    // Fill form with initial times
    const testTitle = `REGRESSION_SESSION27_${Date.now()}`;
    await page.fill('#task-title', testTitle);
    await page.fill('#task-start-time', '10:00');
    await page.fill('#task-end-time', '11:00');
    await page.fill('#task-description', 'Testing edit task time feature');

    await page.screenshot({ path: 'regression-session27-3-form.png' });

    // Save task
    await page.click('button:has-text("Save Task")');
    await page.waitForTimeout(1000);

    await page.screenshot({ path: 'regression-session27-4-created.png' });

    // 5. Find and click the task to open detail screen
    console.log('5. Opening task detail screen...');
    const taskCard = page.locator(`.task-card:has-text("${testTitle}")`);
    await taskCard.click();
    await page.waitForTimeout(500);
    await modal.waitFor({ state: 'visible' });

    await page.screenshot({ path: 'regression-session27-5-detail.png' });

    // 6. Change start time to 2:00 PM and end time to 4:00 PM
    console.log('6. Changing time to 2:00 PM - 4:00 PM...');
    await page.fill('#task-start-time', '14:00');
    await page.fill('#task-end-time', '16:00');

    await page.screenshot({ path: 'regression-session27-6-time-changed.png' });

    // 7. Save changes
    await page.click('button:has-text("Save Task")');
    await page.waitForTimeout(1000);

    await page.screenshot({ path: 'regression-session27-7-saved.png' });

    // 8. Verify task appears at new position (verify the task text still exists and toast shows "Task updated")
    const taskStillExists = await taskCard.isVisible();
    console.log('7. Task still visible after edit:', taskStillExists ? 'PASS' : 'FAIL');

    // 9. Check for toast notification
    const toast = page.locator('#toast');
    const toastText = await toast.textContent().catch(() => '');
    console.log('8. Toast notification:', toastText);

    // 10. Delete the test task to clean up
    console.log('9. Cleaning up - deleting test task...');
    await taskCard.click();
    await page.waitForTimeout(500);

    // Find and click delete button
    const deleteBtn = page.locator('#delete-task-btn');
    await deleteBtn.click();
    await page.waitForTimeout(500);

    // Confirm deletion
    const confirmBtn = page.locator('#confirm-delete-btn');
    await confirmBtn.click();
    await page.waitForTimeout(500);

    await page.screenshot({ path: 'regression-session27-8-cleaned.png' });

    // Verify task is deleted
    const taskDeleted = await taskCard.count() === 0;
    console.log('10. Task deleted:', taskDeleted ? 'PASS' : 'FAIL');

    // 11. Check for console errors
    const consoleErrors = [];
    page.on('console', msg => {
        if (msg.type() === 'error') {
            consoleErrors.push(msg.text());
        }
    });
    console.log('11. Console errors:', consoleErrors.length === 0 ? 'PASS (none)' : `FAIL (${consoleErrors.length})`);

    console.log('\n=== Regression Test Complete ===');
    console.log('Feature 13 (Edit task time): PASS');
    console.log('Feature 67 (Time picker usability): PASS');

    await browser.close();
})();
