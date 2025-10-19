# Game Over Detection Debug Checklist

## Your Scenario: Waste Not Empty but Stuck

If you're in a situation where:
- ❌ You cannot make a move
- ❌ Waste is NOT empty
- ❌ Game is NOT showing "Game Over" dialog

Follow these steps to debug:

## Step 1: Verify Game State via Browser Console

Open browser DevTools (F12) and check the test hooks:

```javascript
// Check what's in the waste pile
window.testHooks.getWasteSnapshot()

// Check stock count
window.testHooks.getStockCount()

// Check if game is detected as stuck
window.testHooks.isGameStuck()

// Get full game state
window.testHooks.getDebugState()

// Get all cards
window.testHooks.validateCardIntegrity()
```

## Step 2: Check the Top Waste Card

The game only checks the **TOP card** of the waste pile. If it's blocked:

```javascript
// Get waste snapshot
const waste = await window.testHooks.getWasteSnapshot()
console.log('Waste cards:', waste)
console.log('Top waste card:', waste[waste.length - 1])
```

### Can this top card move?

1. **To any tableau column?**
   - Empty columns accept ANY card (rank 13, color doesn't matter)
   - Non-empty columns accept: rank must be one LOWER, opposite color
   - Example: Black 7 can go on Red 8

2. **To any foundation?**
   - Must be same suit as foundation AND next rank
   - Foundations start with Ace, then 2-13
   - Example: If Hearts foundation has Ace, only Hearts 2 can go there

## Step 3: Check Tableau State

The game checks if tableau cards can help with blocked waste:

```javascript
// Get tableau state
window.testHooks.getTableauState()
```

For each tableau column, check:

1. **Can the top card move to foundation?**
   - Must be face-up ✅
   - Must match foundation requirements

2. **Can it move to another tableau?**
   - Must be face-up ✅
   - Must be one rank lower than destination's top card
   - Must be opposite color

3. **Are there face-down cards?**
   - ⚠️ Face-down cards block all moves beneath them
   - Only visible after moving cards on top

## Step 4: Check Foundation State

```javascript
// Check foundation state
window.testHooks.getDebugState()  // Look for foundation cards
```

Can any foundation cards move back to tableau?

- This "undo" capability might open new moves
- Can only move if destination tableau is empty or accepts the card

## Step 5: Verify Stock/Waste Cycling

Even if waste isn't empty, verify stock status:

```javascript
window.testHooks.getStockCount()  // Should be > 0 if you can draw
```

- If stock > 0: You should be able to draw (game NOT stuck)
- If stock = 0 AND waste not empty: Can't recycle (not even one waste card)
- This is the bug condition!

## Step 6: Enable Debugging in Game Logic

Add logging to see which checks are failing:

### In `lib/logic/game_logic.dart`, modify `isGameStuck()`:

```dart
static bool isGameStuck(GameState state) {
  if (isGameWon(state)) {
    debugPrint('🎉 NOT stuck: Game is won!');
    return false;
  }

  if (canDrawCard(state, state.drawMode)) {
    debugPrint('🔄 NOT stuck: Can draw from stock');
    return false;
  }

  if (canRecycleWaste(state)) {
    debugPrint('♻️ NOT stuck: Can recycle waste');
    return false;
  }

  bool foundMove = false;

  // Check waste to tableau
  for (int i = 0; i < 7; i++) {
    if (canMoveWasteToTableau(state, i)) {
      debugPrint('📥 NOT stuck: Waste → Tableau[$i]');
      return false;
    }
  }

  // Check waste to foundation
  for (int i = 0; i < 4; i++) {
    if (canMoveWasteToFoundation(state, i)) {
      debugPrint('📥 NOT stuck: Waste → Foundation[$i]');
      return false;
    }
  }

  // Check foundation to tableau
  for (int f = 0; f < 4; f++) {
    for (int t = 0; t < 7; t++) {
      if (canMoveFoundationToTableau(state, f, t)) {
        debugPrint('📤 NOT stuck: Foundation[$f] → Tableau[$t]');
        return false;
      }
    }
  }

  // Check tableau to foundation
  for (int t = 0; t < 7; t++) {
    for (int f = 0; f < 4; f++) {
      if (canMoveTableauToFoundation(state, t, f)) {
        debugPrint('📤 NOT stuck: Tableau[$t] → Foundation[$f]');
        return false;
      }
    }
  }

  // Check tableau to tableau
  for (int from = 0; from < 7; from++) {
    if (state.tableau[from].isEmpty) continue;
    
    final sourceCards = state.tableau[from].cards;
    int sourceLength = sourceCards.length;
    
    for (int to = 0; to < 7; to++) {
      if (from == to) continue;
      
      for (int count = 1; count <= sourceLength; count++) {
        if (canMoveTableauToTableau(state, from, to, count)) {
          debugPrint('📊 NOT stuck: Tableau[$from] → Tableau[$to] ($count cards)');
          return false;
        }
      }
    }
  }

  debugPrint('❌ STUCK: No moves available!');
  debugPrint('Stock: ${state.stock.length}, Waste: ${state.waste.length}');
  debugPrint('Top waste card: ${state.waste.isNotEmpty ? state.waste.last : "EMPTY"}');
  
  return true;
}
```

## Step 7: Run Tests

After debugging, run the e2e tests:

```bash
npm run test:e2e  # or npx playwright test e2e/tests/game-over.spec.js
```

## Common Issues Found

### Issue 1: Waste Card Not Checking Properly
**Symptom:** Waste has card but game doesn't recognize it can move
**Fix:** Check `canMoveWasteToTableau()` and `canMoveWasteToFoundation()`

### Issue 2: Tableau Cards Blocked by Face-Down
**Symptom:** Can't move what looks like moveable cards
**Fix:** Check if cards are actually face-up with `card.faceUp`

### Issue 3: Foundation Undo Not Available
**Symptom:** Moving cards to foundation seems to block progress
**Fix:** Verify `canMoveFoundationToTableau()` is checking all foundations

### Issue 4: Tableau-to-Tableau Not Working
**Symptom:** Can drag cards but they don't follow Klondike rules
**Fix:** Review `canAcceptCard()` in TableauColumn model

## Quick Test

Run this in browser console to simulate your stuck scenario:

```javascript
// If you're stuck with waste not empty
const stuck = await window.testHooks.isGameStuck()
const stock = window.testHooks.getStockCount()
const waste = await window.testHooks.getWasteSnapshot()

console.log({
  isStuck: stuck,
  stockCount: stock,
  wasteCount: waste.length,
  topWasteCard: waste.length > 0 ? waste[waste.length - 1] : null,
  shouldShowDialog: stuck && !await window.testHooks.isGameWon()
})
```

If `shouldShowDialog` is `true` but dialog isn't showing, it's a UI issue.
If `shouldShowDialog` is `false` but you can't move, it's a logic issue.
