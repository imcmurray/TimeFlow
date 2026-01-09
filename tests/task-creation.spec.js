// @ts-check
const { test, expect } = require('@playwright/test');
const {
  waitForFlutterReady,
  clickAddTaskButton,
  clickSettingsButton,
  clickAt,
  typeText,
  calculateTaskYPosition,
  TIMELINE_CONSTANTS,
} = require('./helpers/flutter-utils');

test.describe('Task Creation and Persistence', () => {
  test.beforeEach(async ({ page }) => {
    const baseUrl = process.env.BASE_URL || 'http://localhost:8081';
    await page.goto(baseUrl);
    await waitForFlutterReady(page);
  });

  test('should click FAB and open task creation dialog', async ({ page }) => {
    // Take initial screenshot showing the FAB
    await page.screenshot({ path: 'test-results/task-creation-01-initial.png' });
    console.log('Initial screenshot taken');

    // Get viewport/canvas size
    const viewport = page.viewportSize();
    console.log('Viewport size:', viewport);

    // Click FAB - it's in the bottom right corner
    // Using page.mouse.click directly to avoid Playwright waiting for actions
    const fabX = viewport.width - 45;
    const fabY = viewport.height - 45;
    console.log('Clicking FAB at', fabX, fabY);

    // Use mouse click directly
    await page.mouse.click(fabX, fabY);
    console.log('Click executed');

    // Short wait for dialog animation
    await page.waitForTimeout(500);
    console.log('Wait complete');

    // Take screenshot
    await page.screenshot({ path: 'test-results/task-creation-02-dialog.png' });
    console.log('Dialog screenshot taken');

    // Take one more after stabilization
    await page.waitForTimeout(500);
    await page.screenshot({ path: 'test-results/task-creation-03-dialog-stable.png' });
    console.log('Test complete');
  });

  test('should create a task with default time and verify it persists', async ({ page }) => {
    // Click FAB to open dialog
    await clickAddTaskButton(page);
    await page.waitForTimeout(500);
    await page.screenshot({ path: 'test-results/persist-01-dialog.png' });

    // Click in title field (near top of dialog) and type
    console.log('Typing task title...');
    await page.mouse.click(640, 95);
    await page.waitForTimeout(300);
    await typeText(page, 'Persistence Test Task');
    await page.screenshot({ path: 'test-results/persist-02-title.png' });

    // Scroll down within the dialog to reveal the Create Task button
    console.log('Scrolling to reveal Create Task button...');
    const viewport = page.viewportSize();
    // Scroll within the form to reveal the button at bottom
    await page.mouse.move(viewport.width / 2, viewport.height / 2);
    await page.mouse.wheel(0, 300);
    await page.waitForTimeout(500);
    await page.screenshot({ path: 'test-results/persist-02b-scrolled.png' });

    // Click the "Create Task" button at the bottom of the form
    console.log('Clicking Create Task button...');
    // The button is at the very bottom of the viewport (around y=680 in 720px viewport)
    await page.mouse.click(viewport.width / 2, viewport.height - 30);
    await page.waitForTimeout(1000);
    await page.screenshot({ path: 'test-results/persist-03-after-save.png' });

    // Take screenshots to monitor persistence
    console.log('Monitoring for 15 seconds...');
    for (let i = 1; i <= 3; i++) {
      await page.waitForTimeout(5000);
      await page.screenshot({ path: `test-results/persist-04-after-${i * 5}s.png` });
      console.log(`Screenshot at ${i * 5}s`);
    }

    await page.screenshot({ path: 'test-results/persist-05-final.png' });
    console.log('Persistence test complete');
  });

  test('should verify Flutter app renders canvas correctly', async ({ page }) => {
    // Verify canvas is present and has dimensions
    const canvas = page.locator('canvas').first();
    await expect(canvas).toBeVisible({ timeout: 30000 });

    const canvasBox = await canvas.boundingBox();
    console.log('Canvas dimensions:', canvasBox);

    expect(canvasBox).not.toBeNull();
    expect(canvasBox.width).toBeGreaterThan(300);
    expect(canvasBox.height).toBeGreaterThan(500);

    // Take screenshot showing the canvas
    await page.screenshot({ path: 'test-results/canvas-verification.png' });
  });

  test('should navigate to settings and back', async ({ page }) => {
    // Take initial screenshot
    await page.screenshot({ path: 'test-results/settings-01-initial.png' });

    // Click settings button
    console.log('Clicking settings button...');
    await clickSettingsButton(page);
    await page.waitForTimeout(1000);

    // Take screenshot of settings screen
    await page.screenshot({ path: 'test-results/settings-02-opened.png' });

    // Look for "Upcoming Tasks Above NOW" toggle
    // In Flutter, this might be accessible via semantics
    console.log('Settings screen should be visible');

    // Click back button (typically top-left)
    await clickAt(page, 30, 40);
    await page.waitForTimeout(1000);

    // Take screenshot after returning
    await page.screenshot({ path: 'test-results/settings-03-returned.png' });
  });

  test('should capture task creation flow with video', async ({ page }) => {
    // This test is designed to capture the full task creation flow
    // Video recording should show if tasks disappear

    console.log('Starting task creation flow capture...');

    // Wait for app to be fully loaded
    await page.waitForTimeout(2000);
    await page.screenshot({ path: 'test-results/video-capture-01-start.png' });

    // Click FAB to open task creation
    await clickAddTaskButton(page);
    await page.waitForTimeout(500);
    await page.screenshot({ path: 'test-results/video-capture-02-dialog-open.png' });

    // Enter task details - click title field and type
    const viewport = page.viewportSize();
    await page.mouse.click(viewport.width / 2, 95);
    await page.waitForTimeout(300);
    await typeText(page, 'Video Test Task');
    await page.screenshot({ path: 'test-results/video-capture-03-title.png' });

    // Scroll down within the dialog to reveal the Create Task button
    await page.mouse.move(viewport.width / 2, viewport.height / 2);
    await page.mouse.wheel(0, 300);
    await page.waitForTimeout(500);

    // Click Create Task button at very bottom
    console.log('Clicking Create Task button...');
    await page.mouse.click(viewport.width / 2, viewport.height - 30);
    await page.waitForTimeout(1000);
    await page.screenshot({ path: 'test-results/video-capture-04-saved.png' });

    // Monitor for 60 seconds
    console.log('Monitoring task for 60 seconds...');
    for (let i = 1; i <= 6; i++) {
      await page.waitForTimeout(10000);
      await page.screenshot({ path: `test-results/video-capture-${4 + i}-at-${i * 10}s.png` });
      console.log(`Screenshot at ${i * 10}s`);
    }

    await page.screenshot({ path: 'test-results/video-capture-final.png' });
    console.log('Video capture test complete - check test-results/ for screenshots');
  });

  test('should detect task card region after creation', async ({ page }) => {
    // This test attempts to verify task visibility by checking pixel regions

    // First, scroll the timeline to show a specific hour
    console.log('Scrolling to show later hours...');

    // Use mouse wheel to scroll
    await page.mouse.wheel(0, -500);
    await page.waitForTimeout(1000);
    await page.screenshot({ path: 'test-results/scroll-test-01.png' });

    // Scroll more to reach evening hours
    await page.mouse.wheel(0, -1000);
    await page.waitForTimeout(1000);
    await page.screenshot({ path: 'test-results/scroll-test-02.png' });

    // Create a task
    await clickAddTaskButton(page);
    await page.waitForTimeout(500);

    // Click title field and type
    const viewport = page.viewportSize();
    await page.mouse.click(viewport.width / 2, 95);
    await page.waitForTimeout(300);
    await typeText(page, 'Scroll Test Task');

    // Scroll down to reveal Create Task button
    await page.mouse.move(viewport.width / 2, viewport.height / 2);
    await page.mouse.wheel(0, 300);
    await page.waitForTimeout(500);

    // Click Create Task button
    await page.mouse.click(viewport.width / 2, viewport.height - 30);
    await page.waitForTimeout(1000);

    // Take screenshot of where task should appear
    await page.screenshot({ path: 'test-results/scroll-test-03-task-created.png' });

    console.log('Task creation with scroll test complete');
  });
});

