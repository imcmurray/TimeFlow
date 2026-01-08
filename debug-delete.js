// Debug delete functionality
const { chromium } = require('playwright');
const path = require('path');
const os = require('os');

const BROWSER_PATH = path.join(os.homedir(), '.cache/ms-playwright/chromium-1200/chrome-linux64/chrome');
const BASE_URL = 'http://localhost:3000';

async function debugDelete() {
  const browser = await chromium.launch({
    executablePath: BROWSER_PATH,
    headless: true
  });

  const page = await browser.newPage();
  await page.setViewportSize({ width: 375, height: 667 });

  // Log console messages
  page.on('console', msg => console.log('Console:', msg.text()));

  await page.goto(BASE_URL);
  await page.waitForTimeout(1000);

  // Check hour marker structure
  const hourHTML = await page.evaluate(() => {
    const timeline = document.querySelector('#timeline');
    return timeline ? timeline.innerHTML.substring(0, 1000) : 'NOT FOUND';
  });
  console.log('\nTimeline HTML (first 1000 chars):\n', hourHTML);

  // Count various selectors
  const selectors = ['.hour-row', '.hour-marker', '[class*="hour"]', '[class*="marker"]'];
  for (const sel of selectors) {
    const count = await page.$$eval(sel, els => els.length);
    console.log(`Selector "${sel}": ${count} elements`);
  }

  // Create a task
  const fab = await page.$('.fab');
  await fab.click();
  await page.waitForTimeout(500);

  const uniqueTitle = `DELETE_TEST_${Date.now()}`;
  await page.fill('#task-title', uniqueTitle);
  await page.fill('#task-start-time', '14:00');
  await page.fill('#task-end-time', '15:00');
  await page.click('button[type="submit"]');
  await page.waitForTimeout(500);

  console.log('\nCreated task:', uniqueTitle);
  await page.screenshot({ path: 'debug-delete-1-created.png' });

  // Click on the task
  await page.click(`text=${uniqueTitle}`);
  await page.waitForTimeout(500);

  // Check if delete button is visible
  const deleteBtn = await page.$('#delete-task-btn');
  const deleteBtnHidden = await page.evaluate(() => {
    const btn = document.querySelector('#delete-task-btn');
    return btn ? btn.hidden : 'btn not found';
  });
  console.log('Delete button hidden:', deleteBtnHidden);

  await page.screenshot({ path: 'debug-delete-2-detail.png' });

  // Try to click delete
  if (deleteBtn && !deleteBtnHidden) {
    await deleteBtn.click();
    await page.waitForTimeout(500);
    await page.screenshot({ path: 'debug-delete-3-confirm.png' });

    // Check confirm dialog
    const confirmModal = await page.$('#confirm-modal');
    const confirmHidden = await page.evaluate(() => {
      const m = document.querySelector('#confirm-modal');
      return m ? m.hidden : 'not found';
    });
    console.log('Confirm modal hidden:', confirmHidden);

    if (!confirmHidden) {
      await page.click('#confirm-delete-btn');
      await page.waitForTimeout(500);
      await page.screenshot({ path: 'debug-delete-4-after.png' });
    }
  }

  // Check if task exists
  const taskExists = await page.$(`text=${uniqueTitle}`);
  console.log('Task still exists:', !!taskExists);

  await browser.close();
}

debugDelete().catch(console.error);
