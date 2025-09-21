import { test, expect } from '@playwright/test';

test('Game flow with deterministic state - win or detect stuck', async ({ page }) => {
  // Navigate to the app with a specific seed for deterministic game state
  await page.goto('http://localhost:8080?seed=12345');

  // Wait for the game to load
  await page.waitForSelector('.game-board', { timeout: 10000 });

  // Verify game is loaded
  await expect(page.locator('.game-board')).toBeVisible();

  let moves = 0;
  const maxMoves = 200; // Prevent infinite loops
  let gameWon = false;
  let gameStuck = false;

  while (moves < maxMoves && !gameWon && !gameStuck) {
    // Check if game is won
    const winMessage = page.locator('text=/You Win|Congratulations|Victory/i');
    if (await winMessage.isVisible()) {
      gameWon = true;
      break;
    }

    // Check if game is stuck (look for stuck message or no valid moves)
    const stuckMessage = page.locator('text=/Game Over|Stuck|No More Moves/i');
    if (await stuckMessage.isVisible()) {
      gameStuck = true;
      break;
    }

    // Find all draggable cards
    const cards = page.locator('[data-card]').filter({ hasText: /.+/ });

    // Try to find a valid move
    let moveMade = false;

    for (const card of await cards.all()) {
      // Get card info
      const cardText = await card.textContent();
      const cardRect = await card.boundingClientRect();

      // Try to drag to foundation piles (hearts, diamonds, clubs, spades positions)
      const foundations = [
        page.locator('.foundation-0'),
        page.locator('.foundation-1'),
        page.locator('.foundation-2'),
        page.locator('.foundation-3')
      ];

      for (const foundation of foundations) {
        try {
          await card.dragTo(foundation, { timeout: 1000 });
          moveMade = true;
          break;
        } catch (e) {
          // Drag failed, try next
        }
      }

      if (moveMade) break;

      // Try to drag to tableau columns
      const tableaus = [
        page.locator('.tableau-0'),
        page.locator('.tableau-1'),
        page.locator('.tableau-2'),
        page.locator('.tableau-3'),
        page.locator('.tableau-4'),
        page.locator('.tableau-5'),
        page.locator('.tableau-6')
      ];

      for (const tableau of tableaus) {
        try {
          await card.dragTo(tableau, { timeout: 1000 });
          moveMade = true;
          break;
        } catch (e) {
          // Drag failed, try next
        }
      }

      if (moveMade) break;
    }

    // If no move was made, try clicking the stock pile to draw cards
    if (!moveMade) {
      const stockPile = page.locator('.stock-pile');
      if (await stockPile.isVisible()) {
        await stockPile.click();
        moveMade = true;
      }
    }

    // If still no move, check if waste pile has cards to move
    if (!moveMade) {
      const wasteCards = page.locator('.waste-pile [data-card]');
      if (await wasteCards.count() > 0) {
        const wasteCard = wasteCards.first();
        // Try to move waste card to foundations or tableaus
        const foundations = [
          page.locator('.foundation-0'),
          page.locator('.foundation-1'),
          page.locator('.foundation-2'),
          page.locator('.foundation-3')
        ];

        for (const foundation of foundations) {
          try {
            await wasteCard.dragTo(foundation, { timeout: 1000 });
            moveMade = true;
            break;
          } catch (e) {
            // Continue
          }
        }

        if (!moveMade) {
          const tableaus = [
            page.locator('.tableau-0'),
            page.locator('.tableau-1'),
            page.locator('.tableau-2'),
            page.locator('.tableau-3'),
            page.locator('.tableau-4'),
            page.locator('.tableau-5'),
            page.locator('.tableau-6')
          ];

          for (const tableau of tableaus) {
            try {
              await wasteCard.dragTo(tableau, { timeout: 1000 });
              moveMade = true;
              break;
            } catch (e) {
              // Continue
            }
          }
        }
      }
    }

    if (!moveMade) {
      // No moves possible, game might be stuck
      gameStuck = true;
    }

    moves++;
    // Small delay to allow UI updates
    await page.waitForTimeout(100);
  }

  // Verify the outcome
  if (gameWon) {
    await expect(page.locator('text=/You Win|Congratulations|Victory/i')).toBeVisible();
    console.log(`Game won in ${moves} moves`);
  } else if (gameStuck) {
    // Verify stuck detection is working
    await expect(page.locator('text=/Game Over|Stuck|No More Moves/i')).toBeVisible();
    console.log(`Game stuck after ${moves} moves`);
  } else {
    // Should not reach here
    throw new Error('Game neither won nor stuck within max moves');
  }
});