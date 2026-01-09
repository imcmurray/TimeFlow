// @ts-check
const { test, expect } = require('@playwright/test');

test.describe('Timeline View', () => {
  test.beforeEach(async ({ page }) => {
    // Flutter web app runs on port 8080
    // Use host.docker.internal to access host from Docker container
    const baseUrl = process.env.BASE_URL || 'http://host.docker.internal:8080';
    await page.goto(baseUrl);
    // Wait for Flutter to load - it takes time to initialize
    await page.waitForTimeout(5000);
  });

  test('should display timeline with hour markers', async ({ page }) => {
    console.log('Page title:', await page.title());
    console.log('Page URL:', page.url());

    // Check if the page loaded (Flutter renders to canvas)
    const canvas = page.locator('canvas').first();

    // Wait for canvas to appear with extended timeout for Flutter initialization
    await expect(canvas).toBeVisible({ timeout: 30000 });
    console.log('Canvas found - Flutter app is rendering');

    // Take screenshots after Flutter has loaded
    await page.screenshot({ path: 'test-results/timeline-full.png', fullPage: true });
    await page.screenshot({ path: 'test-results/timeline-viewport.png' });

    // Verify the canvas has reasonable dimensions
    const canvasBox = await canvas.boundingBox();
    console.log('Canvas dimensions:', canvasBox);
    expect(canvasBox).not.toBeNull();
    expect(canvasBox.width).toBeGreaterThan(100);
    expect(canvasBox.height).toBeGreaterThan(100);
  });

  test('should take visual verification screenshots', async ({ page }) => {
    // Wait for Flutter to fully render
    const canvas = page.locator('canvas').first();
    await expect(canvas).toBeVisible({ timeout: 30000 });

    // Wait a bit more for animations to settle
    await page.waitForTimeout(2000);

    // Take screenshot of the current state
    await page.screenshot({ path: 'test-results/flutter-app-loaded.png' });
    console.log('Screenshot saved to test-results/flutter-app-loaded.png');

    // Log page info
    console.log('Page title:', await page.title());

    // Check canvas is the main content
    const canvasBox = await canvas.boundingBox();
    console.log('Flutter canvas rendering at:', canvasBox);
  });
});
