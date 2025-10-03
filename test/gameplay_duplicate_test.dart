import 'package:flutter_test/flutter_test.dart';
import 'package:coop_klondike/models/game_state.dart';
import 'package:coop_klondike/models/card.dart';

void main() {
  group('Gameplay Duplicate Cards Investigation', () {
    test('Firebase serialization preserves card uniqueness', () {
      final gameState = GameState();

      // Collect all cards from the initial game state
      final allCards = <Card>[];

      // Add cards from tableau columns
      for (final column in gameState.tableau) {
        allCards.addAll(column.cards);
      }

      // Add cards from foundation piles
      for (final foundation in gameState.foundations) {
        allCards.addAll(foundation.cards);
      }

      // Add cards from stock
      final stockCards = List<Card>.from(gameState.stock.cards);
      allCards.addAll(stockCards);

      // Add cards from waste
      allCards.addAll(gameState.waste);

      // Verify initial uniqueness
      final initialCardSet = allCards.map((c) => '${c.suit}-${c.rank}').toSet();
      expect(initialCardSet.length, 52, reason: 'Initial game should have 52 unique cards');

      // Simulate Firebase serialization/deserialization cycle
      final json = gameState.toJson();
      final gameStateFromJson = GameState.fromJson(json);

      // Collect all cards from the deserialized game state
      final deserializedCards = <Card>[];

      // Add cards from tableau columns
      for (final column in gameStateFromJson.tableau) {
        deserializedCards.addAll(column.cards);
      }

      // Add cards from foundation piles
      for (final foundation in gameStateFromJson.foundations) {
        deserializedCards.addAll(foundation.cards);
      }

      // Add cards from stock
      final deserializedStockCards = List<Card>.from(gameStateFromJson.stock.cards);
      deserializedCards.addAll(deserializedStockCards);

      // Add cards from waste
      deserializedCards.addAll(gameStateFromJson.waste);

      // Verify deserialized cards are unique
      final deserializedCardSet = deserializedCards.map((c) => '${c.suit}-${c.rank}').toSet();
      expect(deserializedCardSet.length, 52, reason: 'Deserialized game should have 52 unique cards');

      // Verify the sets are identical
      expect(deserializedCardSet, equals(initialCardSet),
          reason: 'Deserialized cards should contain exactly the same unique combinations');
    });

    test('Card movement operations preserve uniqueness', () {
      final gameState = GameState();

      // Get initial card count and uniqueness
      final initialCards = _collectAllCards(gameState);
      final initialSet = initialCards.map((c) => '${c.suit}-${c.rank}').toSet();
      expect(initialSet.length, 52);

      // Simulate some card movements (this would normally be done through GameProvider)
      // For this test, we'll manually move some cards to simulate gameplay

      // Move a card from stock to waste (simulate drawing a card)
      if (!gameState.stock.isEmpty) {
        final card = gameState.stock.drawCard();
        if (card != null) {
          gameState.waste.add(card);
        }
      }

      // Verify uniqueness after movement
      final afterMovementCards = _collectAllCards(gameState);
      final afterMovementSet = afterMovementCards.map((c) => '${c.suit}-${c.rank}').toSet();
      expect(afterMovementSet.length, 52, reason: 'Cards should remain unique after movement');

      // Move card from waste to foundation (if possible)
      if (gameState.waste.isNotEmpty) {
        final card = gameState.waste.last;
        // Check if it can be placed on a foundation
        for (final foundation in gameState.foundations) {
          if (foundation.canAcceptCard(card)) {
            final movedCard = gameState.waste.removeLast();
            foundation.addCard(movedCard);
            break;
          }
        }
      }

      // Verify uniqueness after foundation move
      final afterFoundationCards = _collectAllCards(gameState);
      final afterFoundationSet = afterFoundationCards.map((c) => '${c.suit}-${c.rank}').toSet();
      expect(afterFoundationSet.length, 52, reason: 'Cards should remain unique after foundation move');

      // Move card from tableau to foundation (if possible)
      for (int col = 0; col < gameState.tableau.length; col++) {
        final column = gameState.tableau[col];
        if (column.cards.isNotEmpty) {
          final card = column.cards.last;
          for (final foundation in gameState.foundations) {
            if (foundation.canAcceptCard(card)) {
              final movedCard = column.removeCard();
              if (movedCard != null) {
                foundation.addCard(movedCard);
              }
              break;
            }
          }
        }
      }

      // Final verification
      final finalCards = _collectAllCards(gameState);
      final finalSet = finalCards.map((c) => '${c.suit}-${c.rank}').toSet();
      expect(finalSet.length, 52, reason: 'Cards should remain unique after all movements');
    });

    test('Multiple game state operations maintain uniqueness', () {
      // Test multiple newGame() calls
      for (int i = 0; i < 5; i++) {
        final gameState = GameState();
        final cards = _collectAllCards(gameState);
        final cardSet = cards.map((c) => '${c.suit}-${c.rank}').toSet();
        expect(cardSet.length, 52, reason: 'Game state $i should have 52 unique cards');
      }

      // Test newGame() calls
      final gameState = GameState();
      final cards1 = _collectAllCards(gameState);
      final set1 = cards1.map((c) => '${c.suit}-${c.rank}').toSet();

      gameState.newGame();
      final cards2 = _collectAllCards(gameState);
      final set2 = cards2.map((c) => '${c.suit}-${c.rank}').toSet();

      expect(set1.length, 52);
      expect(set2.length, 52);
      // The sets should be different (different shuffle)
      expect(set1 == set2, false);
    });

  });
}

/// Helper function to collect all cards from a game state
List<Card> _collectAllCards(GameState gameState) {
  final allCards = <Card>[];

  // Add cards from tableau columns
  for (final column in gameState.tableau) {
    allCards.addAll(column.cards);
  }

  // Add cards from foundation piles
  for (final foundation in gameState.foundations) {
    allCards.addAll(foundation.cards);
  }

  // Add cards from stock
  final stockCards = List<Card>.from(gameState.stock.cards);
  allCards.addAll(stockCards);

  // Add cards from waste
  allCards.addAll(gameState.waste);

  return allCards;
}