import '../models/game_state.dart';
import '../models/card.dart';
import '../models/hint.dart';
import 'package:flutter/foundation.dart';

/// Contains the core game rules and move validation logic for Klondike Solitaire.
/// 
/// This class provides static methods to:
/// - Validate moves before execution (canXxx methods)
/// - Execute valid moves (xxx methods)
/// - Check game state (isGameWon, isGameStuck)
/// 
/// All methods assume the provided [GameState] is valid and won't perform
/// extensive validation. The UI layer should call canXxx before calling the
/// corresponding action method.
class GameLogic {
  // ============================================================================
  // Stock/Waste Management
  // ============================================================================

  /// Checks if a card can be drawn from stock to waste.
  static bool canDrawCard(GameState state, DrawMode mode) {
    return !state.stock.isEmpty;
  }

  /// Draws cards from stock to waste based on the draw mode (1 or 3 cards).
  /// 
  /// Each card is flipped face-up when moved to the waste pile.
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
    _logStockOperation(state, 'draw', numToDraw);
  }

  /// Checks if waste can be recycled to stock.
  /// 
  /// True when stock is empty but waste has cards.
  static bool canRecycleWaste(GameState state) {
    return state.stock.isEmpty && state.waste.isNotEmpty;
  }

  /// Recycles waste pile back to stock in reverse order.
  /// 
  /// This maintains the cycle of the game. All waste cards are moved to stock
  /// in reverse order (so they come out in the original order when drawn).
  /// If stock has cards after recycling, automatically draws one batch to
  /// ensure waste never appears empty during gameplay.
  static void recycleWaste(GameState state) {
    if (!canRecycleWaste(state)) {
      return;
    }
    
    final stockBefore = state.stock.length;
    final wasteBefore = state.waste.length;
    debugPrint('  ♻️ LOGIC recycleWaste: BEFORE (stock=$stockBefore, waste=$wasteBefore)');
    
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
    _logStockOperation(state, 'recycle', state.stock.length);
    
    // After recycling, immediately draw so waste is never empty when stock has cards
    if (state.stock.length > 0) {
      debugPrint('  ♻️ LOGIC recycleWaste: Auto-drawing after recycle to keep waste non-empty');
      drawCard(state, state.drawMode);
    } else {
      debugPrint('  ♻️ LOGIC recycleWaste: Stock is empty after recycle, skipping auto-draw');
    }
  }

  // ============================================================================
  // Waste to Tableau/Foundation Moves
  // ============================================================================

  /// Checks if the top waste card can move to a tableau column.
  static bool canMoveWasteToTableau(GameState state, int tableauIndex) {
    if (state.waste.isEmpty) return false;
    final card = state.waste.last;
    return state.tableau[tableauIndex].canAcceptCard(card);
  }

  /// Moves the top waste card to a tableau column.
  static void moveWasteToTableau(GameState state, int tableauIndex) {
    if (canMoveWasteToTableau(state, tableauIndex)) {
      final card = state.waste.removeLast();
      state.tableau[tableauIndex].addCard(card);
      _flipTableauTopCard(state, tableauIndex);
    }
  }

  /// Checks if the top waste card can move to a foundation pile.
  static bool canMoveWasteToFoundation(GameState state, int foundationIndex) {
    if (state.waste.isEmpty) return false;
    final card = state.waste.last;
    return state.foundations[foundationIndex].canAcceptCard(card);
  }

  /// Moves the top waste card to a foundation pile.
  static void moveWasteToFoundation(GameState state, int foundationIndex) {
    if (canMoveWasteToFoundation(state, foundationIndex)) {
      final card = state.waste.removeLast();
      state.foundations[foundationIndex].addCard(card);
    }
  }

  // ============================================================================
  // Tableau to Tableau/Foundation Moves
  // ============================================================================

  /// Checks if cards can move from one tableau column to another.
  /// 
  /// Validates:
  /// - Not moving to the same column
  /// - Sufficient cards available in source column
  /// - All cards are face-up (can't move face-down cards)
  /// - Top card of moving sequence can stack on destination column
  static bool canMoveTableauToTableau(GameState state, int fromIndex, int toIndex, int cardCount) {
    if (fromIndex == toIndex || cardCount < 1) return false;
    final fromColumn = state.tableau[fromIndex];
    if (fromColumn.cards.length < cardCount) return false;

    final movingCards = fromColumn.cards.sublist(fromColumn.cards.length - cardCount);
    final topMovingCard = movingCards.first;
    if (!topMovingCard.faceUp) return false; // Can't move face-down cards

    return state.tableau[toIndex].canAcceptCard(topMovingCard);
  }

  /// Moves multiple cards from one tableau column to another.
  /// 
  /// Flips the newly exposed card in the source column if needed.
  static void moveTableauToTableau(GameState state, int fromIndex, int toIndex, int cardCount) {
    if (canMoveTableauToTableau(state, fromIndex, toIndex, cardCount)) {
      final fromColumn = state.tableau[fromIndex];
      final movingCards = fromColumn.cards.sublist(fromColumn.cards.length - cardCount);
      fromColumn.cards.removeRange(fromColumn.cards.length - cardCount, fromColumn.cards.length);
      state.tableau[toIndex].cards.addAll(movingCards);
      _flipTableauTopCard(state, fromIndex);
    }
  }

  /// Checks if a tableau card can move to a foundation pile.
  static bool canMoveTableauToFoundation(GameState state, int tableauIndex, int foundationIndex) {
    final column = state.tableau[tableauIndex];
    if (column.isEmpty) return false;
    final card = column.topCard!;
    if (!card.faceUp) return false;
    return state.foundations[foundationIndex].canAcceptCard(card);
  }

  /// Moves a tableau card to a foundation pile.
  static void moveTableauToFoundation(GameState state, int tableauIndex, int foundationIndex) {
    if (canMoveTableauToFoundation(state, tableauIndex, foundationIndex)) {
      final card = state.tableau[tableauIndex].removeCard()!;
      state.foundations[foundationIndex].addCard(card);
      _flipTableauTopCard(state, tableauIndex);
    }
  }

  // ============================================================================
  // Foundation to Tableau Moves (Undo Moves)
  // ============================================================================

  /// Checks if a foundation card can move back to a tableau column.
  /// 
  /// This supports undoing cards that were moved to foundation, enabling
  /// more strategic gameplay.
  static bool canMoveFoundationToTableau(GameState state, int foundationIndex, int tableauIndex) {
    final pile = state.foundations[foundationIndex];
    if (pile.isEmpty) return false;
    final card = pile.topCard!;
    return state.tableau[tableauIndex].canAcceptCard(card);
  }

  /// Moves a foundation card back to a tableau column.
  static void moveFoundationToTableau(GameState state, int foundationIndex, int tableauIndex) {
    if (canMoveFoundationToTableau(state, foundationIndex, tableauIndex)) {
      final card = state.foundations[foundationIndex].cards.removeLast();
      state.tableau[tableauIndex].addCard(card);
    }
  }

  // ============================================================================
  // Game State Checks
  // ============================================================================

  /// Checks if the game has been won.
  /// 
  /// True when all 4 foundation piles are complete (13 cards each).
  static bool isGameWon(GameState state) {
    return state.isWon;
  }

  /// Checks if the game is in a stuck state (no legal moves possible).
  /// 
  /// A game is stuck when:
  /// - Not won
  /// - No cards can be drawn or recycled
  /// - No waste to tableau/foundation moves available
  /// - No tableau to tableau moves available
  /// - No tableau to foundation moves available
  /// - No foundation to tableau moves available
  /// 
  /// OPTIMIZATION: As soon as ONE valid move is found, returns false immediately.
  /// Checks cheaper/faster operations first to fail fast.
  static bool isGameStuck(GameState state) {
    if (isGameWon(state)) return false;

    // Check if can draw from stock or recycle waste (fastest operations)
    if (canDrawCard(state, state.drawMode)) return false;
    if (canRecycleWaste(state)) return false;

    // Check waste to tableau moves (fast - at most 7 checks)
    for (int i = 0; i < 7; i++) {
      if (canMoveWasteToTableau(state, i)) return false;
    }

    // Check waste to foundation moves (fast - at most 4 checks)
    for (int i = 0; i < 4; i++) {
      if (canMoveWasteToFoundation(state, i)) return false;
    }

    // Check foundation to tableau moves (moderate - 4*7 checks)
    // This often reveals available moves and is faster than tableau-to-tableau
    for (int f = 0; f < 4; f++) {
      for (int t = 0; t < 7; t++) {
        if (canMoveFoundationToTableau(state, f, t)) return false;
      }
    }

    // Check tableau to foundation moves (moderate - 7*4 checks)
    for (int t = 0; t < 7; t++) {
      for (int f = 0; f < 4; f++) {
        if (canMoveTableauToFoundation(state, t, f)) return false;
      }
    }

    // Check tableau to tableau moves (most expensive - only if absolutely needed)
    // Strategy: Check each source column's top card against all destinations first
    for (int from = 0; from < 7; from++) {
      if (state.tableau[from].isEmpty) continue;
      
      final sourceCards = state.tableau[from].cards;
      int sourceLength = sourceCards.length;
      
      for (int to = 0; to < 7; to++) {
        if (from == to) continue;
        
        // Try all possible card counts from this source, stopping at first valid move
        for (int count = 1; count <= sourceLength; count++) {
          if (canMoveTableauToTableau(state, from, to, count)) return false;
        }
      }
    }

    return true; // No moves possible
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Flips the top card of a tableau column if it's face-down.
  static void _flipTableauTopCard(GameState state, int index) {
    state.tableau[index].flipTopCard();
  }

  /// Generates a detailed hint with visual location information.
  /// 
  /// Returns null if no moves are available (game is stuck or won).
  /// Returns CardHint with source and destination information for visual highlighting.
  static CardHint? generateVisualHint(GameState state) {
    if (isGameWon(state)) return null;
    if (isGameStuck(state)) return null;

    // Priority 1: Move to foundation (most valuable)
    for (int t = 0; t < 7; t++) {
      for (int f = 0; f < 4; f++) {
        if (canMoveTableauToFoundation(state, t, f)) {
          final card = state.tableau[t].topCard;
          if (card != null) {
            return CardHint(
              description: 'Move to foundation',
              type: HintType.moveTableauToFoundation,
              card: card,
              sourceLocation: HintLocation.tableau,
              sourceIndex: t,
              destinationLocation: HintLocation.foundation,
              destinationIndex: f,
            );
          }
        }
      }
    }

    // Priority 1b: Move waste to foundation
    for (int i = 0; i < 4; i++) {
      if (canMoveWasteToFoundation(state, i)) {
        final card = state.waste.last;
        return CardHint(
          description: 'Move to foundation',
          type: HintType.moveWasteToFoundation,
          card: card,
          sourceLocation: HintLocation.waste,
          sourceIndex: 0,
          destinationLocation: HintLocation.foundation,
          destinationIndex: i,
        );
      }
    }

    // Priority 2: Move tableau cards (creates opportunities)
    for (int from = 0; from < 7; from++) {
      if (state.tableau[from].isEmpty) continue;
      
      final sourceCard = state.tableau[from].topCard;
      if (sourceCard == null || !sourceCard.faceUp) continue;

      for (int to = 0; to < 7; to++) {
        if (from == to) continue;
        
        // Try all possible card counts
        int maxCount = state.tableau[from].cards.length;
        for (int count = 1; count <= maxCount; count++) {
          if (canMoveTableauToTableau(state, from, to, count)) {
            return CardHint(
              description: 'Move tableau card',
              type: HintType.moveTableauToTableau,
              card: sourceCard,
              sourceLocation: HintLocation.tableau,
              sourceIndex: from,
              destinationLocation: HintLocation.tableau,
              destinationIndex: to,
            );
          }
        }
      }
    }

    // Priority 3: Move waste to tableau
    if (state.waste.isNotEmpty) {
      final card = state.waste.last;
      for (int i = 0; i < 7; i++) {
        if (canMoveWasteToTableau(state, i)) {
          return CardHint(
            description: 'Move to tableau',
            type: HintType.moveWasteToTableau,
            card: card,
            sourceLocation: HintLocation.waste,
            sourceIndex: 0,
            destinationLocation: HintLocation.tableau,
            destinationIndex: i,
          );
        }
      }
    }

    // Priority 4: Undo moves from foundation (open up cards)
    for (int f = 0; f < 4; f++) {
      for (int t = 0; t < 7; t++) {
        if (canMoveFoundationToTableau(state, f, t)) {
          final card = state.foundations[f].topCard;
          if (card != null) {
            return CardHint(
              description: 'Undo from foundation',
              type: HintType.moveFoundationToTableau,
              card: card,
              sourceLocation: HintLocation.foundation,
              sourceIndex: f,
              destinationLocation: HintLocation.tableau,
              destinationIndex: t,
            );
          }
        }
      }
    }

    // Priority 5: Draw/recycle stock
    if (canRecycleWaste(state)) {
      return CardHint(
        description: 'Recycle waste',
        type: HintType.recycleWaste,
        sourceLocation: HintLocation.waste,
        sourceIndex: 0,
        destinationLocation: HintLocation.stock,
        destinationIndex: 0,
      );
    }

    if (canDrawCard(state, state.drawMode)) {
      return CardHint(
        description: 'Draw cards',
        type: HintType.drawFromStock,
        sourceLocation: HintLocation.stock,
        sourceIndex: 0,
        destinationLocation: HintLocation.waste,
        destinationIndex: 0,
      );
    }

    return null;
  }

  /// Generates a hint for the next move to make progress.
  /// 
  /// Returns null if no moves are available (game is stuck or won).
  /// Priority order: High-value moves (foundation) > Tableau moves > Draw from stock.
  static String? generateHint(GameState state) {
    final hint = generateVisualHint(state);
    if (hint == null) return null;
    return hint.description;
  }

  /// Logs stock operations and card integrity for debugging duplicate issues.
  /// 
  /// This validates that all 52 cards remain in the game and detects duplicates.
  /// Only enabled in debug mode to avoid performance impact.
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