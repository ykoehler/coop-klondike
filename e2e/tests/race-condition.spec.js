import { test, expect } from '@playwright/test';

test.describe('Firebase Race Condition Tests', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('http://localhost:8080');
    await page.waitForFunction(() => window.testHooksReady === true, { timeout: 10000 });
  });

  test('Rapid stock drawing should maintain card integrity', async ({ page }) => {
    // Configure a specific seed for reproducibility
    await page.evaluate(() => window.testHooks.configureGame('blue02orange', 'three'));
    
    console.log('Starting rapid stock draw test...');
    
    // Validate initial state
    let integrity = await page.evaluate(() => window.testHooks.validateCardIntegrity());
    expect(integrity.valid).toBe(true);
    expect(integrity.total).toBe(52);
    expect(integrity.unique).toBe(52);
    
    // Rapidly draw cards - simulate clicking stock very fast
    // This should trigger potential race conditions between:
    // 1. Local drawCard mutation
    // 2. Firebase updateGame
    // 3. Firebase listenToGame update
    const drawCount = 10;
    const results = [];
    
    for (let i = 0; i < drawCount; i++) {
      const result = await page.evaluate(() => window.testHooks.tapStock());
      results.push(result);
      
      // Check integrity after each draw
      integrity = await page.evaluate(() => window.testHooks.validateCardIntegrity());
      
      console.log(`Draw ${i + 1}: ${result}, Total: ${integrity.total}, Unique: ${integrity.unique}, Valid: ${integrity.valid}`);
      
      // CRITICAL: Card integrity must be maintained
      if (!integrity.valid) {
        console.error(`❌ CARD INTEGRITY VIOLATION after draw ${i + 1}!`);
        console.error(`   Total cards: ${integrity.total} (expected 52)`);
        console.error(`   Unique cards: ${integrity.unique} (expected 52)`);
        console.error(`   Duplicates: ${integrity.duplicates}`);
        console.error(`   Missing: ${integrity.missing}`);
        console.error(`   Extra: ${integrity.extra}`);
      }
      
      expect(integrity.valid).toBe(true);
      expect(integrity.total).toBe(52);
      expect(integrity.unique).toBe(52);
      
      // Small delay to allow Firebase sync but fast enough to potentially race
      await page.waitForTimeout(50);
    }
    
    console.log(`✅ Completed ${drawCount} draws without integrity violations`);
    console.log(`   Results: ${results.join(', ')}`);
  });

  test('Simultaneous draws should not corrupt card state', async ({ page, browser }) => {
    // This test simulates two players drawing from stock simultaneously
    // by opening two browser contexts with the same game
    
    await page.evaluate(() => window.testHooks.configureGame('blue02orange', 'three'));
    await page.waitForTimeout(500); // Let Firebase sync
    
    // Open second tab/context
    const context2 = await browser.newContext();
    const page2 = await context2.newPage();
    await page2.goto('http://localhost:8080');
    await page2.waitForFunction(() => window.testHooksReady === true, { timeout: 10000 });
    
    console.log('Setting up second player context...');
    
    // Verify both see the same initial state
    let integrity1 = await page.evaluate(() => window.testHooks.validateCardIntegrity());
    let integrity2 = await page2.evaluate(() => window.testHooks.validateCardIntegrity());
    
    expect(integrity1.valid).toBe(true);
    expect(integrity2.valid).toBe(true);
    
    console.log('Both players see valid initial state');
    
    // Now both players rapidly draw - this should trigger race conditions
    const draws = 5;
    for (let i = 0; i < draws; i++) {
      // Both click at nearly the same time
      const [result1, result2] = await Promise.all([
        page.evaluate(() => window.testHooks.tapStock()),
        page2.evaluate(() => window.testHooks.tapStock())
      ]);
      
      console.log(`Simultaneous draw ${i + 1}: Player1=${result1}, Player2=${result2}`);
      
      // Wait for Firebase to sync
      await page.waitForTimeout(200);
      
      // Check integrity on both clients
      integrity1 = await page.evaluate(() => window.testHooks.validateCardIntegrity());
      integrity2 = await page2.evaluate(() => window.testHooks.validateCardIntegrity());
      
      console.log(`  Player1: Total=${integrity1.total}, Unique=${integrity1.unique}, Valid=${integrity1.valid}`);
      console.log(`  Player2: Total=${integrity2.total}, Unique=${integrity2.unique}, Valid=${integrity2.valid}`);
      
      // Both should see valid state (eventually consistent)
      expect(integrity1.valid).toBe(true);
      expect(integrity2.valid).toBe(true);
    }
    
    await context2.close();
    console.log('✅ Simultaneous draw test completed');
  });

  test('Drain stock completely with no pauses', async ({ page }) => {
    await page.evaluate(() => window.testHooks.configureGame('blue02orange', 'three'));
    
    console.log('Draining stock completely with rapid clicks...');
    
    let clickCount = 0;
    const maxClicks = 30; // Enough to drain and recycle
    
    while (clickCount < maxClicks) {
      const stockCount = await page.evaluate(() => window.testHooks.getStockCount());
      const wasteCount = await page.evaluate(() => window.testHooks.getWasteCount());
      
      if (stockCount === 0 && wasteCount === 0) {
        console.log('Stock and waste both empty - stopping');
        break;
      }
      
      const result = await page.evaluate(() => window.testHooks.tapStock());
      clickCount++;
      
      const integrity = await page.evaluate(() => window.testHooks.validateCardIntegrity());
      
      console.log(`Click ${clickCount}: ${result}, Stock=${await page.evaluate(() => window.testHooks.getStockCount())}, Waste=${await page.evaluate(() => window.testHooks.getWasteCount())}, Valid=${integrity.valid}`);
      
      if (!integrity.valid) {
        console.error(`❌ INTEGRITY VIOLATION at click ${clickCount}!`);
        console.error(`   Action: ${result}`);
        console.error(`   Total: ${integrity.total}, Unique: ${integrity.unique}`);
      }
      
      expect(integrity.valid).toBe(true);
      
      // NO delay - click as fast as possible to trigger race
    }
    
    console.log(`✅ Drained stock in ${clickCount} clicks without violations`);
  });

  test('Verify pending actions are tracked correctly', async ({ page }) => {
    await page.evaluate(() => window.testHooks.configureGame('blue02orange', 'three'));
    
    console.log('Testing pending action tracking...');
    
    // Start a draw and immediately check if pending action is tracked
    const drawPromise = page.evaluate(() => window.testHooks.tapStock());
    
    // Immediately check pending action count (should be > 0)
    await page.waitForTimeout(10);
    const pendingDuringDraw = await page.evaluate(() => window.testHooks.getPendingActionCount());
    
    console.log(`Pending actions during draw: ${pendingDuringDraw}`);
    
    // Wait for completion
    await drawPromise;
    
    // Should be 0 after completion
    const pendingAfterDraw = await page.evaluate(() => window.testHooks.getPendingActionCount());
    
    console.log(`Pending actions after draw: ${pendingAfterDraw}`);
    expect(pendingAfterDraw).toBe(0);
    
    // Verify integrity maintained
    const integrity = await page.evaluate(() => window.testHooks.validateCardIntegrity());
    expect(integrity.valid).toBe(true);
  });
});
