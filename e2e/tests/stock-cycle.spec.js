import { test, expect } from '@playwright/test';

const DRAW_MODES = [
  {
    label: '1 Card',
    seed: 'e2e-draw-one-seed',
    modeKey: 'one',
    handSize: 1,
    initialStock: 23, // 52 - 28 (tableau) - 1 (initial draw)
    expectation: {
      clicks: 23,
    },
  },
  {
    label: '3 Cards',
    seed: 'e2e-draw-three-seed',
    modeKey: 'three',
    handSize: 3,
    initialStock: 21, // 52 - 28 (tableau) - 3 (initial draw)
    expectation: {
      clicks: 7,
    },
  },
];

async function waitForTestHooks(page) {
  await page.waitForFunction(() => window.testHooksReady === true, null, {
    timeout: 20000,
  });
}

async function waitForIdle(page) {
  await page.evaluate(async () => {
    if (!window.testHooks) {
      throw new Error('testHooks not registered');
    }
    await window.testHooks.waitForIdle();
  });
}

async function resetServiceWorkerAndCaches(page) {
  await page.evaluate(async () => {
    if ('serviceWorker' in navigator) {
      const registrations = await navigator.serviceWorker.getRegistrations();
      await Promise.all(registrations.map((reg) => reg.unregister()));
    }
    if (typeof caches !== 'undefined') {
      const cacheNames = await caches.keys();
      await Promise.all(cacheNames.map((name) => caches.delete(name)));
    }
  });
}

async function configureNewGame(page, { seed, modeKey }) {
  await page.evaluate(async ({ seedValue, mode }) => {
    await window.testHooks.configureGame(seedValue, mode);
  }, { seedValue: seed, mode: modeKey });
}

async function getStockCount(page) {
  return page.evaluate(() => window.testHooks.getStockCount());
}

async function getWasteCount(page) {
  return page.evaluate(() => window.testHooks.getWasteCount());
}

async function drainStock(page) {
  const draws = [];
  let safetyCounter = 0;

  while (true) {
    const stockCount = await getStockCount(page);
    if (stockCount === 0) {
      break;
    }

    safetyCounter += 1;
    if (safetyCounter > 40) {
      throw new Error('Exceeded maximum draw operations while draining stock');
    }

    // Capture snapshots and perform tap in one evaluation to avoid interop issues
    const result = await page.evaluate(async () => {
      const stockBefore = await window.testHooks.getStockSnapshot();
      const wasteBefore = await window.testHooks.getWasteSnapshot();
      
      // Call tapStock and see what it returns
      const rawAction = window.testHooks.tapStock();
      const actionType = typeof rawAction;
      const actionConstructor = rawAction && rawAction.constructor ? rawAction.constructor.name : 'null';
      const hasThenable = rawAction && typeof rawAction.then === 'function';
      
      // If it's thenable, await it
      const action = hasThenable ? await rawAction : rawAction;
      const finalType = typeof action;
      
      await window.testHooks.waitForIdle();
      const stockAfter = await window.testHooks.getStockSnapshot();
      const wasteAfter = await window.testHooks.getWasteSnapshot();

      return {
        action,
        actionType: finalType,
        actionStringified: String(action),
        rawActionType: actionType,
        actionConstructor,
        hasThenable,
        stockBefore,
        wasteBefore,
        stockAfter,
        wasteAfter,
      };
    });

    if (draws.length === 0) {
      console.log('First tap debug:', {
        actionType: result.actionType,
        rawActionType: result.rawActionType,
        actionConstructor: result.actionConstructor,
        hasThenable: result.hasThenable,
        actionStringified: result.actionStringified,
      });
    }

    if (result.action !== 'draw') {
      throw new Error(`Unexpected stock action while draining: ${result.action} (type: ${result.actionType}, stringified: ${result.actionStringified})`);
    }

    // Calculate cards moved from stock to waste
    const cardsDrawn = result.stockBefore.filter(
      (card) => !result.stockAfter.includes(card)
    );

    if (cardsDrawn.length === 0) {
      throw new Error('Draw did not move any cards from stock');
    }

    draws.push(cardsDrawn);
  }

  return draws;
}

