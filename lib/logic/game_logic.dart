import '../models/card.dart';
import '../models/game_state.dart';
import '../models/tableau_column.dart';
import '../models/foundation_pile.dart';

class GameLogic {
  // Draw card from stock to waste
  static bool canDrawCard(GameState state) {
    return !state.stock.isEmpty;
  }

  static void drawCard(GameState state) {
    if (canDrawCard(state)) {
      final card = state.stock.drawCard();
      if (card != null) {
        card.faceUp = true;
        state.waste.add(card);
      }
    }
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

  // Check if game is won
  static bool isGameWon(GameState state) {
    return state.isWon;
  }
}