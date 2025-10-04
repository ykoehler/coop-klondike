import 'package:flutter_test/flutter_test.dart';
import 'package:coop_klondike/models/game_state.dart';
import 'package:coop_klondike/models/card.dart';

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

      print('Total cards found: ${allCards.length}');
      print('Expected: 52 cards');

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
        print('ERROR: Found ${allCards.length} cards instead of 52');
        final cardCounts = <String, int>{};
        for (final card in allCards) {
          final key = '${card.suit}-${card.rank}';
          cardCounts[key] = (cardCounts[key] ?? 0) + 1;
        }

        final duplicates = cardCounts.entries.where((entry) => entry.value > 1);
        if (duplicates.isNotEmpty) {
          print('Duplicate cards found:');
          for (final duplicate in duplicates) {
            print('  $duplicate appears ${duplicate.value} times');
          }
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
  });
}