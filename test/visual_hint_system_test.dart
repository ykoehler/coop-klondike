import 'package:flutter_test/flutter_test.dart';
import 'package:coop_klondike/models/game_state.dart';
import 'package:coop_klondike/models/hint.dart';
import 'package:coop_klondike/logic/game_logic.dart';

void main() {
  group('Visual Hint System', () {
    test('generateVisualHint returns CardHint with location info', () {
      final gameState = GameState(seedStr: 'test-seed', drawMode: DrawMode.three);
      
      final hint = GameLogic.generateVisualHint(gameState);
      
      // Should generate a hint for a playable game
      expect(hint, isNotNull);
      if (hint != null) {
        expect(hint.card, isNotNull);
        expect(hint.sourceLocation, isNotNull);
        expect(hint.destinationLocation, isNotNull);
        // Source index should be valid for the location type
        expect(hint.sourceIndex >= 0, true);
        expect(hint.destinationIndex >= 0, true);
      }
    });

    test('CardHint contains required location data', () {
      final gameState = GameState(seedStr: 'test-seed', drawMode: DrawMode.three);
      final hint = GameLogic.generateVisualHint(gameState);
      
      if (hint != null) {
        // Verify all required fields are present
        expect(hint.description.isNotEmpty, true);
        expect(hint.type, isNotNull);
        expect(hint.sourceLocation, isNotNull);
        expect(hint.destinationLocation, isNotNull);
        
        // Source and destination should be different (except for same-pile moves)
        final sameLocation = hint.sourceLocation == hint.destinationLocation;
        final sameIndex = hint.sourceIndex == hint.destinationIndex;
        
        // At minimum, either location or index should differ
        expect(sameLocation == false || sameIndex == false, true);
      }
    });

    test('HintLocation enum contains all required locations', () {
      // Verify the enum has all necessary locations
      expect(HintLocation.values.contains(HintLocation.stock), true);
      expect(HintLocation.values.contains(HintLocation.waste), true);
      expect(HintLocation.values.contains(HintLocation.tableau), true);
      expect(HintLocation.values.contains(HintLocation.foundation), true);
      
      expect(HintLocation.values.length, 4);
    });

    test('HintType enum has required hint types', () {
      // Verify hint types are available
      expect(HintType.values.isNotEmpty, true);
      expect(HintType.values.contains(HintType.drawFromStock), true);
      expect(HintType.values.contains(HintType.moveTableauToFoundation), true);
    });
  });
}
