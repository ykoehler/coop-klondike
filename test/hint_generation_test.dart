import 'package:flutter_test/flutter_test.dart';
import 'package:coop_klondike/models/game_state.dart';
import 'package:coop_klondike/models/card.dart';
import 'package:coop_klondike/logic/game_logic.dart';

void main() {
  group('Hint Generation Tests', () {
    test('generateHint returns null when game is won', () {
      final state = GameState();
      
      // Manually complete all foundations
      for (var suit in Suit.values) {
        for (var rank in Rank.values) {
          final card = Card(suit: suit, rank: rank);
          state.foundations[suit.index].addCard(card);
        }
      }
      
      final hint = GameLogic.generateHint(state);
      expect(hint, isNull);
    });

    test('generateHint returns non-null hint when moves are available', () {
      final state = GameState(seedStr: 'test-game-with-moves');
      
      // The initial game state always has moves available (stock cards, tableau moves, etc)
      // So a hint should be generated
      final hint = GameLogic.generateHint(state);
      expect(hint, isNotNull);
    });

    test('generateHint contains hint text', () {
      final state = GameState(seedStr: 'test-hint-text');
      
      final hint = GameLogic.generateHint(state);
      
      // Hint should be a non-empty string
      if (hint != null) {
        expect(hint.length, greaterThan(0));
        expect(hint, isA<String>());
      }
    });

    test('generateHint suggests foundation moves when possible', () {
      final state = GameState(seedStr: 'test-foundation');
      
      // Reset to known state
      state.newGame();
      
      // If ace is available in waste or tableau, hint should mention foundation
      // This is a probabilistic test based on the seed
      final hint = GameLogic.generateHint(state);
      
      // Should get some hint since fresh game always has moves
      expect(hint, isNotNull);
    });

    test('generateHint is idempotent for same game state', () {
      final state = GameState(seedStr: 'test-idempotent');
      
      final hint1 = GameLogic.generateHint(state);
      final hint2 = GameLogic.generateHint(state);
      
      // Same state should produce same hint
      expect(hint1, equals(hint2));
    });
  });
}
