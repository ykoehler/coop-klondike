import 'package:flutter_test/flutter_test.dart';
import 'package:coop_klondike/models/game_state.dart';
import 'package:coop_klondike/models/tableau_column.dart';
import 'package:coop_klondike/models/card.dart';

void main() {
  group('Empty Tableau Column Tests', () {
    test('Empty tableau columns should be preserved through serialization', () {
      // Create a game state
      final gameState = GameState(gameId: 'TEST-EMPTY', seedStr: 'test-seed');
      
      // Clear the first three columns to simulate gameplay
      gameState.tableau[0].cards.clear();
      gameState.tableau[1].cards.clear();
      gameState.tableau[2].cards.clear();
      
      // Serialize to JSON
      final json = gameState.toJson();
      
      // Deserialize from JSON
      final restoredState = GameState.fromJson(json);
      
      // Verify we still have exactly 7 tableau columns
      expect(restoredState.tableau.length, 7, reason: 'Should always have 7 tableau columns');
      
      // Verify the first three columns are empty
      expect(restoredState.tableau[0].cards.isEmpty, true, reason: 'Column 0 should be empty');
      expect(restoredState.tableau[1].cards.isEmpty, true, reason: 'Column 1 should be empty');
      expect(restoredState.tableau[2].cards.isEmpty, true, reason: 'Column 2 should be empty');
      
      // Verify the other columns still have cards
      expect(restoredState.tableau[3].cards.isNotEmpty, true, reason: 'Column 3 should have cards');
      expect(restoredState.tableau[4].cards.isNotEmpty, true, reason: 'Column 4 should have cards');
      expect(restoredState.tableau[5].cards.isNotEmpty, true, reason: 'Column 5 should have cards');
      expect(restoredState.tableau[6].cards.isNotEmpty, true, reason: 'Column 6 should have cards');
    });

    test('Empty tableau columns should accept Kings', () {
      final column = TableauColumn();
      
      // Create a King of Hearts
      final king = Card(suit: Suit.hearts, rank: Rank.king);
      king.faceUp = true;
      
      // Empty column should only accept Kings
      expect(column.canAcceptCard(king), true, reason: 'Empty column should accept King');
      
      // Create a Queen of Spades
      final queen = Card(suit: Suit.spades, rank: Rank.queen);
      queen.faceUp = true;
      
      // Empty column should not accept non-Kings
      expect(column.canAcceptCard(queen), false, reason: 'Empty column should not accept Queen');
    });

    test('All tableau columns preserved even if only one has cards', () {
      final gameState = GameState(gameId: 'TEST-SINGLE', seedStr: 'test-seed2');
      
      // Clear all columns except the last one
      for (int i = 0; i < 6; i++) {
        gameState.tableau[i].cards.clear();
      }
      
      // Serialize and deserialize
      final json = gameState.toJson();
      final restoredState = GameState.fromJson(json);
      
      // Verify we still have 7 columns
      expect(restoredState.tableau.length, 7, reason: 'Should maintain 7 columns');
      
      // Verify first 6 are empty
      for (int i = 0; i < 6; i++) {
        expect(restoredState.tableau[i].cards.isEmpty, true, 
          reason: 'Column $i should be empty');
      }
      
      // Verify last column has cards
      expect(restoredState.tableau[6].cards.isNotEmpty, true, 
        reason: 'Column 6 should have cards');
    });

    test('JSON with fewer than 7 columns should be padded', () {
      // Create a minimal JSON with only 3 tableau columns
      final json = {
        'gameId': 'TEST-FEW',
        'seed': 'test-seed3',
        'drawMode': 'DrawMode.three',
        'existsInFirebase': true,
        'tableau': [
          {'cards': []},
          {'cards': []},
          {'cards': []}
        ],
        'foundations': List.generate(4, (_) => {'cards': []}),
        'stock': {'cards': []},
        'waste': [],
      };
      
      final gameState = GameState.fromJson(json);
      
      // Should be padded to 7 columns
      expect(gameState.tableau.length, 7, reason: 'Should pad to 7 columns');
      
      // All should be empty in this case
      for (int i = 0; i < 7; i++) {
        expect(gameState.tableau[i].cards.isEmpty, true, 
          reason: 'Column $i should be empty');
      }
    });

    test('Column indices preserved when list entry missing', () {
      final originalState = GameState(gameId: 'TEST-MISSING', seedStr: 'seed-missing');

      // Clear out a middle column and capture original card identities for comparison
      originalState.tableau[1].cards.clear();
      final referenceColumnTwo = originalState.tableau[2]
          .cards
          .map((card) => '${card.suit.name}-${card.rank.name}-${card.faceUp}')
          .toList();

      final json = originalState.toJson();
      final tableauList = List<Map<String, dynamic>>.from(json['tableau'] as List);

      // Simulate data loss where Firebase drops the empty column entry entirely
      tableauList.removeWhere((column) => column['columnIndex'] == 1);

      final mutatedJson = Map<String, dynamic>.from(json);
      mutatedJson['tableau'] = tableauList;

      final restoredState = GameState.fromJson(mutatedJson);

      expect(restoredState.tableau.length, 7);
      expect(restoredState.tableau[1].columnIndex, 1);
      expect(restoredState.tableau[1].cards, isEmpty);
      expect(
        restoredState.tableau[2]
            .cards
            .map((card) => '${card.suit.name}-${card.rank.name}-${card.faceUp}')
            .toList(),
        referenceColumnTwo,
      );
    });

    test('Column indices preserved when sparse map used', () {
      final state = GameState(gameId: 'TEST-SPARSE', seedStr: 'seed-sparse');
      state.tableau[4].cards.clear();

      final json = state.toJson();
      final tableauEntries = (json['tableau'] as List)
          .cast<Map<String, dynamic>>()
          .where((column) => column['columnIndex'] != null)
          .toList();

      final sparseMap = <String, dynamic>{
        for (final entry in tableauEntries)
          if (entry['columnIndex'] != 4)
            '${entry['columnIndex']}' : entry,
      };

      final mutatedJson = Map<String, dynamic>.from(json);
      mutatedJson['tableau'] = sparseMap; // Missing key "4"

      final restored = GameState.fromJson(mutatedJson);

      expect(restored.tableau.length, 7);
      expect(restored.tableau[4].columnIndex, 4);
      expect(restored.tableau[4].cards, isEmpty);
      expect(restored.tableau[3].columnIndex, 3);
      expect(restored.tableau[5].columnIndex, 5);
    });

    test('JSON with more than 7 columns should be trimmed', () {
      // Create JSON with 9 tableau columns
      final json = {
        'gameId': 'TEST-MANY',
        'seed': 'test-seed4',
        'drawMode': 'DrawMode.three',
        'existsInFirebase': true,
        'tableau': List.generate(9, (i) => {
          'cards': i < 7 ? [
            {'suit': 'Suit.hearts', 'rank': 'Rank.ace', 'faceUp': true}
          ] : []
        }),
        'foundations': List.generate(4, (_) => {'cards': []}),
        'stock': {'cards': []},
        'waste': [],
      };
      
      final gameState = GameState.fromJson(json);
      
      // Should be trimmed to 7 columns
      expect(gameState.tableau.length, 7, reason: 'Should trim to 7 columns');
      
      // First 7 should have cards from the JSON
      for (int i = 0; i < 7; i++) {
        expect(gameState.tableau[i].cards.isNotEmpty, true, 
          reason: 'Column $i should have cards');
      }
    });

    test('Empty leftmost column after gameplay should persist', () {
      // Simulate a game where the leftmost column becomes empty during play
      final gameState = GameState(gameId: 'TEST-GAMEPLAY', seedStr: 'gameplay-seed');
      
      // Get initial card count from column 0
      final initialCount = gameState.tableau[0].cards.length;
      expect(initialCount, greaterThan(0), reason: 'Column should start with cards');
      
      // Remove all cards from column 0 (simulating successful moves to foundation)
      gameState.tableau[0].cards.clear();
      
      // Save and reload
      final json = gameState.toJson();
      final reloadedState = GameState.fromJson(json);
      
      // Column 0 should still exist and be empty
      expect(reloadedState.tableau.length, 7);
      expect(reloadedState.tableau[0].cards.isEmpty, true);
      
      // It should accept a King
      final king = Card(suit: Suit.diamonds, rank: Rank.king);
      king.faceUp = true;
      expect(reloadedState.tableau[0].canAcceptCard(king), true);
    });
  });
}
