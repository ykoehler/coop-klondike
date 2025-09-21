import 'package:flutter_test/flutter_test.dart';
import '../lib/models/card.dart';
import '../lib/models/game_state.dart';
import '../lib/models/foundation_pile.dart';

void main() {
  group('GameState', () {
    test('initial dealing distributes cards correctly', () {
      final state = GameState();

      // Check tableau columns
      expect(state.tableau.length, 7);
      for (int i = 0; i < 7; i++) {
        expect(state.tableau[i].cards.length, i + 1);
        expect(state.tableau[i].topCard!.faceUp, true); // Top card face up
        // Check that cards below top are face down
        for (int j = 0; j < i; j++) {
          expect(state.tableau[i].cards[j].faceUp, false);
        }
      }

      // Check foundations are empty
      expect(state.foundations.length, 4);
      for (final pile in state.foundations) {
        expect(pile.isEmpty, true);
      }

      // Check stock has remaining cards: 52 - (1+2+3+4+5+6+7) = 52 - 28 = 24
      expect(state.stock.length, 24);
      expect(state.waste.isEmpty, true);
    });

    test('newGame resets the game', () {
      final state = GameState();
      // Modify state
      state.waste.add(state.stock.drawCard()!);

      state.newGame();

      // Should be back to initial state
      expect(state.tableau.length, 7);
      expect(state.stock.length, 24);
      expect(state.waste.isEmpty, true);
    });

    test('isWon returns false initially', () {
      final state = GameState();
      expect(state.isWon, false);
    });

    test('isWon returns true when all foundations complete', () {
      final state = GameState();

      // Fill each foundation with 13 cards
      for (final pile in state.foundations) {
        for (int i = 0; i < 13; i++) {
          final rank = Rank.values[i];
          final card = Card(suit: pile.suit, rank: rank);
          pile.addCard(card);
        }
        expect(pile.isComplete, true);
      }

      expect(state.isWon, true);
    });
  });
}