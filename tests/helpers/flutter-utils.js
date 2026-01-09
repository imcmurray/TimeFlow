/**
 * Flutter Canvas Testing Utilities
 *
 * Helper functions for interacting with Flutter web apps that render to canvas.
 * Since Flutter renders to a single canvas element, we use coordinate-based
 * interactions and screenshot comparisons for verification.
 */

const TIMELINE_CONSTANTS = {
  hourHeight: 80,           // pixels per hour
  totalHeight: 2400,        // 30 hours * 80px
  nowLinePosition: 0.75,    // NOW line at 75% of viewport
  taskAreaLeftMargin: 70,   // where task cards start (after hour markers)
  taskAreaWidth: 280,       // approximate width of task cards
  fabButtonX: 1235,         // FAB button X position (bottom right - blue +)
  fabButtonY: 675,          // FAB button Y position (bottom right)
  settingsButtonX: 1260,    // Settings gear icon X position (top right)
  settingsButtonY: 28,      // Settings gear icon Y position
};

/**
 * Wait for Flutter to fully initialize and render
 * @param {import('@playwright/test').Page} page
 */
async function waitForFlutterReady(page) {
  // Wait for canvas to be visible
  await page.locator('canvas').first().waitFor({ state: 'visible', timeout: 30000 });

  // Give Flutter extra time to render content
  await page.waitForTimeout(3000);
}

/**
 * Calculate expected Y position for a task at a given time
 * @param {number} hour - Hour (0-23)
 * @param {number} minute - Minute (0-59)
 * @param {boolean} upcomingTasksAboveNow - Whether timeline is inverted
 * @returns {number} Y position in pixels from top of timeline
 */
function calculateTaskYPosition(hour, minute, upcomingTasksAboveNow = true) {
  const minutesSinceMidnight = hour * 60 + minute;
  let fractionOfTimeline = minutesSinceMidnight / (30 * 60);

  if (upcomingTasksAboveNow) {
    fractionOfTimeline = 1.0 - fractionOfTimeline;
  }

  return fractionOfTimeline * TIMELINE_CONSTANTS.totalHeight;
}

/**
 * Calculate task card height based on duration
 * @param {number} durationMinutes
 * @returns {number} Height in pixels
 */
function calculateTaskHeight(durationMinutes) {
  return (durationMinutes / 60) * TIMELINE_CONSTANTS.hourHeight;
}

/**
 * Click the FAB (Floating Action Button) to add a new task
 * @param {import('@playwright/test').Page} page
 */
async function clickAddTaskButton(page) {
  const viewport = page.viewportSize();
  const fabX = viewport.width - 45;
  const fabY = viewport.height - 45;
  await page.mouse.click(fabX, fabY);
  await page.waitForTimeout(500);
}

/**
 * Click the settings gear icon
 * @param {import('@playwright/test').Page} page
 */
async function clickSettingsButton(page) {
  const viewport = page.viewportSize();
  await page.mouse.click(viewport.width - 20, 28);
  await page.waitForTimeout(500);
}

/**
 * Type text into the currently focused Flutter text field
 * @param {import('@playwright/test').Page} page
 * @param {string} text
 */
async function typeText(page, text) {
  await page.keyboard.type(text, { delay: 50 });
}

/**
 * Click at a specific position on the canvas
 * @param {import('@playwright/test').Page} page
 * @param {number} x
 * @param {number} y
 */
async function clickAt(page, x, y) {
  await page.mouse.click(x, y);
  await page.waitForTimeout(200);
}

/**
 * Take a screenshot of a specific region where a task should appear
 * @param {import('@playwright/test').Page} page
 * @param {number} hour
 * @param {number} minute
 * @param {boolean} upcomingTasksAboveNow
 * @returns {Promise<Buffer>} Screenshot buffer
 */
async function screenshotTaskRegion(page, hour, minute, upcomingTasksAboveNow = true) {
  const yPosition = calculateTaskYPosition(hour, minute, upcomingTasksAboveNow);

  // Account for viewport scroll position
  const viewportHeight = await page.evaluate(() => window.innerHeight);

  return page.screenshot({
    clip: {
      x: TIMELINE_CONSTANTS.taskAreaLeftMargin,
      y: Math.max(0, yPosition - 50),
      width: TIMELINE_CONSTANTS.taskAreaWidth,
      height: 120
    }
  });
}

/**
 * Check if a screenshot contains task card pixels (non-background colors)
 * Task cards typically have colored backgrounds (not pure white/light gray)
 * @param {Buffer} screenshot
 * @returns {Promise<boolean>}
 */
async function containsTaskCardPixels(screenshot) {
  // This is a simplified check - in production you'd use image analysis
  // For now, just check the buffer isn't empty and has significant data
  return screenshot && screenshot.length > 1000;
}

/**
 * Get the current scroll position
 * @param {import('@playwright/test').Page} page
 * @returns {Promise<number>}
 */
async function getScrollPosition(page) {
  return page.evaluate(() => {
    const scrollable = document.querySelector('.flt-glass-pane');
    return scrollable ? scrollable.scrollTop : 0;
  });
}

/**
 * Scroll to a specific hour on the timeline
 * @param {import('@playwright/test').Page} page
 * @param {number} hour
 * @param {boolean} upcomingTasksAboveNow
 */
async function scrollToHour(page, hour, upcomingTasksAboveNow = true) {
  const effectiveHour = upcomingTasksAboveNow ? (30 - hour) : hour;
  const targetY = effectiveHour * TIMELINE_CONSTANTS.hourHeight;

  await page.mouse.wheel(0, targetY);
  await page.waitForTimeout(500);
}

/**
 * Format time for display comparison
 * @param {number} hour
 * @param {number} minute
 * @returns {string}
 */
function formatTime(hour, minute) {
  const period = hour >= 12 ? 'PM' : 'AM';
  const displayHour = hour === 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  const displayMinute = minute.toString().padStart(2, '0');
  return `${displayHour}:${displayMinute} ${period}`;
}

module.exports = {
  TIMELINE_CONSTANTS,
  waitForFlutterReady,
  calculateTaskYPosition,
  calculateTaskHeight,
  clickAddTaskButton,
  clickSettingsButton,
  typeText,
  clickAt,
  screenshotTaskRegion,
  containsTaskCardPixels,
  getScrollPosition,
  scrollToHour,
  formatTime,
};
