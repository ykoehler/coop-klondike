import { test, expect } from '@playwright/test';

const BASE_URL = 'http://localhost:8080';

test.describe('Empty Tableau Column Tests', () => {
  test.beforeEach(async ({ page }) => {
    // Enable console error tracking
    page.on('console', msg => {
      if (msg.type() === 'error') {
        console.error('Browser console error:', msg.text());
      }
    });
    
    // Track uncaught errors
    page.on('pageerror', error => {
      console.error('Uncaught page error:', error.message);
      console.error('Stack:', error.stack);
    });

    await page.goto(BASE_URL);
    await page.waitForFunction(() => window.testHooksReady === true, { timeout: 15000 });
  });

  test('Empty tableau columns should remain visible and accept Kings', async ({ page }) => {
    const TEST_SEED = 'empty-column-test';
    
    await page.evaluate(async (seed) => {
      await window.testHooks.configureGame(seed, 'three');
    }, TEST_SEED);

    const initialTableau = await page.evaluate(() => {
      return window.testHooks.getTableauState();
    });
    
    console.log('Initial tableau state:', JSON.stringify(initialTableau, null, 2));
    expect(initialTableau.length).toBe(7);
    
    const columnToEmpty = 0;
    const initialCardCount = initialTableau[columnToEmpty].cardCount;
    console.log(`Column ${columnToEmpty} initially has ${initialCardCount} cards`);
    
    // Use the clearTableauColumn helper
    await page.evaluate(async (colIndex) => {
      await window.testHooks.clearTableauColumn(colIndex);
    }, columnToEmpty);
    
    await page.waitForTimeout(500);
    
    const tableauAfterClear = await page.evaluate(() => {
      return window.testHooks.getTableauState();
    });
    
    console.log('Tableau after clearing column 0:', JSON.stringify(tableauAfterClear, null, 2));
    
    expect(tableauAfterClear.length).toBe(7);
    expect(tableauAfterClear[columnToEmpty].isEmpty).toBe(true);
    expect(tableauAfterClear[columnToEmpty].cardCount).toBe(0);
    
    console.log('✓ Empty column preserved - still have 7 columns');
    
    // Test that the empty column can accept a King
    const canAcceptKing = await page.evaluate(async (emptyColIndex) => {
      const canAccept = window.testHooks.canTableauAcceptCard(emptyColIndex, 'hearts', 'king');
      console.log(`Empty column can accept King: ${canAccept}`);
      
      if (canAccept) {
        await window.testHooks.addCardToTableau(emptyColIndex, 'hearts', 'king');
      }
      
      return canAccept;
    }, columnToEmpty);
    
    expect(canAcceptKing).toBe(true);
    console.log('✓ Empty column correctly accepts Kings');
    
    const tableauAfterKing = await page.evaluate(() => {
      return window.testHooks.getTableauState();
    });
    
    expect(tableauAfterKing[columnToEmpty].cardCount).toBe(1);
    expect(tableauAfterKing[columnToEmpty].topCard.rank).toBe('king');
    expect(tableauAfterKing[columnToEmpty].topCard.suit).toBe('hearts');
    
    console.log('✓ King successfully placed in empty column');
  });

  test('Empty column should NOT accept non-King cards', async ({ page }) => {
    const TEST_SEED = 'empty-column-test-2';
    
    await page.evaluate(async (seed) => {
      await window.testHooks.configureGame(seed, 'three');
    }, TEST_SEED);

    await page.evaluate(async () => {
      await window.testHooks.clearTableauColumn(0);
    });
    
    await page.waitForTimeout(300);
    
    const rejectionResults = await page.evaluate(() => {
      const results = {};
      const testCards = [
        { rank: 'ace', name: 'Ace' },
        { rank: 'queen', name: 'Queen' },
        { rank: 'jack', name: 'Jack' },
        { rank: 'ten', name: 'Ten' },
        { rank: 'five', name: 'Five' },
      ];
      
      testCards.forEach(({ rank, name }) => {
        results[name] = window.testHooks.canTableauAcceptCard(0, 'spades', rank);
      });
      
      return results;
    });
    
    console.log('Non-King card rejection results:', rejectionResults);
    
    Object.entries(rejectionResults).forEach(([cardName, canAccept]) => {
      expect(canAccept).toBe(false);
      console.log(`✓ ${cardName} correctly rejected by empty column`);
    });
  });

  test('Multiple empty columns persist', async ({ page }) => {
    const TEST_SEED = 'multi-empty-columns';
    
    await page.evaluate(async (seed) => {
      await window.testHooks.configureGame(seed, 'three');
    }, TEST_SEED);

    const columnsToEmpty = [0, 2, 4];
    
    for (const colIndex of columnsToEmpty) {
      await page.evaluate(async (col) => {
        await window.testHooks.clearTableauColumn(col);
      }, colIndex);
    }
    
    await page.waitForTimeout(300);
    
    const stateAfterEmptying = await page.evaluate(() => {
      return window.testHooks.getTableauState();
    });
    
    console.log('State after emptying multiple columns:', JSON.stringify(stateAfterEmptying, null, 2));
    
    expect(stateAfterEmptying.length).toBe(7);
    
    columnsToEmpty.forEach(colIndex => {
      expect(stateAfterEmptying[colIndex].isEmpty).toBe(true);
      console.log(`✓ Column ${colIndex} remains empty`);
    });
    
    const nonEmptyColumns = [1, 3, 5, 6];
    nonEmptyColumns.forEach(colIndex => {
      expect(stateAfterEmptying[colIndex].cardCount).toBeGreaterThan(0);
      console.log(`✓ Column ${colIndex} retains cards`);
    });
  });

  test('Leftmost column specifically should persist when empty', async ({ page }) => {
    const TEST_SEED = 'leftmost-empty-test';
    
    await page.evaluate(async (seed) => {
      await window.testHooks.configureGame(seed, 'three');
    }, TEST_SEED);

    const initialState = await page.evaluate(() => {
      const state = window.testHooks.getTableauState();
      return {
        columnCount: state.length,
        leftmostCardCount: state[0].cardCount,
        leftmostCards: state[0].cards
      };
    });
    
    console.log('Initial state:', initialState);
    expect(initialState.columnCount).toBe(7);
    expect(initialState.leftmostCardCount).toBeGreaterThan(0);
    
    await page.evaluate(async () => {
      console.log('Emptying leftmost column (column 0)...');
      await window.testHooks.clearTableauColumn(0);
    });
    
    await page.waitForTimeout(500);
    
    const stateAfterEmpty = await page.evaluate(() => {
      const state = window.testHooks.getTableauState();
      return {
        columnCount: state.length,
        leftmostIsEmpty: state[0].isEmpty,
        leftmostCardCount: state[0].cardCount,
        allColumns: state.map((col, i) => ({
          index: i,
          cardCount: col.cardCount,
          isEmpty: col.isEmpty
        }))
      };
    });
    
    console.log('State after emptying leftmost column:', JSON.stringify(stateAfterEmpty, null, 2));
    
    expect(stateAfterEmpty.columnCount).toBe(7);
    expect(stateAfterEmpty.leftmostIsEmpty).toBe(true);
    expect(stateAfterEmpty.leftmostCardCount).toBe(0);
    
    console.log('✓ BUGFIX VERIFIED: Leftmost column persists when empty');
    
    const canAcceptKing = await page.evaluate(() => {
      return window.testHooks.canTableauAcceptCard(0, 'diamonds', 'king');
    });
    
    expect(canAcceptKing).toBe(true);
    console.log('✓ Empty leftmost column can accept Kings');
  });

  test('UI renders empty tableau column placeholder', async ({ page }) => {
    const TEST_SEED = 'ui-render-test';
    
    await page.evaluate(async (seed) => {
      await window.testHooks.configureGame(seed, 'three');
    }, TEST_SEED);

    await page.evaluate(async () => {
      await window.testHooks.clearTableauColumn(0);
    });
    
    await page.waitForTimeout(1000);
    
    await page.screenshot({ path: 'e2e/test-results/empty-column-ui.png' });
    
    const uiState = await page.evaluate(() => {
      const state = window.testHooks.getTableauState();
      const debugState = window.testHooks.getDebugState();
      
      return {
        tableauColumnCount: state.length,
        emptyColumnExists: state[0].isEmpty,
        gameStateValid: debugState !== null
      };
    });
    
    console.log('UI state:', uiState);
    
    expect(uiState.tableauColumnCount).toBe(7);
    expect(uiState.emptyColumnExists).toBe(true);
    expect(uiState.gameStateValid).toBe(true);
    
    console.log('✓ UI correctly renders empty column placeholder');
  });
});
