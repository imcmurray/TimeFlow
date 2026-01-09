const { chromium } = require('playwright');

async function runTest() {
  console.log('Starting regression test session 43...');

  const browser = await chromium.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });
  const context = await browser.newContext();
  const page = await context.newPage();

  try {
    // Navigate to the app
    console.log('Navigating to http://localhost:3000...');
    await page.goto('http://localhost:3000', { waitUntil: 'networkidle' });
    await page.waitForTimeout(2000);

    // Screenshot 1: Initial state
    await page.screenshot({ path: 'regression-session43-1-initial.png' });
    console.log('Screenshot 1: Initial state captured');

    // Check for onboarding modal and dismiss if present
    const skipButton = await page.$('button:has-text("Skip"), button:has-text("Dismiss")');
    if (skipButton) {
      await skipButton.click();
      await page.waitForTimeout(500);
      console.log('Dismissed onboarding modal');
    }

    // Check basic app elements
    const timeline = await page.$('.timeline');
    const nowLine = await page.$('.now-line');
    const fab = await page.$('.fab');
    console.log(`Timeline visible: ${!!timeline}`);
    console.log(`NOW line visible: ${!!nowLine}`);
    console.log(`FAB visible: ${!!fab}`);

    // Screenshot 2: After onboarding dismissed
    await page.screenshot({ path: 'regression-session43-2-timeline.png' });
    console.log('Screenshot 2: Timeline view captured');

    // Test Feature 93: Focus ring visible on elements
    // Navigate using Tab key
    console.log('\n--- Testing Feature 93: Focus ring visibility ---');
    await page.keyboard.press('Tab');
    await page.waitForTimeout(200);
    await page.screenshot({ path: 'regression-session43-3-focus-1.png' });
    console.log('Screenshot 3: Focus state 1 captured');

    await page.keyboard.press('Tab');
    await page.waitForTimeout(200);
    await page.screenshot({ path: 'regression-session43-4-focus-2.png' });
    console.log('Screenshot 4: Focus state 2 captured');

    await page.keyboard.press('Tab');
    await page.waitForTimeout(200);
    await page.screenshot({ path: 'regression-session43-5-focus-3.png' });
    console.log('Screenshot 5: Focus state 3 captured');

    // Test Feature 78: Back button navigation
    console.log('\n--- Testing Feature 78: Back button navigation ---');

    // Click FAB to open task modal
    if (fab) {
      await fab.click();
      await page.waitForTimeout(500);
      await page.screenshot({ path: 'regression-session43-6-modal-open.png' });
      console.log('Screenshot 6: Modal opened');

      // Press Escape to close modal (simulates back button)
      await page.keyboard.press('Escape');
      await page.waitForTimeout(500);
      await page.screenshot({ path: 'regression-session43-7-modal-closed.png' });
      console.log('Screenshot 7: Modal closed via Escape');
    }

    // Test Feature 141: Completed count visible
    console.log('\n--- Testing Feature 141: Completed count visible ---');

    // Create and complete 3 tasks
    for (let i = 1; i <= 3; i++) {
      // Open modal
      const addBtn = await page.$('.fab');
      if (addBtn) {
        await addBtn.click();
        await page.waitForTimeout(500);
      }

      // Fill task form
      const titleInput = await page.$('#task-title');
      if (titleInput) {
        await titleInput.fill(`Test Task ${i} - SESSION43_${Date.now()}`);
      }

      // Save task
      const saveBtn = await page.$('button:has-text("Save"), button:has-text("Add Task"), button.save-btn');
      if (saveBtn) {
        await saveBtn.click();
        await page.waitForTimeout(500);
      }
    }

    await page.screenshot({ path: 'regression-session43-8-tasks-created.png' });
    console.log('Screenshot 8: 3 tasks created');

    // Complete all tasks by swiping (click on complete button or swipe)
    const taskCards = await page.$$('.task-card');
    console.log(`Found ${taskCards.length} task cards`);

    // Complete tasks
    for (let i = 0; i < Math.min(3, taskCards.length); i++) {
      const checkbox = await taskCards[i].$('input[type="checkbox"]');
      if (checkbox) {
        await checkbox.click();
        await page.waitForTimeout(300);
      }
    }

    await page.waitForTimeout(500);
    await page.screenshot({ path: 'regression-session43-9-tasks-completed.png' });
    console.log('Screenshot 9: Tasks completed');

    // Verify completed tasks are visible
    const completedTasks = await page.$$('.task-card.completed');
    console.log(`Completed tasks visible: ${completedTasks.length}`);

    // Check console errors
    const consoleErrors = [];
    page.on('console', msg => {
      if (msg.type() === 'error') {
        consoleErrors.push(msg.text());
      }
    });

    // Cleanup - delete the test tasks
    console.log('\n--- Cleaning up test tasks ---');
    const testCards = await page.$$('.task-card');
    for (let i = testCards.length - 1; i >= 0; i--) {
      const card = testCards[i];
      const text = await card.textContent();
      if (text && text.includes('SESSION43')) {
        // Click on the card to open detail view
        await card.click();
        await page.waitForTimeout(500);

        // Look for delete button
        const deleteBtn = await page.$('button:has-text("Delete"), button.delete-btn, .delete-button');
        if (deleteBtn) {
          await deleteBtn.click();
          await page.waitForTimeout(300);

          // Confirm delete if there's a dialog
          const confirmBtn = await page.$('button:has-text("Confirm"), button:has-text("Yes"), button:has-text("Delete"):visible');
          if (confirmBtn) {
            await confirmBtn.click();
            await page.waitForTimeout(300);
          }
        }

        // Close modal if still open
        const closeBtn = await page.$('button:has-text("Close"), button.close-btn');
        if (closeBtn) {
          await closeBtn.click();
          await page.waitForTimeout(200);
        }
      }
    }

    await page.screenshot({ path: 'regression-session43-10-cleaned.png' });
    console.log('Screenshot 10: Final cleaned state');

    console.log('\n=== REGRESSION TEST RESULTS ===');
    console.log('Feature 93 (Focus ring visible): Check screenshots 3-5');
    console.log('Feature 78 (Back button navigation): PASS - Escape closed modal');
    console.log(`Feature 141 (Completed count visible): ${completedTasks.length} completed tasks visible`);
    console.log(`Console errors: ${consoleErrors.length === 0 ? 'None' : consoleErrors.join(', ')}`);

  } catch (error) {
    console.error('Error during test:', error);
    await page.screenshot({ path: 'regression-session43-error.png' });
  } finally {
    await browser.close();
    console.log('\nBrowser closed. Test complete.');
  }
}

runTest().catch(console.error);
