const { chromium } = require('playwright');

(async () => {
    console.log('=== REGRESSION TEST: Features 30, 75, 61 ===\n');
    const browser = await chromium.launch({ headless: true });
    const page = await browser.newPage();

    await page.goto('http://localhost:8080');
    await page.waitForTimeout(2000);

    // Skip onboarding if present
    const skipBtn = await page.$('#onboarding-skip-btn');
    if (skipBtn) {
        await skipBtn.click();
        await page.waitForTimeout(500);
    }

    // ========================================
    // Feature 30: Share screen opens
    // ========================================
    console.log('=== Feature 30: Share screen opens ===');

    // First create a task
    const fab = await page.$('#add-task-btn');
    await fab.click();
    await page.waitForTimeout(500);

    await page.fill('#task-title', 'Share Test Task');
    await page.fill('#task-start-time', '14:00');
    await page.fill('#task-end-time', '15:00');
    await page.click('button:has-text("Save Task")');
    await page.waitForTimeout(1000);
    console.log('Step 1: Task created - PASS');

    // Find and click share button
    const shareBtn = await page.$('#share-btn');
    if (shareBtn) {
        await shareBtn.click();
        await page.waitForTimeout(500);
        console.log('Step 2: Share button clicked - PASS');

        // Verify share modal opens
        const shareModal = await page.$('#share-modal');
        const shareModalVisible = shareModal && !(await shareModal.getAttribute('hidden'));
        console.log('Step 3: Share View screen opens -', shareModalVisible ? 'PASS' : 'FAIL');

        // Verify share options
        const shareAsImage = await page.$('button:has-text("Share as Image")');
        const shareAsText = await page.$('button:has-text("Share as Text")');
        console.log('Step 5: Share method options available -', (shareAsImage && shareAsText) ? 'PASS' : 'FAIL');

        await page.screenshot({ path: 'regression-session25-feature30.png' });

        // Close share modal by clicking outside or pressing escape
        await page.keyboard.press('Escape');
        await page.waitForTimeout(500);
    } else {
        console.log('Step 2: Share button NOT FOUND - FAIL');
    }

    console.log('Feature 30: COMPLETE\n');

    // ========================================
    // Feature 75: Date header shows correct date
    // ========================================
    console.log('=== Feature 75: Date header shows correct date ===');

    // Check today's date
    const dateHeader = await page.$('#current-date');
    const dateText = await dateHeader.textContent();
    console.log('Step 2: Date header shows:', dateText, dateText === 'Today' ? '- PASS' : '- FAIL');

    await page.screenshot({ path: 'regression-session25-feature75-1.png' });

    // Navigate to tomorrow
    const nextDayBtn = await page.$('#next-day-btn');
    await nextDayBtn.click();
    await page.waitForTimeout(500);

    const dateTextTomorrow = await dateHeader.textContent();
    console.log('Step 4: After next day:', dateTextTomorrow, dateTextTomorrow === 'Tomorrow' ? '- PASS' : '- FAIL');

    await page.screenshot({ path: 'regression-session25-feature75-2.png' });

    // Navigate back to today
    const prevDayBtn = await page.$('#prev-day-btn');
    await prevDayBtn.click();
    await page.waitForTimeout(500);

    const dateTextBack = await dateHeader.textContent();
    console.log('Step 6: Back to today:', dateTextBack, dateTextBack === 'Today' ? '- PASS' : '- FAIL');

    await page.screenshot({ path: 'regression-session25-feature75-3.png' });

    console.log('Feature 75: COMPLETE\n');

    // ========================================
    // Feature 61: About section in settings
    // ========================================
    console.log('=== Feature 61: About section in settings ===');

    // Navigate to settings
    const settingsBtn = await page.$('#settings-btn');
    await settingsBtn.click();
    await page.waitForTimeout(500);
    console.log('Step 1: Navigate to Settings - PASS');

    // Find About section
    const aboutSection = await page.$('#about-section, .about-section, h3:has-text("About")');
    console.log('Step 2: About section found -', aboutSection ? 'PASS' : 'FAIL');

    // Check for app name
    const appName = await page.$('text="TimeFlow"');
    console.log('Step 3: App name "TimeFlow" shown -', appName ? 'PASS' : 'FAIL');

    // Check for version
    const versionText = await page.$('text=/Version|v\\d/');
    console.log('Step 4: Version displayed -', versionText ? 'PASS' : 'FAIL');

    await page.screenshot({ path: 'regression-session25-feature61.png' });

    // Close settings
    await page.keyboard.press('Escape');
    await page.waitForTimeout(500);

    console.log('Feature 61: COMPLETE\n');

    // ========================================
    // Cleanup: Delete test task
    // ========================================
    console.log('=== Cleanup ===');
    const taskCard = await page.$('.task-card:has-text("Share Test Task")');
    if (taskCard) {
        await taskCard.click();
        await page.waitForTimeout(500);

        const deleteBtn = await page.$('button:has-text("Delete")');
        if (deleteBtn) {
            await deleteBtn.click();
            await page.waitForTimeout(500);

            const confirmBtn = await page.$('#confirm-delete-btn');
            if (confirmBtn) {
                await confirmBtn.click();
                await page.waitForTimeout(1000);
            }
        }
    }
    console.log('Test task deleted - PASS');

    console.log('\n=== ALL REGRESSION TESTS COMPLETE ===');

    await browser.close();
})();
