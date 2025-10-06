import '../models/game_state.dart';
import '../models/card.dart';
import 'package:flutter/foundation.dart';

class GameLogic {
  // Draw card from stock to waste
  static bool canDrawCard(GameState state, DrawMode mode) {
    return !state.stock.isEmpty;
  }

  static void drawCard(GameState state, DrawMode mode) {
    if (!canDrawCard(state, mode)) return;
    
    final stockBefore = state.stock.length;
    final wasteBefore = state.waste.length;
    
    int numToDraw = mode == DrawMode.one ? 1 : (state.stock.length < 3 ? state.stock.length : 3);
    debugPrint('  📥 LOGIC drawCard: Drawing $numToDraw cards from stock (stock=$stockBefore, waste=$wasteBefore)');
    
    for (int i = 0; i < numToDraw; i++) {
      final card = state.stock.drawCard();
      if (card != null) {
        debugPrint('    → Drew ${card.rank.name}-${card.suit.name}');
        card.faceUp = true;
        state.waste.add(card);
      } else {
        debugPrint('    ⚠️ WARNING: drawCard returned null!');
      }
    }
    
    debugPrint('  📥 LOGIC drawCard: Complete (stock=${state.stock.length}, waste=${state.waste.length})');
    
    // Log stock operation for debugging
    _logStockOperation(state, 'draw', numToDraw);
  }

  // Move from waste to tableau
  static bool canMoveWasteToTableau(GameState state, int tableauIndex) {
    if (state.waste.isEmpty) return false;
    final card = state.waste.last;
    return state.tableau[tableauIndex].canAcceptCard(card);
  }

  static void moveWasteToTableau(GameState state, int tableauIndex) {
    if (canMoveWasteToTableau(state, tableauIndex)) {
      final card = state.waste.removeLast();
      state.tableau[tableauIndex].addCard(card);
      _flipTableauTopCard(state, tableauIndex);
    }
  }

  // Move from waste to foundation
  static bool canMoveWasteToFoundation(GameState state, int foundationIndex) {
    if (state.waste.isEmpty) return false;
    final card = state.waste.last;
    return state.foundations[foundationIndex].canAcceptCard(card);
  }

  static void moveWasteToFoundation(GameState state, int foundationIndex) {
    if (canMoveWasteToFoundation(state, foundationIndex)) {
      final card = state.waste.removeLast();
      state.foundations[foundationIndex].addCard(card);
    }
  }

  // Move from tableau to tableau
  static bool canMoveTableauToTableau(GameState state, int fromIndex, int toIndex, int cardCount) {
    if (fromIndex == toIndex || cardCount < 1) return false;
    final fromColumn = state.tableau[fromIndex];
    if (fromColumn.cards.length < cardCount) return false;

    final movingCards = fromColumn.cards.sublist(fromColumn.cards.length - cardCount);
    final topMovingCard = movingCards.first;
    if (!topMovingCard.faceUp) return false; // Can't move face-down cards

    return state.tableau[toIndex].canAcceptCard(topMovingCard);
  }

  static void moveTableauToTableau(GameState state, int fromIndex, int toIndex, int cardCount) {
    if (canMoveTableauToTableau(state, fromIndex, toIndex, cardCount)) {
      final fromColumn = state.tableau[fromIndex];
      final movingCards = fromColumn.cards.sublist(fromColumn.cards.length - cardCount);
      fromColumn.cards.removeRange(fromColumn.cards.length - cardCount, fromColumn.cards.length);
      state.tableau[toIndex].cards.addAll(movingCards);
      _flipTableauTopCard(state, fromIndex);
    }
  }

  // Move from tableau to foundation
  static bool canMoveTableauToFoundation(GameState state, int tableauIndex, int foundationIndex) {
    final column = state.tableau[tableauIndex];
    if (column.isEmpty) return false;
    final card = column.topCard!;
    if (!card.faceUp) return false;
    return state.foundations[foundationIndex].canAcceptCard(card);
  }

  static void moveTableauToFoundation(GameState state, int tableauIndex, int foundationIndex) {
    if (canMoveTableauToFoundation(state, tableauIndex, foundationIndex)) {
      final card = state.tableau[tableauIndex].removeCard()!;
      state.foundations[foundationIndex].addCard(card);
      _flipTableauTopCard(state, tableauIndex);
    }
  }

  // Move from foundation to tableau (rare, but possible)
  static bool canMoveFoundationToTableau(GameState state, int foundationIndex, int tableauIndex) {
    final pile = state.foundations[foundationIndex];
    if (pile.isEmpty) return false;
    final card = pile.topCard!;
    return state.tableau[tableauIndex].canAcceptCard(card);
  }

  static void moveFoundationToTableau(GameState state, int foundationIndex, int tableauIndex) {
    if (canMoveFoundationToTableau(state, foundationIndex, tableauIndex)) {
      final card = state.foundations[foundationIndex].cards.removeLast();
      state.tableau[tableauIndex].addCard(card);
    }
  }