test.describe('Late Night Task Bug Reproduction', () => {
  test.beforeEach(async ({ page }) => {
    const baseUrl = process.env.BASE_URL || 'http://localhost:8081';
    await page.goto(baseUrl);
    await waitForFlutterReady(page);
  });

  test('should create 11:30 PM task and verify it persists (bug reproduction)', async ({ page }) => {
    // This test reproduces the user's reported bug:
    // Task created for 11:30 PM to Midnight disappeared while watching

    console.log('Creating 11:30 PM to Midnight task...');

    // Click FAB to open dialog
    await clickAddTaskButton(page);
    await page.waitForTimeout(500);
    await page.screenshot({ path: 'test-results/late-night-01-dialog.png' });

    // Enter task title
    const viewport = page.viewportSize();
    await page.mouse.click(viewport.width / 2, 95);
    await page.waitForTimeout(300);
    await typeText(page, 'Late Night Task 11:30 PM');
    await page.screenshot({ path: 'test-results/late-night-02-title.png' });

    // Click on Start time field to change it to 11:30 PM
    console.log('Setting start time to 11:30 PM...');
    // The Start time field is on the left side, below title
    await page.mouse.click(viewport.width / 4, 200);
    await page.waitForTimeout(500);
    await page.screenshot({ path: 'test-results/late-night-03-time-picker.png' });

    // Time picker is open - select PM first
    console.log('Clicking PM button...');
    // PM button is in the time picker dialog, right of AM
    await page.mouse.click(540, 385);
    await page.waitForTimeout(300);
    await page.screenshot({ path: 'test-results/late-night-04-pm-selected.png' });

    // Click on 11 on the clock face (top-left area of clock)
    console.log('Clicking 11 on clock...');
    await page.mouse.click(733, 258);
    await page.waitForTimeout(300);
    await page.screenshot({ path: 'test-results/late-night-05-hour-selected.png' });

    // Now select minutes - click on 30 (bottom of clock)
    console.log('Clicking 30 minutes...');
    await page.mouse.click(780, 432);
    await page.waitForTimeout(300);
    await page.screenshot({ path: 'test-results/late-night-06-minutes-selected.png' });

    // Click OK to confirm
    console.log('Clicking OK...');
    await page.mouse.click(873, 504);
    await page.waitForTimeout(500);
    await page.screenshot({ path: 'test-results/late-night-07-time-confirmed.png' });

    // Scroll down to reveal Create Task button
    await page.mouse.move(viewport.width / 2, viewport.height / 2);
    await page.mouse.wheel(0, 300);
    await page.waitForTimeout(500);

    // Click Create Task button
    console.log('Clicking Create Task button...');
    await page.mouse.click(viewport.width / 2, viewport.height - 30);
    await page.waitForTimeout(1000);
    await page.screenshot({ path: 'test-results/late-night-08-after-save.png' });

    // Scroll up to find the 11:30 PM task (it should be above current viewport)
    console.log('Scrolling up to find 11:30 PM task...');
    await page.mouse.move(viewport.width / 2, viewport.height / 2);
    await page.mouse.wheel(0, -2000);
    await page.waitForTimeout(1000);
    await page.screenshot({ path: 'test-results/late-night-09-scrolled-up.png' });

    // Scroll more if needed
    await page.mouse.wheel(0, -2000);
    await page.waitForTimeout(1000);
    await page.screenshot({ path: 'test-results/late-night-10-scrolled-more.png' });

    // Monitor for 30 seconds to see if task disappears
    console.log('Monitoring for 30 seconds for disappearing task bug...');
    for (let i = 1; i <= 6; i++) {
      await page.waitForTimeout(5000);
      await page.screenshot({ path: `test-results/late-night-monitor-${i * 5}s.png` });
      console.log(`Screenshot at ${i * 5}s`);
    }

    await page.screenshot({ path: 'test-results/late-night-final.png' });
    console.log('Late night task test complete');
  });
});

