import 'package:flutter_test/flutter_test.dart';
import 'package:coop_klondike/models/card.dart';
import 'package:coop_klondike/models/game_state.dart';
import 'package:coop_klondike/logic/game_logic.dart';

void main() {
  group('GameLogic', () {
    late GameState state;

    setUp(() {
      state = GameState();
    });

    test('canDrawCard and drawCard', () {
      expect(GameLogic.canDrawCard(state, DrawMode.one), true);
      GameLogic.drawCard(state, DrawMode.one);
      expect(state.waste.length, 1);
      expect(state.waste.last.faceUp, true);
    });

    test('cannot draw when stock empty', () {
      // Empty stock
      while (!state.stock.isEmpty) {
        state.stock.drawCard();
      }
      expect(GameLogic.canDrawCard(state, DrawMode.one), false);
    });

    test('canMoveWasteToTableau and moveWasteToTableau', () {
      state.tableau[0].cards.clear();
      state.tableau[0].addCard(Card(suit: Suit.spades, rank: Rank.queen, faceUp: true));

      // Add a card to waste
      final card = Card(suit: Suit.hearts, rank: Rank.jack);
      state.waste.add(card);

      // Can move jack to column with queen
      expect(GameLogic.canMoveWasteToTableau(state, 0), true);
      GameLogic.moveWasteToTableau(state, 0);
      expect(state.waste.isEmpty, true);
      expect(state.tableau[0].topCard, card);
    });

    test('cannot move waste to invalid tableau', () {
      state.tableau[0].cards.clear();
      state.tableau[0].addCard(Card(suit: Suit.hearts, rank: Rank.two, faceUp: true));

      final card = Card(suit: Suit.hearts, rank: Rank.queen);
      state.waste.add(card);

      // Cannot move queen hearts to two hearts (same color)
      expect(GameLogic.canMoveWasteToTableau(state, 0), false);
    });

    test('canMoveWasteToFoundation and moveWasteToFoundation', () {
      final ace = Card(suit: Suit.hearts, rank: Rank.ace);
      state.waste.add(ace);

      expect(GameLogic.canMoveWasteToFoundation(state, 0), true); // Hearts foundation
      GameLogic.moveWasteToFoundation(state, 0);
      expect(state.waste.isEmpty, true);
      expect(state.foundations[0].topCard, ace);
    });

    test('cannot move waste to invalid foundation', () {
      final two = Card(suit: Suit.hearts, rank: Rank.two);
      state.waste.add(two);

      expect(GameLogic.canMoveWasteToFoundation(state, 0), false);
    });

    test('canMoveTableauToTableau and moveTableauToTableau', () {
      state.tableau[0].cards.clear();
      state.tableau[0].addCard(Card(suit: Suit.spades, rank: Rank.queen, faceUp: true));
      state.tableau[6].cards.last = Card(suit: Suit.hearts, rank: Rank.jack, faceUp: true);

      expect(GameLogic.canMoveTableauToTableau(state, 6, 0, 1), true);
      GameLogic.moveTableauToTableau(state, 6, 0, 1);
      expect(state.tableau[0].topCard!.rank, Rank.jack);
      expect(state.tableau[6].cards.length, 6);
    });
    test('canMoveTableauToTableau multiple cards', () {
      // Set up column 0 with a king
      state.tableau[0].cards.clear();
      state.tableau[0].addCard(Card(suit: Suit.spades, rank: Rank.king, faceUp: true));

      // Set up column 6 with a valid sequence: queen (bottom), jack, ten (top)
      state.tableau[6].cards.clear();
      state.tableau[6].addCard(Card(suit: Suit.hearts, rank: Rank.queen, faceUp: true));
      state.tableau[6].addCard(Card(suit: Suit.spades, rank: Rank.jack, faceUp: true));
      state.tableau[6].addCard(Card(suit: Suit.hearts, rank: Rank.ten, faceUp: true));

      // Can move queen, jack, ten (3 cards) to king
      expect(GameLogic.canMoveTableauToTableau(state, 6, 0, 3), true);
      GameLogic.moveTableauToTableau(state, 6, 0, 3);

      // Column 0 should now have king, queen, jack, ten
      expect(state.tableau[0].cards.length, 4);
      expect(state.tableau[0].cards[0].rank, Rank.king);
      expect(state.tableau[0].cards[1].rank, Rank.queen);
      expect(state.tableau[0].cards[2].rank, Rank.jack);
      expect(state.tableau[0].cards[3].rank, Rank.ten);

      // Column 6 should be empty
      expect(state.tableau[6].isEmpty, true);
    });

    test('cannot move invalid tableau to tableau', () {
      // Try to move more cards than available
      expect(GameLogic.canMoveTableauToTableau(state, 0, 1, 5), false);
      // Try to move face-down cards
      // (Top cards are face up, but if we try to move multiple, some might be down)
    });

    test('canMoveTableauToFoundation and moveTableauToFoundation', () {
      state.tableau[0].cards.clear();
      state.tableau[0].addCard(Card(suit: Suit.hearts, rank: Rank.ace, faceUp: true));

      expect(GameLogic.canMoveTableauToFoundation(state, 0, 0), true);
      GameLogic.moveTableauToFoundation(state, 0, 0);
      expect(state.foundations[0].topCard!.rank, Rank.ace);
    });

    test('cannot move invalid tableau to foundation', () {
      expect(GameLogic.canMoveTableauToFoundation(state, 0, 0), false); // Not ace
    });

    test('canMoveFoundationToTableau and moveFoundationToTableau', () {
      // First move ace to foundation
      final ace = Card(suit: Suit.hearts, rank: Rank.ace);
      state.foundations[0].addCard(ace);

      state.tableau[0].cards.clear();
      state.tableau[0].addCard(Card(suit: Suit.spades, rank: Rank.two, faceUp: true));

      // Move back to tableau
      expect(GameLogic.canMoveFoundationToTableau(state, 0, 0), true);
      GameLogic.moveFoundationToTableau(state, 0, 0);
      expect(state.foundations[0].isEmpty, true);
      expect(state.tableau[0].topCard, ace);
    });

    test('flipping cards when moving from tableau', () {
      // When moving from tableau, if the new top card is face down, it should flip
      // But in initial deal, all top cards are face up. So manually set one down.
      final column = state.tableau[6]; // Has 7 cards, top face up
      column.cards[column.cards.length - 2].faceUp = false; // Second top face down

      // Move top card
      GameLogic.moveTableauToTableau(state, 6, 0, 1);
      // Now the new top should be flipped
      expect(column.topCard!.faceUp, true);
    });

    test('isGameWon', () {
      expect(GameLogic.isGameWon(state), false);

      // Fill foundations
      for (final pile in state.foundations) {
        for (int i = 0; i < 13; i++) {
          final rank = Rank.values[i];
          final card = Card(suit: pile.suit, rank: rank);
          pile.addCard(card);
        }
      }
      expect(GameLogic.isGameWon(state), true);
    });

    test('canRecycleWaste returns true when stock is empty and waste is not empty', () {
      // Empty stock
      while (!state.stock.isEmpty) {
        state.stock.drawCard();
      }
      // Add cards to waste
      state.waste.add(Card(suit: Suit.hearts, rank: Rank.ace));
      state.waste.add(Card(suit: Suit.spades, rank: Rank.king));

      expect(GameLogic.canRecycleWaste(state), true);
    });

    test('canRecycleWaste returns false when stock is not empty', () {
      // Stock has cards (default state)
      state.waste.add(Card(suit: Suit.hearts, rank: Rank.ace));

      expect(GameLogic.canRecycleWaste(state), false);
    });

    test('canRecycleWaste returns false when waste is empty', () {
      // Empty stock
      while (!state.stock.isEmpty) {
        state.stock.drawCard();
      }
      // Waste is empty

      expect(GameLogic.canRecycleWaste(state), false);
    });

    test('canRecycleWaste returns false when both stock and waste are empty', () {
      // Empty stock
      while (!state.stock.isEmpty) {
        state.stock.drawCard();
      }
      // Waste is empty

      expect(GameLogic.canRecycleWaste(state), false);
    });

    test('recycleWaste moves all waste cards to stock in reverse order', () {
      // Empty stock
      while (!state.stock.isEmpty) {
        state.stock.drawCard();
      }

      // Add cards to waste in specific order
      final card1 = Card(suit: Suit.hearts, rank: Rank.ace);
      final card2 = Card(suit: Suit.spades, rank: Rank.king);
      final card3 = Card(suit: Suit.diamonds, rank: Rank.queen);
      state.waste.add(card1);
      state.waste.add(card2);
      state.waste.add(card3);

      expect(state.stock.isEmpty, true);
      expect(state.waste.length, 3);

      GameLogic.recycleWaste(state);

      expect(state.waste.isEmpty, true);
      expect(state.stock.length, 3);

      // Cards should be in reverse order (last added to waste becomes first in stock)
      expect(state.stock.drawCard(), card3);
      expect(state.stock.drawCard(), card2);
      expect(state.stock.drawCard(), card1);
    });

    test('recycleWaste does nothing when cannot recycle', () {
      // Stock has cards, waste has cards - cannot recycle
      state.waste.add(Card(suit: Suit.hearts, rank: Rank.ace));
      final initialStockLength = state.stock.length;
      final initialWasteLength = state.waste.length;

      GameLogic.recycleWaste(state);

      expect(state.stock.length, initialStockLength);
      expect(state.waste.length, initialWasteLength);
    });

    test('isGameStuck returns false when game is won', () {
      // Fill foundations to win the game
      for (final pile in state.foundations) {
        for (int i = 0; i < 13; i++) {
          final rank = Rank.values[i];
          final card = Card(suit: pile.suit, rank: rank);
          pile.addCard(card);
        }
      }
      expect(GameLogic.isGameStuck(state), false);
    });

    test('isGameStuck returns false when moves are available', () {
      // Default state should have moves available
      expect(GameLogic.isGameStuck(state), false);
    });

    test('isGameStuck returns true when no moves are possible and game is not won', () {
      // Create a stuck state: empty stock, empty waste,
      // tableau with cards that can't move to each other or foundation
      while (!state.stock.isEmpty) {
        state.stock.drawCard();
      }
      state.waste.clear();

      // Clear tableau and set up cards that can't move
      for (int i = 0; i < 7; i++) {
        state.tableau[i].cards.clear();
        // Add a king to each column - kings can't move since no empty columns and not aces
        state.tableau[i].addCard(Card(suit: Suit.hearts, rank: Rank.king, faceUp: true));
      }

      expect(GameLogic.isGameWon(state), false);
      expect(GameLogic.isGameStuck(state), true);
    });
  });
}