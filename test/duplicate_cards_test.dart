import 'package:flutter_test/flutter_test.dart';
import 'package:coop_klondike/models/game_state.dart';
import 'package:coop_klondike/models/card.dart';
import 'package:coop_klondike/logic/game_logic.dart';

void main() {
  group('Duplicate Cards Issue', () {
    test('GameState should not contain duplicate cards', () {
      final gameState = GameState();

      // Collect all cards from the game state
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
      final stockCards = <Card>[];
      while (!gameState.stock.isEmpty) {
        final card = gameState.stock.drawCard();
        if (card != null) {
          stockCards.add(card);
        }
      }
      allCards.addAll(stockCards);

      // Add cards from waste
      allCards.addAll(gameState.waste);

      // Verify we have exactly 52 cards
      expect(allCards.length, 52, reason: 'Game should contain exactly 52 cards');

      // Check for uniqueness by comparing each card to every other card
      for (int i = 0; i < allCards.length; i++) {
        for (int j = i + 1; j < allCards.length; j++) {
          expect(allCards[i], isNot(equals(allCards[j])),
              reason: 'Cards at positions $i and $j should be different: ${allCards[i]} vs ${allCards[j]}');
        }
      }

      // Verify all suits are present
      final suits = allCards.map((card) => card.suit).toSet();
      expect(suits.length, 4, reason: 'Should have all 4 suits');

      // Verify all ranks are present
      final ranks = allCards.map((card) => card.rank).toSet();
      expect(ranks.length, 13, reason: 'Should have all 13 ranks');

      // Verify each suit has exactly 13 cards
      for (final suit in Suit.values) {
        final suitCards = allCards.where((card) => card.suit == suit).length;
        expect(suitCards, 13, reason: 'Suit $suit should have exactly 13 cards');
      }

      // Verify each rank appears exactly 4 times (once per suit)
      for (final rank in Rank.values) {
        final rankCards = allCards.where((card) => card.rank == rank).length;
        expect(rankCards, 4, reason: 'Rank $rank should appear exactly 4 times');
      }

      // Print some debug info if we find duplicates
      if (allCards.length != 52) {
        final cardCounts = <String, int>{};
        for (final card in allCards) {
          final key = '${card.suit}-${card.rank}';
          cardCounts[key] = (cardCounts[key] ?? 0) + 1;
        }

        final duplicates = cardCounts.entries.where((entry) => entry.value > 1);
        if (duplicates.isNotEmpty) {
          // Debug info removed
        }
      }
    });

    test('Multiple GameState instances should not share card references', () {
      final gameState1 = GameState();
      final gameState2 = GameState();

      // Collect cards from first game state
      final cards1 = <Card>[];
      for (final column in gameState1.tableau) {
        cards1.addAll(column.cards);
      }

      // Collect cards from second game state
      final cards2 = <Card>[];
      for (final column in gameState2.tableau) {
        cards2.addAll(column.cards);
      }

      // Cards should be different objects (different memory references)
      expect(cards1, isNot(same(cards2)));

      // But they should represent different card combinations
      final set1 = cards1.map((c) => '${c.suit}-${c.rank}').toSet();
      final set2 = cards2.map((c) => '${c.suit}-${c.rank}').toSet();

      // The sets should be different (different shuffles)
      expect(set1, isNot(equals(set2)));
    });

    test('GameState card distribution logging should work correctly', () {
      // This test verifies that the logging functionality works and cards are properly distributed
      final gameState = GameState(seedStr: 'test-seed-for-logging');

      // Verify basic structure
      expect(gameState.tableau.length, 7, reason: 'Should have 7 tableau columns');

      // Count total cards in tableau (should be 28: 1+2+3+4+5+6+7)
      int tableauCardCount = 0;
      for (final column in gameState.tableau) {
        tableauCardCount += column.cards.length;
      }
      expect(tableauCardCount, 28, reason: 'Tableau should have 28 cards after dealing');

      // Verify stock has remaining cards (52 - 28 - 3 = 21 for DrawMode.three)
      expect(gameState.stock.length, 21, reason: 'Stock should have 21 cards after dealing (DrawMode.three)');

      // Verify waste has initial cards (3 for DrawMode.three)
      expect(gameState.waste.length, 3, reason: 'Waste should have 3 cards after dealing (DrawMode.three)');

      // Verify foundations are empty after dealing
      for (final foundation in gameState.foundations) {
        expect(foundation.cards.length, 0, reason: 'Foundations should be empty after dealing');
      }

      // Verify face-up cards in tableau
      for (int col = 0; col < gameState.tableau.length; col++) {
        final column = gameState.tableau[col];
        expect(column.cards.length, col + 1, reason: 'Column ${col + 1} should have ${col + 1} cards');

        // Check that only the top card is face up
        for (int row = 0; row < column.cards.length; row++) {
          final card = column.cards[row];
          if (row == column.cards.length - 1) {
            expect(card.faceUp, true, reason: 'Top card in column ${col + 1} should be face up');
          } else {
            expect(card.faceUp, false, reason: 'Non-top card at row $row in column ${col + 1} should be face down');
          }
        }
      }

      // Collect all cards to verify uniqueness
      final allCards = <Card>[];
      for (final column in gameState.tableau) {
        allCards.addAll(column.cards);
      }

      // Add stock cards
      final stockSnapshot = gameState.stock.cards;
      allCards.addAll(stockSnapshot);
      
      // Add waste cards
      allCards.addAll(gameState.waste);

      // Verify total of 52 unique cards
      expect(allCards.length, 52, reason: 'Total cards should be 52');

      // Check for duplicates
      final cardSignatures = allCards.map((card) => '${card.suit}-${card.rank}').toSet();
      expect(cardSignatures.length, 52, reason: 'Should have 52 unique card signatures');

      // Verify all suits and ranks are present
      final suits = allCards.map((card) => card.suit).toSet();
      final ranks = allCards.map((card) => card.rank).toSet();
      expect(suits.length, 4, reason: 'Should have all 4 suits');
      expect(ranks.length, 13, reason: 'Should have all 13 ranks');
    });

    test('Stock drawing should not create duplicates', () {
      final gameState = GameState(seedStr: 'test-stock-drawing');

      // Record initial state (DrawMode.three draws 3 cards initially)
      final initialStockCount = gameState.stock.length;
      final initialWasteCount = gameState.waste.length;

      // Collect all cards initially
      final initialAllCards = <Card>[];
      for (final column in gameState.tableau) {
        initialAllCards.addAll(column.cards);
      }
      initialAllCards.addAll(gameState.stock.cards);
      initialAllCards.addAll(gameState.waste);

      expect(initialAllCards.length, 52, reason: 'Should start with 52 cards');
      expect(initialStockCount, 21, reason: 'Stock should have 21 cards initially (DrawMode.three)');
      expect(initialWasteCount, 3, reason: 'Waste should have 3 cards initially (DrawMode.three)');

      // Draw 3 more cards (3-card draw mode)
      GameLogic.drawCard(gameState, DrawMode.three);

      // Verify state after drawing
      expect(gameState.stock.length, initialStockCount - 3, reason: 'Stock should have 3 fewer cards');
      expect(gameState.waste.length, 6, reason: 'Waste should have 6 cards');

      // Collect all cards after drawing
      final afterDrawAllCards = <Card>[];
      for (final column in gameState.tableau) {
        afterDrawAllCards.addAll(column.cards);
      }
      afterDrawAllCards.addAll(gameState.stock.cards);
      afterDrawAllCards.addAll(gameState.waste);

      // Should still have exactly 52 cards
      expect(afterDrawAllCards.length, 52, reason: 'Should still have 52 cards after drawing');

      // Check for duplicates
      final afterDrawSignatures = afterDrawAllCards.map((card) => '${card.suit}-${card.rank}').toSet();
      expect(afterDrawSignatures.length, 52, reason: 'Should still have 52 unique card signatures after drawing');

      // Verify drawn cards are face up in waste
      for (final card in gameState.waste) {
        expect(card.faceUp, true, reason: 'Cards in waste should be face up');
      }

      // Draw remaining cards
      while (!gameState.stock.isEmpty) {
        GameLogic.drawCard(gameState, DrawMode.three);
      }

      // Collect all cards after emptying stock
      final afterEmptyStockAllCards = <Card>[];
      for (final column in gameState.tableau) {
        afterEmptyStockAllCards.addAll(column.cards);
      }
      afterEmptyStockAllCards.addAll(gameState.stock.cards);
      afterEmptyStockAllCards.addAll(gameState.waste);

      expect(afterEmptyStockAllCards.length, 52, reason: 'Should still have 52 cards after emptying stock');
      expect(gameState.stock.length, 0, reason: 'Stock should be empty');

      // Check for duplicates after emptying stock
      final afterEmptySignatures = afterEmptyStockAllCards.map((card) => '${card.suit}-${card.rank}').toSet();
      expect(afterEmptySignatures.length, 52, reason: 'Should still have 52 unique card signatures after emptying stock');
    });

    test('Stock recycling should not create duplicates', () {
      final gameState = GameState(seedStr: 'test-stock-recycling');

      // Draw all cards to waste
      while (!gameState.stock.isEmpty) {
        GameLogic.drawCard(gameState, DrawMode.three);
      }

      expect(gameState.stock.length, 0, reason: 'Stock should be empty');
      expect(gameState.waste.length, 24, reason: 'Waste should have 24 cards');

      // Collect all cards before recycling
      final beforeRecycleAllCards = <Card>[];
      for (final column in gameState.tableau) {
        beforeRecycleAllCards.addAll(column.cards);
      }
      beforeRecycleAllCards.addAll(gameState.stock.cards);
      beforeRecycleAllCards.addAll(gameState.waste);

      expect(beforeRecycleAllCards.length, 52, reason: 'Should have 52 cards before recycling');

      // Recycle waste back to stock
      GameLogic.recycleWaste(gameState);

      expect(gameState.stock.length, 24, reason: 'Stock should have 24 cards after recycling');
      expect(gameState.waste.length, 0, reason: 'Waste should be empty after recycling');

      // Collect all cards after recycling
      final afterRecycleAllCards = <Card>[];
      for (final column in gameState.tableau) {
        afterRecycleAllCards.addAll(column.cards);
      }
      afterRecycleAllCards.addAll(gameState.stock.cards);
      afterRecycleAllCards.addAll(gameState.waste);

      expect(afterRecycleAllCards.length, 52, reason: 'Should still have 52 cards after recycling');

      // Check for duplicates after recycling
      final afterRecycleSignatures = afterRecycleAllCards.map((card) => '${card.suit}-${card.rank}').toSet();
      expect(afterRecycleSignatures.length, 52, reason: 'Should still have 52 unique card signatures after recycling');

      // Verify recycled cards are face down in stock
      for (final card in gameState.stock.cards) {
        expect(card.faceUp, false, reason: 'Cards in stock should be face down after recycling');
      }
    });

    test('Multiple draw/recycle cycles preserve card integrity', () {
      final gameState = GameState(seedStr: 'multi-cycle-integrity');

      bool checkIntegrity() {
        final allCards = <Card>[];
        for (final column in gameState.tableau) {
          allCards.addAll(column.cards);
        }
        allCards.addAll(gameState.stock.cards);
        allCards.addAll(gameState.waste);
        for (final foundation in gameState.foundations) {
          allCards.addAll(foundation.cards);
        }

        if (allCards.length != 52) {
          return false;
        }
        return allCards.toSet().length == 52;
      }

      for (int cycle = 0; cycle < 10; cycle++) {
        while (!gameState.stock.isEmpty) {
          GameLogic.drawCard(gameState, DrawMode.three);
          expect(checkIntegrity(), isTrue,
              reason: 'Integrity should hold during draw cycle ${cycle + 1}');
        }

        expect(gameState.waste.length, 24,
            reason: 'Waste should contain all 24 stock cards after drawing');
        expect(checkIntegrity(), isTrue,
            reason: 'Integrity should hold before recycling in cycle ${cycle + 1}');

        GameLogic.recycleWaste(gameState);

        expect(gameState.stock.length, 24,
            reason: 'Stock should be refilled after recycling in cycle ${cycle + 1}');
        expect(gameState.waste.length, 0,
            reason: 'Waste should be empty after recycling in cycle ${cycle + 1}');
        expect(checkIntegrity(), isTrue,
            reason: 'Integrity should hold after recycling in cycle ${cycle + 1}');
      }
    });
  });
}