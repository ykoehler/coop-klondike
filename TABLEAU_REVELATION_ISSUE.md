# Tableau Card Revelation Issue

## The Problem

When checking if the game is stuck, we verify:
1. ✅ Can waste card move?
2. ✅ Can tableau card move to foundation?
3. ✅ Can tableau card move to another tableau?

BUT we DON'T verify the crucial detail:
❌ **When a tableau card moves, does it reveal a face-down card that enables NEW moves?**

## Critical Scenario

```
Tableau Column 1:          Tableau Column 2:
[5♠ face-up]               [6♥ face-up]
[4♣ face-down] ← KEY!      [3♦ face-up]

Waste: [7♦ face-up]
```

What happens:

**Move 1:** Move 5♠ to 6♥ (tableau-to-tableau)
- This is VALID (5 is one rank below 6, opposite color)
- After move, 4♣ gets flipped face-up ✅

**Move 2:** Now 4♣ is revealed face-up, and 3♦ is at bottom
- 4♣ can move to 5♠ (which is now in Column 2)
- OR 7♦ (from waste) can move to 8 of opposite color (if available)

**The Issue:**
When checking `isGameStuck()`, if we only check:
- "Can waste move? NO (7♦ doesn't fit anywhere)"
- "Can tableau cards move? MAYBE (depends on face-down cards)"

We might NOT recognize that:
- Moving one card reveals a face-down card
- Which enables the waste card to move
- So game is NOT stuck

## How This Breaks

Current logic in `isGameStuck()`:

```dart
bool hasAnyMove(GameState checkState) {
  // Check if waste card can move
  for (int i = 0; i < 7; i++) {
    if (canMoveWasteToTableau(checkState, i)) return true;  // ← Only checks current state
  }
  
  // Check if tableau to tableau...
  for (int from = 0; from < 7; from++) {
    for (int to = 0; to < 7; to++) {
      // ← Checks if move is valid
      if (canMoveTableauToTableau(checkState, from, to, count)) return true;
    }
  }
}
```

**Missing:** After each potential tableau-to-tableau move, check if it REVEALS a card that enables new moves.

## The Real Question

Should we:

**Option A:** Only check surface-level moves (fast but might miss valid progressions)

**Option B:** After each tableau-to-tableau move, simulate the revelation and check if new moves appear (slower but more accurate)

For **accurate stuck detection**, we need **Option B**.

## Current Code Flow

1. `moveTableauToTableau()` does call `_flipTableauTopCard()`
2. But in `isGameStuck()` simulation, we copy the cards and don't properly simulate the revelation effect on subsequent move checks

The issue is that the simulation copies state but doesn't recursively check if revealed cards enable new moves.
