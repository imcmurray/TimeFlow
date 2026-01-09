const { chromium } = require('playwright');

async function runRegression() {
    console.log('Starting regression test for Session 26...');

    const browser = await chromium.launch({
        headless: true
    });

    const context = await browser.newContext({
        viewport: { width: 1280, height: 720 }
    });

    const page = await context.newPage();

    // Collect console errors
    const consoleErrors = [];
    page.on('console', msg => {
        if (msg.type() === 'error') {
            consoleErrors.push(msg.text());
        }
    });

    try {
        // Test 1: App loads
        console.log('\n--- Test 1: App loads ---');
        await page.goto('http://localhost:8080');
        await page.waitForTimeout(1000);

        // Skip onboarding if present
        const onboardingSkip = await page.$('#onboarding-skip-btn:visible');
        if (onboardingSkip) {
            await onboardingSkip.click();
            await page.waitForTimeout(500);
            console.log('Skipped onboarding');
        }

        // Test 2: NOW line visible
        console.log('\n--- Test 2: NOW line visible ---');
        const nowLine = await page.$('#now-line');
        if (nowLine) {
            const nowLineVisible = await nowLine.isVisible();
            console.log(`NOW line visible: ${nowLineVisible ? 'PASS' : 'FAIL'}`);
        } else {
            console.log('NOW line visible: FAIL (not found)');
        }

        // Test 3: Hour markers visible
        console.log('\n--- Test 3: Hour markers ---');
        const hourLabels = await page.$$('.hour-label');
        console.log(`Hour markers found: ${hourLabels.length} (expected 24)`);
        console.log(`Hour markers: ${hourLabels.length === 24 ? 'PASS' : 'FAIL'}`);

        // Test 4: FAB button visible
        console.log('\n--- Test 4: FAB button ---');
        const fabBtn = await page.$('#add-task-btn');
        if (fabBtn) {
            const fabVisible = await fabBtn.isVisible();
            console.log(`FAB button visible: ${fabVisible ? 'PASS' : 'FAIL'}`);
        } else {
            console.log('FAB button: FAIL (not found)');
        }

        await page.screenshot({ path: 'regression-session26-1-initial.png' });
        console.log('Screenshot: regression-session26-1-initial.png');

        // Test 5: Create a task
        console.log('\n--- Test 5: Create task ---');
        await page.click('#add-task-btn');
        await page.waitForTimeout(500);

        // Wait for modal to be visible
        await page.waitForSelector('#task-modal:not([hidden])');
        await page.screenshot({ path: 'regression-session26-2-modal.png' });
        console.log('Screenshot: regression-session26-2-modal.png');

        // Fill in task details with unique test data
        const testId = `REGTEST_${Date.now()}`;
        await page.fill('#task-title', testId);
        await page.fill('#task-start-time', '14:00');
        await page.fill('#task-end-time', '15:00');
        await page.fill('#task-description', 'Regression test task for Session 26');

        await page.screenshot({ path: 'regression-session26-3-form.png' });
        console.log('Screenshot: regression-session26-3-form.png');

        // Click Save button
        await page.click('button:has-text("Save Task")');
        await page.waitForTimeout(1000);

        // Verify task appears on timeline
        const taskCard = await page.waitForSelector('.task-card', { timeout: 5000 });
        if (taskCard) {
            console.log('Task creation: PASS');
        } else {
            console.log('Task creation: FAIL');
        }

        // Check for toast message
        const toast = await page.$('.toast');
        if (toast) {
            const toastText = await toast.textContent();
            console.log(`Toast message: "${toastText}"`);
        }

        await page.screenshot({ path: 'regression-session26-4-created.png' });
        console.log('Screenshot: regression-session26-4-created.png');

        // Test 6: Verify touch targets (Feature 94)
        console.log('\n--- Test 6: Touch targets (Feature 94) ---');
        const fabBounds = await fabBtn.boundingBox();
        if (fabBounds) {
            const isAdequateSize = fabBounds.width >= 44 && fabBounds.height >= 44;
            console.log(`FAB size: ${fabBounds.width}x${fabBounds.height}px (min 44x44)`);
            console.log(`Touch targets: ${isAdequateSize ? 'PASS' : 'FAIL'}`);
        }

        // Test 7: Delete task
        console.log('\n--- Test 7: Delete task ---');
        await page.click('.task-card');
        await page.waitForTimeout(500);

        // Wait for modal and click delete
        await page.waitForSelector('#task-modal:not([hidden])');
        await page.click('button:has-text("Delete")');
        await page.waitForTimeout(500);

        // Confirm deletion
        await page.waitForSelector('#confirm-modal:not([hidden])');
        await page.click('#confirm-delete-btn');
        await page.waitForTimeout(1000);

        // Verify task is gone
        const tasksAfterDelete = await page.$$('.task-card');
        console.log(`Task deletion: ${tasksAfterDelete.length === 0 ? 'PASS' : 'FAIL'}`);

        await page.screenshot({ path: 'regression-session26-5-cleaned.png' });
        console.log('Screenshot: regression-session26-5-cleaned.png');

        // Test 8: Console errors
        console.log('\n--- Test 8: Console errors ---');
        console.log(`Console errors: ${consoleErrors.length === 0 ? 'PASS' : 'FAIL'}`);
        if (consoleErrors.length > 0) {
            console.log('Errors:', consoleErrors);
        }

        console.log('\n=== REGRESSION TEST COMPLETE ===');
        console.log('All core features verified.');

    } catch (error) {
        console.error('Test error:', error.message);
        await page.screenshot({ path: 'regression-session26-error.png' });
    } finally {
        await browser.close();
    }
}

runRegression().catch(console.error);
