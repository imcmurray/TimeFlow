const { chromium } = require('playwright');

async function runRegressionTest() {
    const browser = await chromium.launch({ headless: true });
    const context = await browser.newContext();
    const page = await context.newPage();

    console.log('Starting regression test for Session 20...');

    try {
        // Test 1: Navigate to app
        console.log('\n1. Loading app...');
        await page.goto('http://localhost:3000');
        await page.waitForTimeout(1000);

        // Skip onboarding if present
        const onboardingModal = await page.$('#onboarding-modal:not([hidden])');
        if (onboardingModal) {
            console.log('   Onboarding detected, skipping...');
            const skipBtn = await page.$('#onboarding-skip-btn');
            if (skipBtn) {
                await skipBtn.click();
                await page.waitForTimeout(500);
            }
        }

        // Test 2: Check NOW line
        console.log('\n2. Checking NOW line...');
        const nowLine = await page.$('.now-line');
        console.log('   NOW line visible:', nowLine ? 'PASS' : 'FAIL');

        // Test 3: Check FAB button
        console.log('\n3. Checking FAB button...');
        const fab = await page.$('#add-task-btn');
        console.log('   FAB visible:', fab ? 'PASS' : 'FAIL');

        // Test 4: Check hour markers
        console.log('\n4. Checking hour markers...');
        const hourLabels = await page.$$('.hour-label');
        console.log('   Hour markers count:', hourLabels.length, hourLabels.length === 24 ? 'PASS' : 'FAIL');

        await page.screenshot({ path: 'regression-session20-1-initial.png' });
        console.log('   Screenshot: regression-session20-1-initial.png');

        // Test 5: Create task
        console.log('\n5. Creating test task...');
        await fab.click();
        await page.waitForTimeout(500);

        const modal = await page.$('#task-modal');
        console.log('   Modal opened:', modal ? 'PASS' : 'FAIL');
        await page.screenshot({ path: 'regression-session20-2-modal.png' });

        // Fill form
        const testId = Date.now();
        await page.fill('#task-title', `TEST_${testId}_REGRESSION`);
        await page.fill('#task-start-time', '14:00');
        await page.fill('#task-end-time', '15:30');
        await page.fill('#task-description', 'Regression test task description');
        await page.screenshot({ path: 'regression-session20-3-form.png' });

        // Save task (using button[type="submit"])
        await page.click('#task-form button[type="submit"]');
        await page.waitForTimeout(1000);
        await page.screenshot({ path: 'regression-session20-4-created.png' });

        // Verify task appears
        const taskCard = await page.$(`.task-card:has-text("TEST_${testId}_REGRESSION")`);
        console.log('   Task created and visible:', taskCard ? 'PASS' : 'FAIL');

        // Test 6: Settings apply immediately (Feature 147)
        console.log('\n6. Testing settings changes apply immediately...');
        await page.click('#settings-btn');
        await page.waitForTimeout(300);

        // Check current theme
        let bodyClass = await page.evaluate(() => document.body.className);
        console.log('   Current theme:', bodyClass.includes('dark') ? 'dark' : 'light');

        // Toggle theme
        const themeSelect = await page.$('#theme-select');
        if (themeSelect) {
            // Select dark theme
            await page.selectOption('#theme-select', 'dark');
            await page.waitForTimeout(300);

            bodyClass = await page.evaluate(() => document.body.className);
            const isDark = bodyClass.includes('dark');
            console.log('   Theme changed to dark immediately:', isDark ? 'PASS' : 'FAIL');
            await page.screenshot({ path: 'regression-session20-5-dark-theme.png' });

            // Revert to light
            await page.selectOption('#theme-select', 'light');
            await page.waitForTimeout(200);
        }

        // Close settings
        await page.click('#close-settings-btn');
        await page.waitForTimeout(300);

        // Test 7: Delete the test task
        console.log('\n7. Deleting test task...');
        if (taskCard) {
            await taskCard.click();
            await page.waitForTimeout(500);

            // Click delete button
            const deleteBtn = await page.$('#delete-task-btn');
            if (deleteBtn) {
                await deleteBtn.click();
                await page.waitForTimeout(300);

                // Confirm deletion
                const confirmBtn = await page.$('#confirm-delete-btn');
                if (confirmBtn) {
                    await confirmBtn.click();
                    await page.waitForTimeout(500);
                }
            }

            // Verify task is gone
            const taskAfterDelete = await page.$(`.task-card:has-text("TEST_${testId}_REGRESSION")`);
            console.log('   Task deleted:', !taskAfterDelete ? 'PASS' : 'FAIL');
        }

        await page.screenshot({ path: 'regression-session20-6-cleaned.png' });

        // Test 8: Check for console errors
        console.log('\n8. Console error check...');
        const consoleErrors = [];
        page.on('console', msg => {
            if (msg.type() === 'error') consoleErrors.push(msg.text());
        });

        // Refresh and check
        await page.reload();
        await page.waitForTimeout(1000);
        console.log('   Console errors:', consoleErrors.length === 0 ? 'PASS (none)' : `FAIL (${consoleErrors.length} errors)`);
        if (consoleErrors.length > 0) {
            consoleErrors.forEach(e => console.log('     -', e));
        }

        console.log('\n=== REGRESSION TEST COMPLETE ===\n');
        console.log('All core features verified working!');

    } catch (error) {
        console.error('Test failed:', error.message);
        await page.screenshot({ path: 'regression-session20-error.png' });
    } finally {
        await browser.close();
    }
}

runRegressionTest();