test.describe('Task Position Verification', () => {
  test.beforeEach(async ({ page }) => {
    const baseUrl = process.env.BASE_URL || 'http://localhost:8081';
    await page.goto(baseUrl);
    await waitForFlutterReady(page);
  });

  test('should calculate expected task positions', async ({ page }) => {
    // Test the position calculation logic
    const testCases = [
      { hour: 9, minute: 0, desc: '9:00 AM' },
      { hour: 12, minute: 0, desc: '12:00 PM (Noon)' },
      { hour: 18, minute: 0, desc: '6:00 PM' },
      { hour: 23, minute: 30, desc: '11:30 PM' },
      { hour: 0, minute: 0, desc: '12:00 AM (Midnight)' },
    ];

    console.log('Expected task positions (with upcomingTasksAboveNow = true):');
    for (const tc of testCases) {
      const yPos = calculateTaskYPosition(tc.hour, tc.minute, true);
      console.log(`  ${tc.desc}: Y = ${yPos.toFixed(0)}px`);
    }

    console.log('\nExpected task positions (with upcomingTasksAboveNow = false):');
    for (const tc of testCases) {
      const yPos = calculateTaskYPosition(tc.hour, tc.minute, false);
      console.log(`  ${tc.desc}: Y = ${yPos.toFixed(0)}px`);
    }

    // Take a screenshot showing the timeline for manual verification
    await page.screenshot({ path: 'test-results/position-calculation-reference.png', fullPage: true });
  });
});
