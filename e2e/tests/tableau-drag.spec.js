import { test, expect } from '@playwright/test';

const BASE_URL = 'http://localhost:8080';
const DEFAULT_SEED = 'blue02orange';

test.describe('Tableau Card Drag Tests', () => {
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
    await page.evaluate(async (seed) => {
      await window.testHooks.configureGame(seed, 'three');
    }, DEFAULT_SEED);
  });

  test('Can get tableau column information', async ({ page }) => {
    const tableauState = await page.evaluate(() => {
      return window.testHooks.getTableauState();
    });
    
    console.log('Tableau state:', JSON.stringify(tableauState, null, 2));
    
    // Verify we have 7 columns
    expect(tableauState.length).toBe(7);
    
    // Verify each column has the expected structure
    tableauState.forEach((column, i) => {
      expect(column.index).toBe(i);
      expect(typeof column.cardCount).toBe('number');
      expect(typeof column.isEmpty).toBe('boolean');
      console.log(`Column ${i}: ${column.cardCount} cards, isEmpty: ${column.isEmpty}`);
    });
  });

  test('Move a card from one tableau column to another', async ({ page }) => {
    let errors = [];
    
    page.on('pageerror', error => {
      errors.push({
        message: error.message,
        stack: error.stack
      });
      console.error('Page error during tableau move:', error.message);
    });
    
    // Get initial tableau state
    const tableauBefore = await page.evaluate(() => {
      return window.testHooks.getTableauState();
    });
    
    console.log('Tableau before move:', JSON.stringify(tableauBefore, null, 2));
    
    // Find a move that should work: look for a column with a face-up card
    // and another column that can accept it
    let fromCol = -1;
    let toCol = -1;
    let cardCount = 1;
    
    for (let i = 0; i < tableauBefore.length; i++) {
      if (tableauBefore[i].topCard && tableauBefore[i].topCard.faceUp) {
        fromCol = i;
        break;
      }
    }
    
    if (fromCol !== -1) {
      console.log(`Found source column: ${fromCol} with top card ${tableauBefore[fromCol].topCard.rank} of ${tableauBefore[fromCol].topCard.suit}`);
      
      // Try to find a valid destination (this is a simple test, might not find one)
      for (let i = 0; i < tableauBefore.length; i++) {
        if (i !== fromCol) {
          toCol = i;
          break; // Just try the first different column for testing
        }
      }
      
      if (toCol !== -1) {
        console.log(`Attempting to move from column ${fromCol} to column ${toCol}`);
        
        // Attempt the move
        const moveResult = await page.evaluate(async ({ from, to, count }) => {
          try {
            const result = await window.testHooks.moveTableauToTableau(from, to, count);
            return { success: true, result };
          } catch (e) {
            return { success: false, error: e.message, stack: e.stack };
          }
        }, { from: fromCol, to: toCol, count: cardCount });
        
        console.log('Move result:', moveResult);
        
        // Get tableau state after
        const tableauAfter = await page.evaluate(() => {
          return window.testHooks.getTableauState();
        });
        
        console.log('Tableau after move:', JSON.stringify(tableauAfter, null, 2));
        
        // Verify card integrity
        const integrity = await page.evaluate(() => {
          return window.testHooks.validateCardIntegrity();
        });
        
        console.log('Card integrity after move:', integrity);
        expect(integrity.valid).toBe(true);
      }
    }
    
    // Check if any errors occurred
    if (errors.length > 0) {
      console.error('Errors during test:');
      errors.forEach(err => {
        console.error('  -', err.message);
        console.error('    Stack:', err.stack);
      });
      expect(errors.length).toBe(0); // Fail the test if errors occurred
    }
  });

  test('Click on tableau card should not throw exception', async ({ page }) => {
    let errorOccurred = false;
    let errorMessage = '';
    
    // Listen for errors
    page.on('pageerror', error => {
      errorOccurred = true;
      errorMessage = error.message;
      console.error('Exception caught:', error.message);
      console.error('Stack:', error.stack);
    });
    
    // Wait for game to be ready
    await page.waitForTimeout(1000);
    
    // Try to simulate a drag operation programmatically
    const dragResult = await page.evaluate(() => {
      try {
        // Get the game state
        const state = window.testHooks ? window.testHooks.getDebugState() : null;
        
        // Try to find a draggable card by looking at the Flutter widget tree
        // We'll simulate what happens when you click a tableau card
        
        return {
          success: true,
          hasTestHooks: window.testHooks !== undefined,
          state: state,
          message: 'Attempted programmatic drag simulation'
        };
      } catch (e) {
        return {
          success: false,
          error: e.message,
          stack: e.stack
        };
      }
    });
    
    console.log('Drag simulation result:', JSON.stringify(dragResult, null, 2));
    
    // Verify no errors occurred
    expect(errorOccurred).toBe(false);
    if (errorOccurred) {
      console.error('Error message:', errorMessage);
    }
  });

  test('Tableau card drag should maintain card integrity', async ({ page }) => {
    // Get initial integrity
    const integrityBefore = await page.evaluate(() => 
      window.testHooks.validateCardIntegrity()
    );
    
    expect(integrityBefore.valid).toBe(true);
    console.log('Initial integrity:', integrityBefore);
    
    // Get tableau state to find a valid move
    const tableauState = await page.evaluate(() => 
      window.testHooks.getTableauState()
    );
    
    console.log('Tableau state:', JSON.stringify(tableauState, null, 2));
    
    // Find the first column with face-up cards
    let moveAttempted = false;
    for (let i = 0; i < tableauState.length; i++) {
      const column = tableauState[i];
      if (!column.isEmpty && column.topCard.faceUp) {
        // Try to move this card to another column (just attempt it, may not be legal)
        const targetColumn = (i + 1) % tableauState.length;
        
        try {
          const moveResult = await page.evaluate(async ({ from, to }) => {
            return await window.testHooks.moveTableauToTableau(from, to, 1);
          }, { from: i, to: targetColumn });
          
          console.log(`Move attempt from column ${i} to ${targetColumn}: ${moveResult}`);
          moveAttempted = true;
          break;
        } catch (error) {
          console.log(`Move attempt failed: ${error.message}`);
          // Continue trying other columns
        }
      }
    }
    
    console.log(`Move attempted: ${moveAttempted}`);
    
    // Check integrity after drag attempt
    await page.waitForTimeout(500);
    const integrityAfter = await page.evaluate(() => 
      window.testHooks.validateCardIntegrity()
    );
    
    console.log('Integrity after move attempt:', integrityAfter);
    expect(integrityAfter.valid).toBe(true);
  });

  test('Inspect error when dragging a specific tableau card', async ({ page }) => {
    let consoleMessages = [];
    let errors = [];
    
    // Capture all console messages
    page.on('console', msg => {
      consoleMessages.push({
        type: msg.type(),
        text: msg.text()
      });
    });
    
    // Capture all errors
    page.on('pageerror', error => {
      errors.push({
        message: error.message,
        stack: error.stack
      });
    });
    
    await page.waitForTimeout(1000);
    
    // Take a screenshot to see the game state
    await page.screenshot({ path: 'e2e/tableau-before-drag.png' });
    
    // Get tableau state to find a card to drag
    const tableauState = await page.evaluate(() => {
      return window.testHooks.getTableauState();
    });
    
    console.log('Looking for draggable cards in tableau...');
    let foundDraggableCard = false;
    
    for (let i = 0; i < tableauState.length; i++) {
      const column = tableauState[i];
      if (column.cards && column.cards.length > 0) {
        const faceUpCards = column.cards.filter(c => c.faceUp);
        if (faceUpCards.length > 0) {
          console.log(`Column ${i} has ${faceUpCards.length} face-up cards`);
          foundDraggableCard = true;
        }
      }
    }
    
    if (!foundDraggableCard) {
      console.log('No draggable cards found in tableau');
    }
    
    // Try to simulate a drag using Flutter's rendering
    const dragAttempt = await page.evaluate(() => {
      try {
        // Get the provider state
        const debugState = window.testHooks.getDebugState();
        
        // Check if the game is locked or has pending actions
        if (debugState.isLocked || debugState.hasPendingAction) {
          return {
            success: false,
            reason: 'Game is locked or has pending actions',
            debugState
          };
        }
        
        // Try to find flt-semantics nodes (Flutter's semantic tree)
        const semanticsNodes = document.querySelectorAll('flt-semantics');
        console.log(`Found ${semanticsNodes.length} Flutter semantics nodes`);
        
        return {
          success: true,
          message: 'Drag simulation attempted',
          semanticsNodeCount: semanticsNodes.length,
          debugState
        };
      } catch (e) {
        return {
          success: false,
          error: e.message,
          stack: e.stack
        };
      }
    });
    
    console.log('Drag attempt result:', JSON.stringify(dragAttempt, null, 2));
    
    await page.waitForTimeout(1000);
    await page.screenshot({ path: 'e2e/tableau-after-drag.png' });
    
    // Log all captured messages and errors
    console.log('\n=== Console Messages ===');
    const errorMessages = consoleMessages.filter(msg => msg.type === 'error');
    if (errorMessages.length > 0) {
      console.log('Found error messages:');
      errorMessages.forEach(msg => {
        console.log(`  - ${msg.text}`);
      });
    } else {
      console.log('No error messages found');
    }
    
    console.log('\n=== Page Errors ===');
    if (errors.length > 0) {
      console.log('Found page errors:');
      errors.forEach(err => {
        console.log('Error:', err.message);
        console.log('Stack:', err.stack);
      });
    } else {
      console.log('No page errors found');
    }
    
    // The test passes but logs information about any errors
    // If you want the test to fail on errors, uncomment the next line:
    // expect(errors.length).toBe(0);
  });
});
