// Session 44 - Regression Testing Script
const { chromium } = require('playwright');

async function runRegressionTests() {
  console.log('Session 44 - Regression Testing');
  console.log('================================');

  // Use local chromium installation
  const browser = await chromium.launch({
    headless: true
  });

  const context = await browser.newContext({
    viewport: { width: 1280, height: 720 }
  });

  const page = await context.newPage();
  const results = [];

  try {
    // TEST 1: App loads
    console.log('\n1. Testing app load...');
    await page.goto('http://localhost:3000', { waitUntil: 'networkidle' });
    await page.waitForTimeout(2000);
    await page.screenshot({ path: 'regression-session44-1-initial.png' });
    console.log('   - Initial screenshot captured');

    // Handle onboarding if present - click Skip button
    console.log('\n2. Handling onboarding modal...');
    const skipButton = await page.$('button:has-text("Skip")');
    if (skipButton) {
      await skipButton.click();
      console.log('   - Clicked Skip button');
      await page.waitForTimeout(500);
    }

    // Double check the onboarding is really closed
    const onboardingStillVisible = await page.isVisible('#onboarding-modal');
    if (onboardingStillVisible) {
      // Try pressing escape
      await page.keyboard.press('Escape');
      await page.waitForTimeout(300);
      console.log('   - Pressed Escape to dismiss modal');
    }

    await page.screenshot({ path: 'regression-session44-2-after-onboarding.png' });

    // Verify onboarding is dismissed
    const finalOnboardingCheck = await page.isVisible('#onboarding-modal');
    console.log(`   - Onboarding still visible: ${finalOnboardingCheck}`);

    // TEST 3: NOW line visible
    console.log('\n3. Testing NOW line visibility...');
    const nowLine = await page.$('#now-line');
    const nowLineVisible = nowLine !== null;
    results.push({ test: 'NOW line visible', pass: nowLineVisible });
    console.log(`   - NOW line visible: ${nowLineVisible ? 'PASS' : 'FAIL'}`);

    // Get current time from NOW line
    if (nowLine) {
      const nowTimeElement = await page.$('.now-time');
      if (nowTimeElement) {
        const nowTime = await nowTimeElement.textContent();
        console.log(`   - NOW line shows: ${nowTime}`);
      }
    }

    // TEST 4: FAB button accessible
    console.log('\n4. Testing FAB button...');
    const fab = await page.$('.fab');
    const fabVisible = fab !== null;
    results.push({ test: 'FAB visible', pass: fabVisible });
    console.log(`   - FAB visible: ${fabVisible ? 'PASS' : 'FAIL'}`);

    // TEST 5: Feature 23 - Settings screen accessible
    console.log('\n5. Testing Settings screen accessibility (Feature 23)...');
    const settingsBtn = await page.$('.settings-btn');
    if (settingsBtn) {
      await settingsBtn.click();
      await page.waitForTimeout(500);
      await page.screenshot({ path: 'regression-session44-3-settings.png' });

      // Check for theme selector
      const themeSelector = await page.$('#theme-select');
      const themePresent = themeSelector !== null;
      results.push({ test: 'Feature 23 - Settings theme selector', pass: themePresent });
      console.log(`   - Theme selector present: ${themePresent ? 'PASS' : 'FAIL'}`);

      // Check for notification toggle
      const notifToggle = await page.$('#notifications-enabled');
      const notifPresent = notifToggle !== null;
      results.push({ test: 'Feature 23 - Notification preferences', pass: notifPresent });
      console.log(`   - Notification toggle present: ${notifPresent ? 'PASS' : 'FAIL'}`);

      // Close settings by pressing Escape
      await page.keyboard.press('Escape');
      await page.waitForTimeout(300);
    } else {
      results.push({ test: 'Feature 23 - Settings screen accessible', pass: false });
      console.log('   - Settings button not found: FAIL');
    }

    // TEST 6: Feature 90 - Rapid navigation
    console.log('\n6. Testing rapid navigation (Feature 90)...');
    for (let i = 0; i < 5; i++) {
      const settingsBtnRapid = await page.$('.settings-btn');
      if (settingsBtnRapid) {
        await settingsBtnRapid.click();
        await page.waitForTimeout(100);
      }
      await page.keyboard.press('Escape');
      await page.waitForTimeout(100);
    }
    await page.screenshot({ path: 'regression-session44-4-rapid-nav.png' });
    const rapidNavOk = await page.$('.timeline') !== null;
    results.push({ test: 'Feature 90 - Rapid navigation', pass: rapidNavOk });
    console.log(`   - App stable after rapid navigation: ${rapidNavOk ? 'PASS' : 'FAIL'}`);

    // TEST 7: Feature 106 - Create then immediately view
    console.log('\n7. Testing immediate task creation view (Feature 106)...');
    const testTaskTitle = `IMMEDIATE_VIEW_TEST_${Date.now()}`;

    // Click FAB to open task modal
    console.log('   - Clicking FAB...');
    await page.click('.fab');
    await page.waitForTimeout(500);
    await page.screenshot({ path: 'regression-session44-5-modal.png' });

    // Wait for modal to be visible
    const taskModalVisible = await page.isVisible('#task-modal');
    console.log(`   - Task modal visible: ${taskModalVisible}`);

    if (taskModalVisible) {
      // Fill in task details
      console.log('   - Filling task title...');
      await page.fill('#task-title', testTaskTitle);
      await page.screenshot({ path: 'regression-session44-6-form.png' });

      // Save task using button[type="submit"] selector
      console.log('   - Clicking save button...');
      await page.click('#task-modal button[type="submit"]');
      await page.waitForTimeout(500);
      await page.screenshot({ path: 'regression-session44-7-after-save.png' });

      // Check if task appears immediately
      const pageContent = await page.content();
      const taskAppearsImmediately = pageContent.includes(testTaskTitle);
      results.push({ test: 'Feature 106 - Task appears immediately', pass: taskAppearsImmediately });
      console.log(`   - Task appears immediately: ${taskAppearsImmediately ? 'PASS' : 'FAIL'}`);

      // CLEANUP: Delete the test task
      console.log('\n8. Cleaning up test data...');
      const taskCards = await page.$$('.task-card');
      for (const card of taskCards) {
        const text = await card.textContent();
        if (text.includes('IMMEDIATE_VIEW_TEST')) {
          await card.click();
          await page.waitForTimeout(300);

          // Look for delete button in detail view
          const deleteBtn = await page.$('#delete-task');
          if (deleteBtn) {
            await deleteBtn.click();
            await page.waitForTimeout(300);

            // Confirm deletion
            const confirmBtn = await page.$('#confirm-delete');
            if (confirmBtn) {
              await confirmBtn.click();
              await page.waitForTimeout(300);
            }
          }
          break;
        }
      }
      await page.screenshot({ path: 'regression-session44-8-cleaned.png' });
      console.log('   - Test data cleaned up');
    } else {
      results.push({ test: 'Feature 106 - Task appears immediately', pass: false });
      console.log('   - Task modal did not open: FAIL');
    }

  } catch (error) {
    console.error('Test error:', error.message);
    await page.screenshot({ path: 'regression-session44-error.png' });
  }

  await browser.close();

  // Print summary
  console.log('\n================================');
  console.log('REGRESSION TEST SUMMARY');
  console.log('================================');
  let passCount = 0;
  for (const result of results) {
    const status = result.pass ? 'PASS' : 'FAIL';
    if (result.pass) passCount++;
    console.log(`${status}: ${result.test}`);
  }
  console.log(`\nTotal: ${passCount}/${results.length} tests passing`);

  return results;
}

runRegressionTests().catch(console.error);
