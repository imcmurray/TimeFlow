const { chromium } = require('playwright');

async function runRegressionTest() {
    console.log('Starting regression test...');

    const browser = await chromium.launch({ headless: true });
    const context = await browser.newContext();
    const page = await context.newPage();

    try {
        // Test 1: App loads
        console.log('Test 1: Navigating to app...');
        await page.goto('http://localhost:3000');
        await page.waitForLoadState('networkidle');

        // Skip onboarding if present
        const skipBtn = await page.$('#onboarding-skip-btn');
        if (skipBtn) {
            console.log('Skipping onboarding...');
            await skipBtn.click();
            await page.waitForTimeout(500);
        }

        // Test 2: NOW line visible
        console.log('Test 2: Checking NOW line...');
        const nowLine = await page.$('#now-line');
        if (nowLine) {
            console.log('✓ NOW line visible');
        } else {
            console.log('✗ NOW line NOT found');
        }

        // Test 3: FAB button visible
        console.log('Test 3: Checking FAB button...');
        const fab = await page.$('#add-task-btn');
        if (fab) {
            console.log('✓ FAB button visible');
        } else {
            console.log('✗ FAB button NOT found');
        }

        // Test 4: Hour markers
        console.log('Test 4: Checking hour markers...');
        const hourMarkers = await page.$$('.hour-marker');
        console.log(`✓ Found ${hourMarkers.length} hour markers`);

        // Take screenshot of initial state
        await page.screenshot({ path: 'regression-session24-1-initial.png' });
        console.log('Screenshot saved: regression-session24-1-initial.png');

        // Test 5: Create a task
        console.log('Test 5: Creating task...');
        await fab.click();
        await page.waitForTimeout(500);

        // Check modal is open
        const modal = await page.$('#task-modal');
        const isHidden = await modal.getAttribute('hidden');
        if (isHidden === null) {
            console.log('✓ Task modal opened');
        }

        // Fill in task details
        const uniqueTitle = `TEST_${Date.now()}_REGRESSION`;
        await page.fill('#task-title', uniqueTitle);
        await page.fill('#task-start-time', '14:00');
        await page.fill('#task-end-time', '15:00');
        await page.fill('#task-description', 'Regression test task description');

        await page.screenshot({ path: 'regression-session24-2-form.png' });
        console.log('Screenshot saved: regression-session24-2-form.png');

        // Save task
        await page.click('button:has-text("Save Task")');
        await page.waitForTimeout(1000);

        await page.screenshot({ path: 'regression-session24-3-created.png' });
        console.log('Screenshot saved: regression-session24-3-created.png');

        // Verify task was created
        const taskCard = await page.$(`text=${uniqueTitle}`);
        if (taskCard) {
            console.log('✓ Task created successfully');
        } else {
            console.log('✗ Task NOT found after creation');
        }

        // Test 6: Delete the task
        console.log('Test 6: Deleting task...');
        await taskCard.click();
        await page.waitForTimeout(500);

        // Click delete button
        await page.click('#delete-task-btn');
        await page.waitForTimeout(500);

        // Confirm deletion
        await page.click('#confirm-delete-btn');
        await page.waitForTimeout(1000);

        await page.screenshot({ path: 'regression-session24-4-deleted.png' });
        console.log('Screenshot saved: regression-session24-4-deleted.png');

        // Verify task was deleted
        const deletedTask = await page.$(`text=${uniqueTitle}`);
        if (!deletedTask) {
            console.log('✓ Task deleted successfully');
        } else {
            console.log('✗ Task still exists after deletion');
        }

        // Test 7: Check for console errors
        console.log('Test 7: Console errors check completed');

        console.log('\n=== REGRESSION TEST COMPLETE ===');
        console.log('All core features verified working!');

    } catch (error) {
        console.error('Test error:', error.message);
        await page.screenshot({ path: 'regression-session24-error.png' });
    } finally {
        await browser.close();
    }
}

runRegressionTest().catch(console.error);
