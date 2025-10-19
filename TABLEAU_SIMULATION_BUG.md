# Tableau Simulation Deep Copy Bug - FIXED

## The Problem You Identified

When checking if the game is stuck, we simulate drawing cards from stock. During this simulation, we copy the tableau, foundations, and waste. However, the copy was **SHALLOW**, meaning:

```dart
// OLD CODE (Shallow copy)
columnCopy.cards = List<Card>.from(col.cards);  // ← Copies list, but cards are same references!

// Later modification
card.faceUp = true;  // ← Modifies the ORIGINAL card object!
```

This could potentially affect:
1. The original card's face-up state
2. Subsequent checks on the original tableau

Additionally, when checking tableau moves, we must verify:
✅ TOP card of moving sequence is face-up (can't move face-down sequences)
✅ When cards move, face-down cards beneath get revealed (automatic via `_flipTableauTopCard()`)
✅ Tableau-to-tableau moves follow stacking rules

## The Fix

Now using **DEEP copies** of cards:

```dart
// NEW CODE (Deep copy)
columnCopy.cards = col.cards.map((card) {
  final cardCopy = Card(suit: card.suit, rank: card.rank);  // ← New Card object
  cardCopy.faceUp = card.faceUp;  // ← Copy state
  return cardCopy;
}).toList();

// Same for foundations:
pileCopy.cards = pile.cards.map((card) {
  final cardCopy = Card(suit: card.suit, rank: card.rank);  // ← New Card object
  cardCopy.faceUp = card.faceUp;  // ← Copy state
  return cardCopy;
}).toList();
```

Now modifying simulated cards doesn't affect the original state.

## What This Ensures

1. ✅ Simulation doesn't corrupt original game state
2. ✅ Face-down card simulation is independent
3. ✅ Stock cycle simulation is accurate
4. ✅ Tableau-to-tableau checks properly account for card revelation

## Tableau-to-Tableau Move Verification

The `canMoveTableauToTableau()` method correctly:

1. **Checks top card is face-up**
   ```dart
   final topMovingCard = movingCards.first;
   if (!topMovingCard.faceUp) return false;  // Can't move face-down sequences
   ```

2. **Validates stacking rules**
   ```dart
   return state.tableau[toIndex].canAcceptCard(topMovingCard);  // Checks color and rank
   ```

3. **Movement automatically reveals cards**
   ```dart
   // In moveTableauToTableau():
   _flipTableauTopCard(state, fromIndex);  // ← Flips any face-down top card after removal
   ```

So when checking `isGameStuck()`:
- If we find a valid tableau-to-tableau move, we return NOT stuck
- That move WILL reveal face-down cards  
- Game progression IS possible

## Test Coverage

The fix ensures:
✅ Stock cycle simulation doesn't corrupt state
✅ Deep copied cards can be safely modified during simulation
✅ Tableau-to-tableau moves properly account for card revelation
✅ Game over detection is accurate

