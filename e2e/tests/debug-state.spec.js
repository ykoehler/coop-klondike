import { test, expect } from '@playwright/test';

test.describe('Debug State Tests', () => {
  test('Check initial state after configureGame', async ({ page }) => {
    await page.goto('http://localhost:8080');
    await page.waitForFunction(() => window.testHooksReady === true, { timeout: 10000 });
    
    console.log('Test hooks ready, configuring game...');
    
    // Configure the game
    await page.evaluate(() => window.testHooks.configureGame('blue02orange', 'three'));
    
    console.log('Game configured, checking state...');
    
    // Check the debug state
    const debugState = await page.evaluate(() => window.testHooks.getDebugState());
    console.log('Debug state:', JSON.stringify(debugState, null, 2));
    
    // Check card counts
    const stockCount = await page.evaluate(() => window.testHooks.getStockCount());
    const wasteCount = await page.evaluate(() => window.testHooks.getWasteCount());
    const totalCount = await page.evaluate(() => window.testHooks.getTotalCardCount());
    
    console.log(`Stock: ${stockCount}, Waste: ${wasteCount}, Total: ${totalCount}`);
    
    // Try to call tapStock and see what happens
    console.log('Attempting to tap stock...');
    try {
      const result = await page.evaluate(() => {
        return Promise.race([
          window.testHooks.tapStock(),
          new Promise((_, reject) => 
            setTimeout(() => reject(new Error('tapStock timeout after 5s')), 5000)
          )
        ]);
      });
      console.log('tapStock result:', result);
    } catch (error) {
      console.error('tapStock failed:', error.message);
      
      // Check state again after failure
      const debugStateAfter = await page.evaluate(() => window.testHooks.getDebugState());
      console.log('Debug state after failure:', JSON.stringify(debugStateAfter, null, 2));
    }
  });
});
