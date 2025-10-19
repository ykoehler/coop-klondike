# Game Over Verification Logic - CORRECTED

## Overview

The game checks if it's "stuck" (game over) by verifying that NO legal moves are possible, INCLUDING the ability to draw from stock or waste. The crucial fix: **Having stock or waste cards does NOT guarantee the game is playable** - we must simulate if any of those cards could actually be moved.

## Verification Checks (CORRECTED ORDER)

### 1. Game Won Check

- If all 4 foundations are complete with 13 cards each, game is NOT stuck (it's won)
- This prevents false "game over" when player has actually won

### 2. Immediate Moves Check

Check if ANY move is immediately available:

- ✅ Waste card to any tableau column (7 checks)
- ✅ Waste card to any foundation pile (4 checks)
- ✅ Any foundation card back to tableau (undo moves, 4×7 checks)
- ✅ Any tableau card to foundation (7×4 checks)
- ✅ Any tableau sequence to another tableau (7×7×N checks)

If ANY of these moves exist, the game is NOT stuck.

### 3. Stock/Waste Cycle Simulation (THE FIX)

**CRITICAL:** If no immediate moves but stock/waste has cards, we must SIMULATE drawing through them:

**If stock has cards:**

- Simulate drawing `drawMode` cards (1 or 3) from stock
- For each card drawn, check if it can move to tableau or foundation
- If ANY simulated waste card is moveable, game is NOT stuck
- Check the entire stock cycle (all remaining cards)
- After stock exhausted, also check if cards in waste (after being recycled) could move

**If only waste has cards (stock empty):**

- Check if ANY card currently in waste can move to tableau or foundation
- Even if only the top card is currently accessible, if it can't move, game IS stuck

### 4. Return Result

If both stock and waste are completely empty AND no moves available → **STUCK**

If ANY card from stock cycle or waste can move → **NOT STUCK**

## What Changed

| Old Logic | New Logic |
|-----------|-----------|
| ❌ "Stock not empty" = game not stuck | ✅ Must simulate: could ANY stock card move? |
| ❌ "Can recycle waste" = game not stuck | ✅ Must check: do those waste cards move anywhere? |
| ✅ Check immediate moves | ✅ Still check, but FIRST |
| ❌ Only check top waste card | ✅ Check ALL waste cards (any could appear via recycle) |

## Example Scenarios

### Scenario 1: Stock has cards, waste has top card that can't move

Old logic: "Game not stuck" (FALSE)
New logic: Simulates drawing all stock → checks if ANY waste card is moveable → accurate

### Scenario 2: All tableau is blocked by face-down cards, stock has cards

Old logic: "Game not stuck" (FALSE)
New logic: Simulates drawing → checks if drawn cards help (they won't if tableau blocked) → accurate

### Scenario 3: Waste not empty, but top card can't move, no other moves

Old logic: Might say "not stuck" if stock exists (FALSE)
New logic: Simulates stock/checks waste → determines if ANY card helps → accurate

## Summary Table

| Check | Condition | Requires | Notes |
|-------|-----------|----------|-------|
| 1 | Game Won | 52 cards in foundations (13 each) | No game over if won |
| 2 | Draw from stock | Stock not empty | Any draw mode |
| 3 | Recycle waste | Stock empty + waste not empty | Can recycle at most once per cycle |
| 4 | Waste → Tableau | Top waste card + valid tableau | 7 possible destinations |
| 5 | Waste → Foundation | Top waste card + valid foundation | 4 possible destinations |
| 6 | Foundation → Tableau | Top foundation card + valid tableau | Allows undo moves |
| 7 | Tableau → Foundation | Top face-up tableau card | 4 × 7 = 28 possible combinations |
| 8 | Tableau → Tableau | Any face-up sequence | 7 × 7 × N possible combinations |

## Key Points About Your Situation

If you **cannot progress and waste is NOT empty**, the game should be checking:

1. ✅ Can the waste card move to any tableau column?
2. ✅ Can the waste card move to any foundation pile?
3. ✅ Can any tableau cards move to the waste's destination?
4. ✅ Can any foundation cards move to open up blocked tableau cards?
5. ✅ Can any tableau cards move to other tableau columns?

If **all of these return false**, then the game is correctly stuck.

**Possible Issues to Debug:**
- [ ] Is the waste card being checked correctly (is it the actual top card)?
- [ ] Are the tableau validation rules working correctly?
- [ ] Are face-down cards blocking moves that should be available?
- [ ] Is there a bug in the `canAcceptCard()` logic for tableau or foundation?

## Testing

Run the e2e test to verify game over detection:
```bash
npx playwright test e2e/tests/game-over.spec.js
```

The test `'Game over when stock is empty AND waste is empty'` specifically tests the scenario where both are empty and no moves are available.
