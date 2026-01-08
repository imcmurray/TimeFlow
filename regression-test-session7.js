// Session 7 Regression Test - Verify core features before new work
const { chromium } = require('playwright');
const path = require('path');
const os = require('os');

const BROWSER_PATH = path.join(os.homedir(), '.cache/ms-playwright/chromium-1200/chrome-linux64/chrome');
const BASE_URL = 'http://localhost:3000';

async function runRegressionTests() {
  console.log('=== Session 7 Regression Test ===\n');

  const browser = await chromium.launch({
    executablePath: BROWSER_PATH,
    headless: true
  });

  const page = await browser.newPage();
  await page.setViewportSize({ width: 375, height: 667 });

  const results = [];

  try {
    // Test 1: App loads
    console.log('Test 1: App loads...');
    await page.goto(BASE_URL);
    await page.waitForSelector('.timeline-container', { timeout: 5000 });
    const title = await page.title();
    results.push({ test: 'App loads', pass: title.includes('TimeFlow'), detail: title });

    // Test 2: NOW line visible
    console.log('Test 2: NOW line visible...');
    const nowLine = await page.$('.now-line');
    const nowVisible = nowLine && await nowLine.isVisible();
    results.push({ test: 'NOW line visible', pass: nowVisible, detail: nowVisible ? 'visible' : 'not found' });

    // Test 3: Hour markers present (class is .hour-block, not .hour-row)
    console.log('Test 3: Hour markers...');
    await page.waitForTimeout(1000); // Give JS time to render
    const hourMarkers = await page.$$('.hour-block');
    results.push({ test: 'Hour markers', pass: hourMarkers.length >= 20, detail: `${hourMarkers.length} markers` });

    // Test 4: FAB visible
    console.log('Test 4: FAB button...');
    const fab = await page.$('.fab');
    const fabVisible = fab && await fab.isVisible();
    results.push({ test: 'FAB visible', pass: fabVisible, detail: fabVisible ? 'visible' : 'not found' });

    // Test 5: Create a task
    console.log('Test 5: Create task...');
    await fab.click();

    // Modal uses hidden attribute, not active class
    await page.waitForFunction(() => {
      const modal = document.querySelector('#task-modal');
      return modal && !modal.hidden;
    }, { timeout: 3000 });

    const uniqueTitle = `TEST_REGRESSION_${Date.now()}`;
    await page.fill('#task-title', uniqueTitle);
    await page.fill('#task-start-time', '14:00');
    await page.fill('#task-end-time', '15:00');

    // Click save button (the form submit)
    await page.click('button[type="submit"]');

    // Wait for modal to close
    await page.waitForFunction(() => {
      const modal = document.querySelector('#task-modal');
      return modal && modal.hidden;
    }, { timeout: 3000 });
    await page.waitForTimeout(500);

    // Verify task appears by looking for task card with that title
    const taskCard = await page.$(`.task-card:has-text("${uniqueTitle}")`);
    results.push({ test: 'Create task', pass: !!taskCard, detail: taskCard ? 'task created' : 'task not found' });

    // Test 6: Settings accessible
    console.log('Test 6: Settings...');
    const settingsBtn = await page.$('#settings-btn');
    await settingsBtn.click();

    await page.waitForFunction(() => {
      const modal = document.querySelector('#settings-modal');
      return modal && !modal.hidden;
    }, { timeout: 3000 });

    const themeSelect = await page.$('#theme-select');
    results.push({ test: 'Settings accessible', pass: !!themeSelect, detail: themeSelect ? 'theme select found' : 'not found' });

    // Close settings
    await page.click('#close-settings-btn');
    await page.waitForTimeout(300);

    // Test 7: Delete the test task
    console.log('Test 7: Delete task...');
    const taskToClick = await page.$(`.task-card:has-text("${uniqueTitle}")`);
    if (taskToClick) {
      await taskToClick.click();
    } else {
      throw new Error('Task card not found for delete test');
    }

    // Wait for task detail modal (reuses task-modal)
    await page.waitForFunction(() => {
      const modal = document.querySelector('#task-modal');
      return modal && !modal.hidden;
    }, { timeout: 3000 });

    await page.click('#delete-task-btn');

    // Handle confirmation dialog
    await page.waitForFunction(() => {
      const modal = document.querySelector('#confirm-modal');
      return modal && !modal.hidden;
    }, { timeout: 3000 });

    await page.click('#confirm-delete-btn');

    // Wait for delete to complete and modal to close
    await page.waitForFunction(() => {
      const modal = document.querySelector('#task-modal');
      return modal && modal.hidden;
    }, { timeout: 3000 });
    await page.waitForTimeout(1000); // Wait for any toast to disappear

    // Verify deleted - look specifically for task-card
    const deletedTask = await page.$(`.task-card:has-text("${uniqueTitle}")`);
    results.push({ test: 'Delete task', pass: !deletedTask, detail: deletedTask ? 'still exists' : 'deleted successfully' });

    await page.screenshot({ path: 'regression-session7.png' });

  } catch (error) {
    console.error('Test error:', error.message);
    await page.screenshot({ path: 'regression-session7-error.png' });
    results.push({ test: 'Error', pass: false, detail: error.message });
  }

  await browser.close();

  // Print results
  console.log('\n=== Results ===');
  let passed = 0, failed = 0;
  for (const r of results) {
    const status = r.pass ? '✓ PASS' : '✗ FAIL';
    console.log(`${status}: ${r.test} - ${r.detail}`);
    if (r.pass) passed++; else failed++;
  }
  console.log(`\nTotal: ${passed}/${results.length} passed`);

  if (failed > 0) {
    console.log('\n⚠️  REGRESSION DETECTED - Fix issues before new work!');
    process.exit(1);
  } else {
    console.log('\n✅ All regression tests passed - safe to proceed');
    process.exit(0);
  }
}

runRegressionTests().catch(console.error);
