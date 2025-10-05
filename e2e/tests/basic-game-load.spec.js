import { test, expect } from '@playwright/test';

const BASE_URL = 'http://localhost:8080';
const DEFAULT_SEED = 'blue02orange';
const ALT_SEED = 'crimson51kite';

test.describe('Basic Game Load Tests', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto(BASE_URL);
    await page.waitForFunction(() => window.testHooksReady === true, { timeout: 15000 });
    await page.evaluate(async (seed) => {
      await window.testHooks.configureGame(seed, 'three');
    }, DEFAULT_SEED);
  });

  test('Game loads and can be configured via hooks', async ({ page }) => {
    const integrity = await page.evaluate(() => window.testHooks.validateCardIntegrity());
    expect(integrity.valid).toBe(true);
    expect(integrity.total).toBe(52);
    expect(integrity.unique).toBe(52);

    const stockCount = await page.evaluate(() => window.testHooks.getStockCount());
    expect(stockCount).toBeGreaterThan(0);

    const wasteCount = await page.evaluate(() => window.testHooks.getWasteCount());
    expect(wasteCount).toBeGreaterThan(0);

    const totalCards = await page.evaluate(() => window.testHooks.getTotalCardCount());
    expect(totalCards).toBe(52);
  });

  test('Single draw moves cards from stock to waste', async ({ page }) => {
    const countsBefore = await page.evaluate(() => ({
      stock: window.testHooks.getStockCount(),
      waste: window.testHooks.getWasteCount(),
    }));

    const result = await page.evaluate(async () => {
      return await window.testHooks.tapStock();
    });

    expect(result).toBe('draw');

    const countsAfter = await page.evaluate(() => ({
      stock: window.testHooks.getStockCount(),
      waste: window.testHooks.getWasteCount(),
    }));

    expect(countsAfter.stock).toBeLessThan(countsBefore.stock);
    expect(countsAfter.waste).toBeGreaterThan(countsBefore.waste);

    const integrity = await page.evaluate(() => window.testHooks.validateCardIntegrity());
    expect(integrity.valid).toBe(true);
  });

  test('Rapid stock taps maintain card integrity', async ({ page }) => {
    for (let i = 0; i < 10; i++) {
      await page.evaluate(async () => {
        await window.testHooks.tapStock();
      });
      const integrity = await page.evaluate(() => window.testHooks.validateCardIntegrity());
      expect(integrity.valid).toBe(true);
      expect(integrity.total).toBe(52);
    }
  });

  test('Recycling waste restores stock when empty', async ({ page }) => {
    await page.evaluate(async () => {
      let guard = 0;
      while (window.testHooks.getStockCount() > 0 && guard < 200) {
        await window.testHooks.tapStock();
        guard++;
      }
    });

    const recycleResult = await page.evaluate(async () => {
      return await window.testHooks.tapStock();
    });

    expect(recycleResult).toBe('recycle');

    const postRecycle = await page.evaluate(() => ({
      stock: window.testHooks.getStockCount(),
      waste: window.testHooks.getWasteCount(),
    }));

    // After recycling with auto-draw in DrawMode.three, stock should have (total - 3) and waste should have 3
    expect(postRecycle.stock).toBeGreaterThan(0);
    expect(postRecycle.waste).toBe(3);

    const integrity = await page.evaluate(() => window.testHooks.validateCardIntegrity());
    expect(integrity.valid).toBe(true);
  });

  test('Pending action count clears after draw', async ({ page }) => {
    const drawPromise = page.evaluate(async () => {
      return await window.testHooks.tapStock();
    });

    await page.waitForTimeout(20);

    const pendingDuring = await page.evaluate(() => window.testHooks.getPendingActionCount());
    expect(pendingDuring).toBeGreaterThan(0);

    await drawPromise;

    const pendingAfter = await page.evaluate(() => window.testHooks.getPendingActionCount());
    expect(pendingAfter).toBe(0);

    const integrity = await page.evaluate(() => window.testHooks.validateCardIntegrity());
    expect(integrity.valid).toBe(true);
  });

  test('Different seeds yield distinct stock order', async ({ page }) => {
    const initialSnapshot = await page.evaluate(() => window.testHooks.getStockSnapshot());
    const initialWaste = await page.evaluate(() => window.testHooks.getWasteSnapshot());

    await page.evaluate(async (seed) => {
      await window.testHooks.configureGame(seed, 'three');
    }, ALT_SEED);

    const nextSnapshot = await page.evaluate(() => window.testHooks.getStockSnapshot());
    const nextWaste = await page.evaluate(() => window.testHooks.getWasteSnapshot());

    expect(nextSnapshot).not.toEqual(initialSnapshot);
    expect(nextWaste).not.toEqual(initialWaste);

    const integrity = await page.evaluate(() => window.testHooks.validateCardIntegrity());
    expect(integrity.valid).toBe(true);
  });
});