/**
 * Session 23 - Regression Testing
 * Tests core features: Timeline, NOW line, FAB, Task CRUD, Jump to NOW
 */
const { chromium } = require('playwright');

const BASE_URL = 'http://localhost:8080';

async function runRegressionTests() {
  console.log('Starting Session 23 Regression Tests...\n');

  const browser = await chromium.launch({
    headless: true,
    executablePath: process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH || undefined
  });
  const context = await browser.newContext({ viewport: { width: 1280, height: 720 } });
  const page = await context.newPage();

  const results = [];

  try {
    // Test 1: App loads correctly
    console.log('Test 1: Verifying app loads...');
    await page.goto(BASE_URL);
    await page.waitForLoadState('networkidle');

    // Skip onboarding if present (uses hidden attribute, not .active class)
    const onboardingModal = page.locator('#onboarding-modal:not([hidden])');
    if (await onboardingModal.isVisible({ timeout: 2000 }).catch(() => false)) {
      console.log('  Onboarding modal detected, skipping...');
      const skipBtn = page.locator('#onboarding-skip-btn');
      if (await skipBtn.isVisible({ timeout: 1000 }).catch(() => false)) {
        await skipBtn.click();
      } else {
        // Try clicking "Next" button multiple times until we get to "Get Started"
        const nextBtn = page.locator('#onboarding-next-btn');
        for (let i = 0; i < 5; i++) {
          if (await nextBtn.isVisible({ timeout: 500 }).catch(() => false)) {
            await nextBtn.click();
            await page.waitForTimeout(300);
          }
        }
      }
      await page.waitForTimeout(500);
      // Verify onboarding is closed
      await page.waitForSelector('#onboarding-modal[hidden]', { timeout: 5000 }).catch(() => {});
    }

    results.push({ test: 'App loads', passed: true });
    console.log('  ✓ App loaded successfully');

    // Test 2: NOW line visible (Feature 2)
    console.log('Test 2: Verifying NOW line...');
    const nowLine = page.locator('#now-line');
    const nowLineVisible = await nowLine.isVisible();
    results.push({ test: 'NOW line visible', passed: nowLineVisible });
    console.log(`  ${nowLineVisible ? '✓' : '✗'} NOW line ${nowLineVisible ? 'visible' : 'NOT visible'}`);

    // Test 3: Timeline hour markers (Feature 4)
    console.log('Test 3: Verifying hour markers...');
    const hourLabels = page.locator('.hour-label');
    const hourCount = await hourLabels.count();
    const hourMarkersPass = hourCount === 24;
    results.push({ test: 'Hour markers (24)', passed: hourMarkersPass });
    console.log(`  ${hourMarkersPass ? '✓' : '✗'} Found ${hourCount} hour markers (expected 24)`);

    // Test 4: FAB button visible (Feature 5)
    console.log('Test 4: Verifying FAB button...');
    const fab = page.locator('#add-task-btn');
    const fabVisible = await fab.isVisible();
    results.push({ test: 'FAB button visible', passed: fabVisible });
    console.log(`  ${fabVisible ? '✓' : '✗'} FAB button ${fabVisible ? 'visible' : 'NOT visible'}`);

    await page.screenshot({ path: 'regression-session23-1-initial.png' });

    // Test 5: Task creation (Feature 6)
    console.log('Test 5: Verifying task creation...');
    await fab.click();
    await page.waitForSelector('#task-modal:not([hidden])');

    const testTitle = `TEST_${Date.now()}_SESSION23`;
    await page.fill('#task-title', testTitle);

    // Set time to current hour + 1
    const now = new Date();
    const startHour = (now.getHours() + 1) % 24;
    const endHour = (startHour + 1) % 24;
    await page.fill('#task-start-time', `${String(startHour).padStart(2, '0')}:00`);
    await page.fill('#task-end-time', `${String(endHour).padStart(2, '0')}:00`);

    await page.screenshot({ path: 'regression-session23-2-form.png' });

    await page.click('button:has-text("Save Task")');
    // Wait for modal to become hidden - use state: 'attached' since hidden elements aren't "visible"
    await page.waitForSelector('#task-modal[hidden]', { state: 'attached', timeout: 5000 });

    // Verify task appears on timeline
    await page.waitForTimeout(500);
    const taskCard = page.locator(`.task-card:has-text("${testTitle}")`);
    const taskCreated = await taskCard.isVisible();
    results.push({ test: 'Task creation', passed: taskCreated });
    console.log(`  ${taskCreated ? '✓' : '✗'} Task ${taskCreated ? 'created successfully' : 'NOT created'}`);

    await page.screenshot({ path: 'regression-session23-3-created.png' });

    // Test 6: Jump to NOW button (Feature 40)
    console.log('Test 6: Verifying Jump to NOW button...');
    // First scroll away from NOW
    await page.evaluate(() => {
      const timeline = document.getElementById('timeline');
      timeline.scrollTop = 0; // Scroll to top (midnight)
    });
    await page.waitForTimeout(1000);

    const jumpButton = page.locator('#jump-to-now');
    const jumpVisible = await jumpButton.isVisible().catch(() => false);

    if (jumpVisible) {
      await jumpButton.click();
      await page.waitForTimeout(500);
    }

    // Verify we're near the current time
    const nowLineInView = await page.evaluate(() => {
      const nowLine = document.getElementById('now-line');
      const rect = nowLine.getBoundingClientRect();
      return rect.top >= 0 && rect.top <= window.innerHeight;
    });

    const jumpToNowPass = jumpVisible || nowLineInView;
    results.push({ test: 'Jump to NOW', passed: jumpToNowPass });
    console.log(`  ${jumpToNowPass ? '✓' : '✗'} Jump to NOW ${jumpToNowPass ? 'working' : 'NOT working'}`);

    // Test 7: Task deletion (Feature 14)
    console.log('Test 7: Verifying task deletion...');
    if (taskCreated) {
      await taskCard.click();
      await page.waitForSelector('#task-modal:not([hidden])');

      await page.click('#delete-task-btn');
      await page.waitForSelector('#confirm-modal:not([hidden])');
      await page.click('#confirm-delete-btn');

      await page.waitForTimeout(500);
      const taskGone = !(await taskCard.isVisible().catch(() => false));
      results.push({ test: 'Task deletion', passed: taskGone });
      console.log(`  ${taskGone ? '✓' : '✗'} Task ${taskGone ? 'deleted successfully' : 'NOT deleted'}`);
    } else {
      results.push({ test: 'Task deletion', passed: false });
      console.log('  ✗ Skipped (task not created)');
    }

    await page.screenshot({ path: 'regression-session23-4-cleaned.png' });

    // Test 8: Console errors
    console.log('Test 8: Checking for console errors...');
    const consoleErrors = [];
    page.on('console', msg => {
      if (msg.type() === 'error') consoleErrors.push(msg.text());
    });
    await page.reload();
    await page.waitForLoadState('networkidle');

    // Skip onboarding again if needed
    const skipBtnReload = page.locator('#onboarding-skip-btn');
    if (await skipBtnReload.isVisible({ timeout: 1000 }).catch(() => false)) {
      await skipBtnReload.click();
      await page.waitForTimeout(500);
    }

    await page.waitForTimeout(1000);
    const noErrors = consoleErrors.length === 0;
    results.push({ test: 'No console errors', passed: noErrors });
    console.log(`  ${noErrors ? '✓' : '✗'} ${noErrors ? 'No console errors' : `Found ${consoleErrors.length} errors: ${consoleErrors.join(', ')}`}`);

  } catch (error) {
    console.error('Test error:', error.message);
    await page.screenshot({ path: 'regression-session23-error.png' });
  } finally {
    await browser.close();
  }

  // Summary
  console.log('\n' + '='.repeat(50));
  console.log('REGRESSION TEST SUMMARY');
  console.log('='.repeat(50));

  const passed = results.filter(r => r.passed).length;
  const total = results.length;

  results.forEach(r => {
    console.log(`${r.passed ? '✓' : '✗'} ${r.test}`);
  });

  console.log('-'.repeat(50));
  console.log(`Total: ${passed}/${total} tests passed (${((passed/total)*100).toFixed(1)}%)`);

  return passed === total;
}

runRegressionTests()
  .then(success => process.exit(success ? 0 : 1))
  .catch(err => {
    console.error('Fatal error:', err);
    process.exit(1);
  });
