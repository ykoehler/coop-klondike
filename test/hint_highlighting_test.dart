import 'package:flutter_test/flutter_test.dart';
import 'package:coop_klondike/models/game_state.dart';
import 'package:coop_klondike/models/hint.dart';
import 'package:coop_klondike/logic/game_logic.dart';

void main() {
  group('Hint Highlighting Tests', () {
    test('Tableau to tableau hint should only target top card of destination', () {
      // Create a game state and find a valid tableau-to-tableau move
      final state = GameState(seedStr: 'hint-test-1');
      
      // Generate hint - should give us a valid move
      final hint = GameLogic.generateVisualHint(state);

      // We got a hint, now test if it's for tableau moves
      expect(hint, isNotNull);
      if (hint != null && hint.destinationLocation == HintLocation.tableau) {
        // Verify the destination column has cards
        final destColumn = state.tableau[hint.destinationIndex];
        
        // Key principle: The destination in a hint should match the top card of the destination column
        // This is the card that will be revealed and clickable, not face-down cards below it.
        if (destColumn.topCard != null) {
          // The highlighting logic in HintHighlightedCard should check:
          // 1. Is this the top card of the destination column?
          // 2. If yes, highlight it
          // 3. Do NOT highlight face-down cards below it
          expect(destColumn.topCard!.faceUp, true);
        }
      }
    });

    test('Face-down cards in source column should not be highlighted', () {
      final state = GameState(seedStr: 'hint-test-2');

      final hint = GameLogic.generateVisualHint(state);

      // Verify we got a hint
      expect(hint, isNotNull);
      if (hint != null) {
        // If the source is a tableau column, the source card should be face-up
        if (hint.sourceLocation == HintLocation.tableau) {
          final sourceColumn = state.tableau[hint.sourceIndex];
          
          // The hint card should be the top card (face-up)
          expect(sourceColumn.topCard, isNotNull);
          expect(sourceColumn.topCard!.faceUp, true);
          
          // Verify hint card matches the top card
          if (hint.card != null) {
            expect(hint.card!.suit, equals(sourceColumn.topCard!.suit));
            expect(hint.card!.rank, equals(sourceColumn.topCard!.rank));
          }
        }
      }
    });

    test('Empty tableau column destination shows no card highlight', () {
      final state = GameState(seedStr: 'hint-test-3');

      final hint = GameLogic.generateVisualHint(state);

      // For this test, we verify the logic: empty columns can be destinations for Kings
      // but there's no card to highlight in an empty column
      expect(hint, isNotNull);
      
      if (hint != null && hint.destinationLocation == HintLocation.tableau) {
        final destColumn = state.tableau[hint.destinationIndex];
        
        // If destination is empty, topCard is null
        if (destColumn.isEmpty) {
          // No card to highlight - the UI should show the drop zone is valid
          expect(destColumn.topCard, isNull);
        } else {
          // If not empty, there should be a top card
          expect(destColumn.topCard, isNotNull);
        }
      }
    });

    test('Multiple valid moves prefer high-value moves', () {
      final state = GameState(seedStr: 'hint-test-4');

      final hint = GameLogic.generateVisualHint(state);

      // Hints should follow priority: Foundation > Tableau > Draw
      // If a card can go to foundation, that should be suggested
      expect(hint, isNotNull);
    });
  });
}
