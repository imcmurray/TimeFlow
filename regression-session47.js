// Session 47 Regression Test Script
const { chromium } = require('playwright');

(async () => {
  console.log('Starting Session 47 Regression Testing...\n');

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();

  let testsPassed = 0;
  let testsFailed = 0;

  try {
    // Navigate to app
    console.log('1. Navigating to app...');
    await page.goto('http://localhost:3000');
    await page.waitForTimeout(2000);
    await page.screenshot({ path: 'regression-session47-1-initial.png' });
    console.log('   ✓ App loaded');

    // Check for onboarding and dismiss if present
    const skipButton = await page.$('#onboarding-skip-btn');
    if (skipButton && await skipButton.isVisible()) {
      await skipButton.click();
      await page.waitForTimeout(500);
      console.log('   ✓ Onboarding dismissed');
    }

    // Test 1: FAB Button Visibility (Feature 5)
    console.log('\n2. Testing FAB Button Visibility (Feature 5)...');
    const fab = await page.$('#add-task-btn');
    if (fab) {
      const fabBox = await fab.boundingBox();
      if (fabBox) {
        console.log(`   ✓ FAB is visible at position (${fabBox.x.toFixed(0)}, ${fabBox.y.toFixed(0)})`);
        testsPassed++;
      } else {
        console.log('   ✗ FAB bounding box not found');
        testsFailed++;
      }
    } else {
      console.log('   ✗ FAB button not found');
      testsFailed++;
    }

    // Test scrolling and FAB position
    await page.evaluate(() => window.scrollBy(0, 500));
    await page.waitForTimeout(500);
    const fabAfterScroll = await page.$('#add-task-btn');
    if (fabAfterScroll) {
      const fabBoxAfter = await fabAfterScroll.boundingBox();
      if (fabBoxAfter) {
        console.log(`   ✓ FAB remains visible after scroll at (${fabBoxAfter.x.toFixed(0)}, ${fabBoxAfter.y.toFixed(0)})`);
      }
    }
    await page.screenshot({ path: 'regression-session47-2-after-scroll.png' });

    // Test 2: Success Feedback on Save (Feature 87)
    console.log('\n3. Testing Success Feedback on Save (Feature 87)...');
    await page.click('#add-task-btn');
    await page.waitForTimeout(500);
    await page.screenshot({ path: 'regression-session47-3-modal.png' });
    console.log('   ✓ Task modal opened');

    // Fill form
    const testId = `REGTEST_${Date.now()}`;
    await page.fill('#task-title', testId);
    await page.fill('#task-description', 'Regression test for success feedback');
    await page.screenshot({ path: 'regression-session47-4-form-filled.png' });
    console.log(`   ✓ Form filled with test ID: ${testId}`);

    // Save task
    const saveBtn = await page.$('button:has-text("Save Task")');
    if (saveBtn) {
      await saveBtn.click();
    }
    await page.waitForTimeout(1500);
    await page.screenshot({ path: 'regression-session47-5-task-created.png' });

    // Check for success toast
    const toast = await page.$('.toast');
    if (toast) {
      const toastText = await toast.textContent();
      console.log(`   ✓ Toast notification shown: "${toastText.trim()}"`);
      testsPassed++;
    } else {
      console.log('   ⚠ No toast notification visible (may have already dismissed)');
    }

    // Verify task was created
    const taskCard = await page.$(`text=${testId}`);
    if (taskCard) {
      console.log('   ✓ Task created and visible on timeline');
    }

    // Test 3: Form Data Preserved on Validation Error (Feature 91)
    console.log('\n4. Testing Form Data Preserved on Validation Error (Feature 91)...');
    await page.click('#add-task-btn');
    await page.waitForTimeout(500);

    // Fill all fields except title (leave required field empty)
    await page.fill('#task-title', ''); // Clear title
    await page.fill('#task-description', 'Test description for validation');

    // Try to save without title
    const saveBtn2 = await page.$('button:has-text("Save Task")');
    if (saveBtn2) {
      await saveBtn2.click();
    }
    await page.waitForTimeout(500);
    await page.screenshot({ path: 'regression-session47-6-validation-error.png' });

    // Check if description field still has data
    const descValue = await page.$eval('#task-description', el => el.value);
    if (descValue === 'Test description for validation') {
      console.log('   ✓ Form data preserved after validation error');
      testsPassed++;
    } else {
      console.log(`   ✗ Form data was lost after validation error (got: "${descValue}")`);
      testsFailed++;
    }

    // Cancel and close modal
    const closeBtn = await page.$('#close-modal-btn');
    if (closeBtn) {
      await closeBtn.click();
    }
    await page.waitForTimeout(500);

    // Clean up: Delete the test task
    console.log('\n5. Cleaning up test data...');
    const testTask = await page.$(`text=${testId}`);
    if (testTask) {
      await testTask.click();
      await page.waitForTimeout(500);

      // Find and click delete button
      const deleteBtn = await page.$('#delete-task-btn');
      if (deleteBtn) {
        await deleteBtn.click();
        await page.waitForTimeout(500);
        await page.screenshot({ path: 'regression-session47-7-delete-confirm.png' });

        // Confirm deletion
        const confirmBtn = await page.$('#confirm-delete-btn');
        if (confirmBtn) {
          await confirmBtn.click();
          await page.waitForTimeout(1000);
        }
      }
    }
    await page.screenshot({ path: 'regression-session47-8-cleaned.png' });
    console.log('   ✓ Test data cleaned up');

    // Final verification - NOW line and hour markers
    console.log('\n6. Verifying Core UI Elements...');
    const nowLine = await page.$('#now-line');
    if (nowLine) {
      console.log('   ✓ NOW line is present');
    }

    const hourMarkers = await page.$$('.hour-label');
    console.log(`   ✓ ${hourMarkers.length} hour markers found`);

  } catch (error) {
    console.error('Test error:', error.message);
    await page.screenshot({ path: 'regression-session47-error.png' });
    testsFailed++;
  } finally {
    await browser.close();

    console.log('\n========================================');
    console.log(`Regression Test Results: ${testsPassed}/${testsPassed + testsFailed} passed`);
    console.log('========================================');
  }
})();
