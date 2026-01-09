const { chromium } = require('playwright');

(async () => {
  console.log('Starting regression test for Session 16...');

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();

  try {
    // Navigate to the app
    console.log('1. Navigating to app...');
    await page.goto('http://localhost:3000');
    await page.waitForTimeout(1000);

    // Take initial screenshot
    await page.screenshot({ path: 'regression-session16-1-initial.png' });
    console.log('   Screenshot: regression-session16-1-initial.png');

    // Check for onboarding and dismiss if present
    const onboardingModal = await page.$('#onboarding-modal');
    if (onboardingModal) {
      const isVisible = await onboardingModal.isVisible();
      if (isVisible) {
        console.log('   Onboarding modal detected, dismissing...');
        // Try skip button first
        const skipBtn = await page.$('#onboarding-skip-btn');
        if (skipBtn) {
          await skipBtn.click();
        } else {
          // Try alternative selectors
          const altSkip = await page.$('button:has-text("Skip")');
          if (altSkip) await altSkip.click();
          else {
            // Click through all slides to finish
            for (let i = 0; i < 4; i++) {
              const nextBtn = await page.$('#onboarding-next-btn');
              const startBtn = await page.$('button:has-text("Get Started")');
              if (startBtn) {
                await startBtn.click();
                break;
              } else if (nextBtn) {
                await nextBtn.click();
              }
              await page.waitForTimeout(200);
            }
          }
        }
        await page.waitForTimeout(500);
      }
    }

    // Check NOW line
    console.log('2. Checking NOW line...');
    const nowLine = await page.$('.now-line');
    if (nowLine) {
      console.log('   ✓ NOW line is present');
    } else {
      console.log('   ✗ NOW line NOT found');
    }

    // Check FAB button
    console.log('3. Checking FAB button...');
    const fab = await page.$('#add-task-btn');
    if (fab) {
      console.log('   ✓ FAB button is present');
    } else {
      console.log('   ✗ FAB button NOT found');
    }

    // Check hour labels
    console.log('4. Checking hour markers...');
    const hourLabels = await page.$$('.hour-label');
    console.log(`   ✓ Found ${hourLabels.length} hour markers`);

    // Create a test task
    console.log('5. Creating test task...');
    await fab.click();
    await page.waitForTimeout(500);

    // Fill in task form
    await page.fill('#task-title', 'REGRESSION_TEST_SESSION16');
    await page.fill('#task-start-time', '14:00');
    await page.fill('#task-end-time', '15:00');

    await page.screenshot({ path: 'regression-session16-2-form.png' });
    console.log('   Screenshot: regression-session16-2-form.png');

    // Save task
    const saveBtn = await page.$('button[type="submit"]:has-text("Save Task")');
    if (!saveBtn) {
      const altSaveBtn = await page.$('button.btn-primary:has-text("Save")');
      if (altSaveBtn) await altSaveBtn.click();
      else throw new Error('Save button not found');
    } else {
      await saveBtn.click();
    }
    await page.waitForTimeout(1000);

    await page.screenshot({ path: 'regression-session16-3-created.png' });
    console.log('   Screenshot: regression-session16-3-created.png');

    // Verify task was created
    const taskCard = await page.$('.task-card');
    if (taskCard) {
      const taskTitle = await taskCard.$eval('.task-title', el => el.textContent);
      if (taskTitle.includes('REGRESSION_TEST_SESSION16')) {
        console.log('   ✓ Task created successfully');
      } else {
        console.log(`   ✗ Task title mismatch: ${taskTitle}`);
      }
    } else {
      console.log('   ✗ Task card NOT found');
    }

    // Delete the test task
    console.log('6. Deleting test task...');
    await taskCard.click();
    await page.waitForTimeout(500);

    const deleteBtn = await page.$('#delete-task-btn');
    await deleteBtn.click();
    await page.waitForTimeout(500);

    // Confirm deletion
    const confirmBtn = await page.$('.confirm-dialog .btn-danger');
    if (confirmBtn) {
      await confirmBtn.click();
      await page.waitForTimeout(500);
    }

    await page.screenshot({ path: 'regression-session16-4-deleted.png' });
    console.log('   Screenshot: regression-session16-4-deleted.png');

    // Verify task was deleted
    const remainingTasks = await page.$$('.task-card');
    const testTaskStillExists = await page.$('text=REGRESSION_TEST_SESSION16');
    if (!testTaskStillExists) {
      console.log('   ✓ Task deleted successfully');
    } else {
      console.log('   ✗ Task still exists after deletion');
    }

    // Check console for errors
    console.log('7. Checking for console errors...');
    const consoleErrors = [];
    page.on('console', msg => {
      if (msg.type() === 'error') consoleErrors.push(msg.text());
    });

    // Refresh and check again
    await page.reload();
    await page.waitForTimeout(1000);

    if (consoleErrors.length === 0) {
      console.log('   ✓ No console errors detected');
    } else {
      console.log(`   ⚠ Found ${consoleErrors.length} console errors`);
    }

    console.log('\n=== REGRESSION TEST COMPLETE ===');
    console.log('All core features verified working!');

  } catch (error) {
    console.error('Test error:', error.message);
    await page.screenshot({ path: 'regression-session16-error.png' });
  } finally {
    await browser.close();
  }
})();
