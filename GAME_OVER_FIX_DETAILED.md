# Game Over Detection Logic - FIX EXPLANATION

## The Problem You Identified

The original `isGameStuck()` implementation had a fundamental flaw:

```dart
// ❌ WRONG LOGIC (old code)
if (canDrawCard(state, state.drawMode)) return false;  // "Has stock" = not stuck
if (canRecycleWaste(state)) return false;              // "Can recycle" = not stuck
```

This is **INCORRECT** because:

1. **Having stock cards doesn't mean they're useful**
   - If all tableau columns are blocked by face-down cards
   - And all drawn cards can't go to foundation
   - Then having stock is meaningless

2. **Being able to recycle waste doesn't mean it helps**
   - If no card in the waste pile can move to tableau or foundation
   - Recycling just puts the same stuck cards back in stock
   - Then recycling is useless

## Your Specific Case

You said:
> "In my situation the waste was not empty when I reach a situation where I could not progress"

This scenario reveals the bug:

```
Old Logic: Waste not empty → "Game not stuck" ✓ (returned false immediately)
Your Experience: Can't make ANY move
Truth: Game IS stuck ✓
```

The old code checked immediate moves AFTER assuming stock/waste meant not stuck. If it got past those checks, it would declare the game stuck. But it should have **simulated** whether those stock/waste cards were actually useful.

## The Fix

The new `isGameStuck()` properly:

### 1. Checks immediate moves first

```dart
bool hasAnyMove(GameState checkState) {
  // Check all 5 move types...
  return foundAnyMove;
}

if (hasAnyMove(state)) return false;  // ✓ Correct
```

### 2. If no immediate moves and stock is empty + waste is empty

```dart
if (state.stock.isEmpty && state.waste.isEmpty) {
  return true;  // ✓ Definitely stuck
}
```

### 3. **CRITICAL FIX: If stock has cards, simulate drawing them**

```dart
if (!state.stock.isEmpty) {
  debugPrint('📊 Simulating stock cycle (${state.stock.length} cards)...');
  
  // Copy the state components we need to simulate
  final stockCardsCopy = List<Card>.from(state.stock.cards);
  final wasteCopy = List<Card>.from(state.waste);
  final tableauCopy = /* copy tableau */;
  final foundationsCopy = /* copy foundations */;
  
  // Simulate drawing through entire stock
  while (drawsToSimulate > 0 && stockCardsCopy.isNotEmpty) {
    // Draw cards
    final numToDraw = min(drawMode, stockCardsCopy.length);
    for (int i = 0; i < numToDraw; i++) {
      final card = stockCardsCopy.removeAt(0);
      card.faceUp = true;
      wasteCopy.add(card);
    }
    
    // CHECK: Can the drawn card move?
    if (wasteCopy.isNotEmpty) {
      final topWaste = wasteCopy.last;
      
      // Check waste to tableau
      for (int i = 0; i < 7; i++) {
        if (tableauCopy[i].canAcceptCard(topWaste)) {
          debugPrint('✅ Found moveable card in stock: waste → tableau[$i]');
          return false;  // ✓ Game NOT stuck
        }
      }
      
      // Check waste to foundation
      for (int i = 0; i < 4; i++) {
        if (foundationsCopy[i].canAcceptCard(topWaste)) {
          debugPrint('✅ Found moveable card in stock: waste → foundation[$i]');
          return false;  // ✓ Game NOT stuck
        }
      }
    }
    
    drawsToSimulate--;
  }
  
  // After stock exhausted, check if waste cards (which would recycle) are moveable
  if (wasteCopy.isNotEmpty) {
    for (final card in wasteCopy) {
      // Check if ANY waste card could move
      for (int i = 0; i < 7; i++) {
        if (tableauCopy[i].canAcceptCard(card)) {
          return false;  // ✓ Game NOT stuck
        }
      }
      // ... also check foundation
    }
  }
}
```

### 4. If only waste has cards (stock empty)

```dart
if (state.waste.isNotEmpty && state.stock.isEmpty) {
  // Check if ANY card in waste could move
  for (final card in state.waste) {
    for (int i = 0; i < 7; i++) {
      if (state.tableau[i].canAcceptCard(card)) {
        return false;  // Game NOT stuck
      }
    }
    // ... also check foundation
  }
}
```

### 5. If we reach here without finding a move

```dart
debugPrint('❌ STUCK: No cards from stock/waste are moveable, game is stuck');
return true;  // ✓ Game IS stuck
```

## Why This Matters

### Scenario: The User's Exact Case

**Game state:**
- Waste has several cards (including an Ace of Hearts)
- Stock has cards  
- Tableau completely filled with face-down cards
- No foundation moves available
- No tableau-to-tableau moves available

**Old logic:**
```
1. Check: Can draw from stock? YES
2. Decision: Game not stuck ✗ WRONG
3. Never checks if drawn cards are useful
4. User can keep clicking but nothing works
```

**New logic:**
```
1. Check immediate moves? NO
2. Check: Stock empty? NO → Simulate stock cycle
3. Simulate: Draw cards 1-2-3... Check each
4. For each: Can waste card move? NO
5. Continue: Draw cards 4-5-6... Check each
6. For each: Can waste card move? NO
7. ... Continue through all stock
8. Stock exhausted, check waste recycle? Can any waste card move? NO
9. Decision: Game IS stuck ✓ CORRECT
10. Show "Game Over" dialog
```

## Testing the Fix

The simulation ensures that:

✅ Drawing is only considered viable if drawn cards can move somewhere
✅ Recycling is only considered viable if recycled waste cards can move somewhere
✅ Waste non-empty is not treated as "game not stuck"
✅ The entire possible card sequence is evaluated before declaring stuck

## Debug Output

When the game checks stuck state, you'll see:
```
📊 Simulating stock cycle (N cards)...
✅ Found moveable card in stock: waste → tableau[2]
```
Or:
```
📊 Simulating stock cycle (N cards)...
📊 Stock exhausted, checking waste recycle cycle...
❌ STUCK: No cards from stock/waste are moveable, game is stuck
```
