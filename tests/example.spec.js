// @ts-check
const { test, expect } = require('@playwright/test');

test.describe('TimeFlow Web App', () => {
  test('should load the homepage', async ({ page }) => {
    await page.goto('/');

    // Wait for page to load
    await page.waitForLoadState('networkidle');

    // Check that the page loaded successfully
    await expect(page).toHaveTitle(/TimeFlow/i);
  });

  test('should display the main content', async ({ page }) => {
    await page.goto('/');

    // Wait for the page to be fully loaded
    await page.waitForLoadState('domcontentloaded');

    // Check for main content area
    const body = await page.locator('body');
    await expect(body).toBeVisible();
  });

  test('should be responsive on mobile', async ({ page }) => {
    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });

    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Verify page is still accessible on mobile
    await expect(page).toHaveTitle(/TimeFlow/i);
  });
});

test.describe('Navigation', () => {
  test('should handle navigation between pages', async ({ page }) => {
    await page.goto('/');

    // Example: test navigation if your app has multiple routes
    // await page.click('a[href="/about"]');
    // await expect(page).toHaveURL(/\/about/);
  });
});

test.describe('Performance', () => {
  test('should load within acceptable time', async ({ page }) => {
    const startTime = Date.now();

    await page.goto('/');
    await page.waitForLoadState('load');

    const loadTime = Date.now() - startTime;

    // Page should load in less than 3 seconds
    expect(loadTime).toBeLessThan(3000);
  });
});
