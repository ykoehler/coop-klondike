import 'package:flutter_test/flutter_test.dart';
import 'package:coop_klondike/models/card.dart';
import 'package:coop_klondike/models/game_state.dart';

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

  group('DrawMode', () {
    test('DrawMode enum has correct values', () {
      expect(DrawMode.one.index, 0);
      expect(DrawMode.three.index, 1);
      expect(DrawMode.values.length, 2);
    });
  });

  group('gameId', () {
    test('gameId is generated when not provided', () {
      final state = GameState();
      expect(state.gameId, isNotNull);
      expect(state.gameId, isNotEmpty);
    });

    test('gameId uses provided value', () {
      const customId = 'TEST1-TEST2';
      final state = GameState(gameId: customId);
      expect(state.gameId, customId);
    });

    test('generated gameId has correct format', () {
      final state = GameState();
      final id = state.gameId;
      expect(id.length, 11); // 5-5 with dash
      expect(id.substring(5, 6), '-');
      final part1 = id.substring(0, 5);
      final part2 = id.substring(6, 11);
      expect(_isValidGameIdPart(part1), true);
      expect(_isValidGameIdPart(part2), true);
    });

    test('seeded game produces consistent layout', () {
      const seed = 'SEED1-SEED2';
      final state1 = GameState(gameId: seed);
      final state2 = GameState(gameId: seed);

      // Compare tableau layouts
      for (int i = 0; i < state1.tableau.length; i++) {
        expect(state1.tableau[i].cards.length, state2.tableau[i].cards.length);
        for (int j = 0; j < state1.tableau[i].cards.length; j++) {
          expect(state1.tableau[i].cards[j].suit, state2.tableau[i].cards[j].suit);
          expect(state1.tableau[i].cards[j].rank, state2.tableau[i].cards[j].rank);
        }
      }
    });

    test('different seeds produce different layouts', () {
      final state1 = GameState(gameId: 'SEED1-SEED2');
      final state2 = GameState(gameId: 'DIFF1-DIFF2');

      // At least one card should be different (highly likely)
      bool different = false;
      for (int i = 0; i < state1.tableau.length && !different; i++) {
        for (int j = 0; j < state1.tableau[i].cards.length && !different; j++) {
          if (state1.tableau[i].cards[j].suit != state2.tableau[i].cards[j].suit ||
              state1.tableau[i].cards[j].rank != state2.tableau[i].cards[j].rank) {
            different = true;
          }
        }
      }
      expect(different, true);
    });
  });

  group('DrawMode in GameState', () {
    test('default drawMode is one', () {
      final state = GameState();
      expect(state.drawMode, DrawMode.one);
    });

    test('drawMode can be set to three', () {
      final state = GameState(drawMode: DrawMode.three);
      expect(state.drawMode, DrawMode.three);
    });
  });
}

bool _isValidGameIdPart(String part) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  for (final char in part.split('')) {
    if (!chars.contains(char)) return false;
  }
  return true;
}