async function recycleStock(page, handSize) {
  // Capture snapshots and perform recycle in one evaluation
  const result = await page.evaluate(async () => {
    const stockBefore = await window.testHooks.getStockSnapshot();
    const wasteBefore = await window.testHooks.getWasteSnapshot();
    const action = await window.testHooks.tapStock();
    await window.testHooks.waitForIdle();
    const stockAfter = await window.testHooks.getStockSnapshot();
    const wasteAfter = await window.testHooks.getWasteSnapshot();

    return {
      action,
      stockBefore,
      wasteBefore,
      stockAfter,
      wasteAfter,
    };
  });

  if (result.action !== 'recycle') {
    throw new Error(`Expected recycle action but received: ${result.action}`);
  }

  // After recycle, stock should have cards (all waste cards minus what was auto-drawn)
  expect(result.stockAfter.length).toBeGreaterThan(0);
  // Waste should have cards from the auto-draw (not empty)
  expect(result.wasteAfter.length).toBeGreaterThan(0);
  expect(result.wasteAfter.length).toBeLessThanOrEqual(handSize);
  
  // Stock + waste should equal the total we had in waste before
  expect(result.stockAfter.length + result.wasteAfter.length).toBe(result.wasteBefore.length);
}

function expectValidCycle(draws, handSize, expectedTotal) {
  const totalCards = draws.reduce((sum, cards) => {
    expect(Array.isArray(cards)).toBeTruthy();
    expect(cards.length).toBeGreaterThan(0);
    expect(cards.length).toBeLessThanOrEqual(handSize);
    return sum + cards.length;
  }, 0);

  expect(totalCards).toBe(expectedTotal);
}

test.describe('Stock cycling preserves order', () => {
  for (const mode of DRAW_MODES) {
    test(`recycles without mutation in ${mode.label} mode`, async ({ page }) => {
      await page.goto('/');
      await waitForTestHooks(page);
      await waitForIdle(page);

      await configureNewGame(page, {
        seed: mode.seed,
        modeKey: mode.modeKey,
      });

      // Capture initial waste state (from initial deal)
      const initialWaste = await page.evaluate(async () => {
        return await window.testHooks.getWasteSnapshot();
      });

      const initialStockCount = await getStockCount(page);
      expect(initialStockCount).toBe(mode.initialStock);

      const firstCycle = await drainStock(page);
      expect(firstCycle.length).toBe(mode.expectation.clicks);
      
      // drainStock only drains from stock, so it returns mode.initialStock cards
      const totalFirstCycleCards = firstCycle.reduce((sum, cards) => sum + cards.length, 0);
      expect(totalFirstCycleCards).toBe(mode.initialStock);

      const stockAfterFirstCycle = await getStockCount(page);
      expect(stockAfterFirstCycle).toBe(0);

      // After recycling, some cards will be auto-drawn to waste
      await recycleStock(page, mode.handSize);

      // Get the cards that were auto-drawn during recycle
      const wasteAfterRecycle = await page.evaluate(async () => {
        return await window.testHooks.getWasteSnapshot();
      });

      // Drain the stock again - this will do the same number of clicks as before
      const secondCycle = await drainStock(page);
      expect(secondCycle.length).toBe(mode.expectation.clicks);
      
      // Total cards in second cycle should equal total cards from first cycle (both drain just the stock)
      const totalCardsInSecondCycle = secondCycle.reduce((sum, cards) => sum + cards.length, 0);
      expect(totalCardsInSecondCycle).toBe(totalFirstCycleCards);

      // Verify order is preserved: Combine waste (auto-drawn) + second cycle draws to match initial waste + first cycle draws
      // After recycle, waste contains: initial waste cards + auto-drawn cards
      // We need to compare against: initial waste + first cycle cards
      const allSecondCycleCards = [...wasteAfterRecycle, ...secondCycle.flat()];
      const allFirstCycleCards = [...initialWaste, ...firstCycle.flat()];
      
      expect(allSecondCycleCards).toEqual(allFirstCycleCards);
    });
  }
});