  // Helper to flip top card in tableau if needed
  static void _flipTableauTopCard(GameState state, int index) {
    state.tableau[index].flipTopCard();
  }

  // Recycle waste to stock
  static bool canRecycleWaste(GameState state) {
    return state.stock.isEmpty && state.waste.isNotEmpty;
  }

  static void recycleWaste(GameState state) {
    if (canRecycleWaste(state)) {
      final stockBefore = state.stock.length;
      final wasteBefore = state.waste.length;
      debugPrint('  ♻️ LOGIC recycleWaste: BEFORE (stock=$stockBefore, waste=$wasteBefore)');
      
      // Log the waste cards that will be recycled
      debugPrint('    Waste cards to recycle: ${state.waste.map((c) => '${c.rank.name}${c.suit.name}').join(', ')}');
      
      // Reverse the waste cards when moving back to stock
      // This ensures they come out in the same order when drawn again
      final reversedWaste = state.waste.reversed.toList();
      debugPrint('    Reversed waste list created with ${reversedWaste.length} cards');
      
      state.stock.addCards(reversedWaste);
      debugPrint('    After addCards: stock=${state.stock.length}');
      
      state.waste.clear();
      debugPrint('    After waste.clear(): waste=${state.waste.length}');
      
      debugPrint('  ♻️ LOGIC recycleWaste: AFTER (stock=${state.stock.length}, waste=${state.waste.length})');
      
      // Log stock operation for debugging
      _logStockOperation(state, 'recycle', state.stock.length);
      
      // After recycling, immediately draw so waste is never empty when stock has cards
      if (state.stock.length > 0) {
        debugPrint('  ♻️ LOGIC recycleWaste: Auto-drawing after recycle to keep waste non-empty');
        drawCard(state, state.drawMode);
      } else {
        debugPrint('  ♻️ LOGIC recycleWaste: Stock is empty after recycle, skipping auto-draw');
      }
    }
  }

  // Check if game is won
  static bool isGameWon(GameState state) {
    return state.isWon;
  }

  // Check if game is stuck (no progress moves possible and not won)
  static bool isGameStuck(GameState state) {
    if (isGameWon(state)) return false;

    // Check if can draw from stock
    if (canDrawCard(state, state.drawMode)) return false;

    // Check waste to tableau moves
    for (int i = 0; i < 7; i++) {
      if (canMoveWasteToTableau(state, i)) return false;
    }

    // Check waste to foundation moves
    for (int i = 0; i < 4; i++) {
      if (canMoveWasteToFoundation(state, i)) return false;
    }

    // Check tableau to tableau moves
    for (int from = 0; from < 7; from++) {
      for (int to = 0; to < 7; to++) {
        if (from == to) continue;
        int maxCount = state.tableau[from].cards.length;
        for (int count = 1; count <= maxCount; count++) {
          if (canMoveTableauToTableau(state, from, to, count)) return false;
        }
      }
    }

    // Check tableau to foundation moves
    for (int t = 0; t < 7; t++) {
      for (int f = 0; f < 4; f++) {
        if (canMoveTableauToFoundation(state, t, f)) return false;
      }
    }

    // Check foundation to tableau moves
    for (int f = 0; f < 4; f++) {
      for (int t = 0; t < 7; t++) {
        if (canMoveFoundationToTableau(state, f, t)) return false;
      }
    }

    return true; // No moves possible
  }

  /// Logs stock operations for debugging duplicate card issues
  static void _logStockOperation(GameState state, String operation, int count) {
    final allCards = <Card>[];
    for (final column in state.tableau) {
      allCards.addAll(column.cards);
    }
    allCards.addAll(state.stock.cards);
    allCards.addAll(state.waste);
    for (final foundation in state.foundations) {
      allCards.addAll(foundation.cards);
    }

    final cardSignatures = allCards.map((card) => '${card.suit}-${card.rank}').toSet();
    final hasDuplicates = cardSignatures.length != allCards.length;

    debugPrint('STOCK $operation: $count cards, total: ${allCards.length}, unique: ${cardSignatures.length}, duplicates: $hasDuplicates');
    if (hasDuplicates) {
      debugPrint('DUPLICATE ALERT: Found ${allCards.length - cardSignatures.length} duplicate cards!');
      // Log duplicate details
      final cardCounts = <String, int>{};
      for (final card in allCards) {
        final key = '${card.suit}-${card.rank}';
        cardCounts[key] = (cardCounts[key] ?? 0) + 1;
      }
      final duplicates = cardCounts.entries.where((entry) => entry.value > 1);
      for (final dup in duplicates) {
        debugPrint('  ${dup.key}: ${dup.value} copies');
      }
    }
  }
}