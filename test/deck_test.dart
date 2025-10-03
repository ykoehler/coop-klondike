import 'package:flutter_test/flutter_test.dart';
import 'package:coop_klondike/models/card.dart';
import 'package:coop_klondike/models/deck.dart';

void main() {
  group('Deck', () {
    test('initialization creates 52 unique cards', () {
      final deck = Deck();
      expect(deck.length, 52);
      expect(deck.isEmpty, false);

      // Check all suits and ranks are present
      final suits = <Suit>{};
      final ranks = <Rank>{};
      for (int i = 0; i < 52; i++) {
        final card = deck.drawCard();
        expect(card, isNotNull);
        suits.add(card!.suit);
        ranks.add(card.rank);
      }
      expect(suits.length, 4);
      expect(ranks.length, 13);
      expect(deck.isEmpty, true);
    });

    test('shuffle changes order', () {
      final deck1 = Deck();
      final deck2 = Deck();

      // Draw first few cards before shuffle
      final cards1 = <Card>[];
      for (int i = 0; i < 5; i++) {
        cards1.add(deck1.drawCard()!);
      }

      deck2.shuffle();

      final cards2 = <Card>[];
      for (int i = 0; i < 5; i++) {
        cards2.add(deck2.drawCard()!);
      }

      // Likely different order (though theoretically could be same, but very unlikely)
      bool sameOrder = true;
      for (int i = 0; i < 5; i++) {
        if (cards1[i] != cards2[i]) {
          sameOrder = false;
          break;
        }
      }
      expect(sameOrder, false); // Assuming shuffle works
    });

    test('drawCard removes and returns last card', () {
      final deck = Deck();
      final initialLength = deck.length;
      final card = deck.drawCard();
      expect(card, isNotNull);
      expect(deck.length, initialLength - 1);
    });

    test('drawCard returns null when empty', () {
      final deck = Deck();
      for (int i = 0; i < 52; i++) {
        deck.drawCard();
      }
      expect(deck.isEmpty, true);
      final card = deck.drawCard();
      expect(card, isNull);
    });

    test('reset reinitializes and shuffles deck', () {
      final deck = Deck();
      // Draw some cards
      for (int i = 0; i < 10; i++) {
        deck.drawCard();
      }
      expect(deck.length, 42);

      deck.reset();
      expect(deck.length, 52);
      expect(deck.isEmpty, false);
    });
    test('shuffle with seed produces consistent order', () {
      final deck1 = Deck();
      final deck2 = Deck();

      deck1.shuffle('42');
      deck2.shuffle('42');

      // Compare first 10 cards
      final cards1 = <Card>[];
      final cards2 = <Card>[];
      for (int i = 0; i < 10; i++) {
        cards1.add(deck1.drawCard()!);
        cards2.add(deck2.drawCard()!);
      }

      for (int i = 0; i < 10; i++) {
        expect(cards1[i].suit, cards2[i].suit);
        expect(cards1[i].rank, cards2[i].rank);
      }
    });

    test('shuffle with different seeds produce different orders', () {
      final deck1 = Deck();
      final deck2 = Deck();

      deck1.shuffle('42');
      deck2.shuffle('43');

      // Compare first 10 cards
      final cards1 = <Card>[];
      final cards2 = <Card>[];
      for (int i = 0; i < 10; i++) {
        cards1.add(deck1.drawCard()!);
        cards2.add(deck2.drawCard()!);
      }

      // At least one should be different
      bool different = false;
      for (int i = 0; i < 10; i++) {
        if (cards1[i].suit != cards2[i].suit || cards1[i].rank != cards2[i].rank) {
          different = true;
          break;
        }
      }
      expect(different, true);
    });

    test('reset with seed produces consistent deck', () {
      final deck1 = Deck();
      final deck2 = Deck();

      deck1.reset(seed: '123');
      deck2.reset(seed: '123');

      // Compare all cards
      for (int i = 0; i < 52; i++) {
        final card1 = deck1.drawCard()!;
        final card2 = deck2.drawCard()!;
        expect(card1.suit, card2.suit);
        expect(card1.rank, card2.rank);
      }
    });

    test('addCards adds cards to deck and sets them face down', () {
      final deck = Deck();
      final cards = [
        Card(suit: Suit.hearts, rank: Rank.ace, faceUp: true),
        Card(suit: Suit.spades, rank: Rank.king, faceUp: true),
      ];

      deck.addCards(cards);

      expect(deck.length, 54); // 52 + 2
      expect(cards[0].faceUp, false);
      expect(cards[1].faceUp, false);
    });

    test('addCards preserves existing deck order', () {
      final deck = Deck();
      final initialLength = deck.length;
      final cards = [
        Card(suit: Suit.hearts, rank: Rank.ace),
        Card(suit: Suit.spades, rank: Rank.king),
      ];

      deck.addCards(cards);

      expect(deck.length, initialLength + 2);
      // Cards should be added to the end
      final drawnCard = deck.drawCard();
      expect(drawnCard, isNotNull);
      expect(drawnCard!.suit, cards[1].suit); // Last added card
      expect(drawnCard.rank, cards[1].rank);
    });

    test('deck creates exactly 52 unique cards', () {
      final deck = Deck();

      // Collect all cards
      final allCards = <Card>[];
      for (int i = 0; i < 52; i++) {
        final card = deck.drawCard();
        expect(card, isNotNull, reason: 'Card $i should not be null');
        allCards.add(card!);
      }

      // Verify we have exactly 52 cards
      expect(allCards.length, 52);

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
    });

    test('Firebase serialization preserves card uniqueness', () {
      final deck = Deck();

      // Draw all cards to get them in a list
      final originalCards = <Card>[];
      for (int i = 0; i < 52; i++) {
        final card = deck.drawCard();
        expect(card, isNotNull);
        originalCards.add(card!);
      }

      // Simulate Firebase serialization/deserialization cycle
      final json = {
        'cards': originalCards.map((card) => card.toJson()).toList(),
      };

      final deckFromJson = Deck.fromJson(json);

      // Verify the deserialized deck has the same number of cards
      expect(deckFromJson.length, 52);

      // Collect all cards from deserialized deck
      final deserializedCards = <Card>[];
      for (int i = 0; i < 52; i++) {
        final card = deckFromJson.drawCard();
        expect(card, isNotNull);
        deserializedCards.add(card!);
      }

      // Verify uniqueness in deserialized cards
      for (int i = 0; i < deserializedCards.length; i++) {
        for (int j = i + 1; j < deserializedCards.length; j++) {
          expect(deserializedCards[i], isNot(equals(deserializedCards[j])),
              reason: 'Deserialized cards at positions $i and $j should be different');
        }
      }

      // Verify the deserialized cards contain the same unique combinations as original
      final originalSet = originalCards.map((c) => '${c.suit}-${c.rank}').toSet();
      final deserializedSet = deserializedCards.map((c) => '${c.suit}-${c.rank}').toSet();

      expect(deserializedSet.length, originalSet.length,
          reason: 'Deserialized cards should have same number of unique combinations');
      expect(deserializedSet, equals(originalSet),
          reason: 'Deserialized cards should contain exactly the same unique combinations');
    });
  });

  group('Deck Seed Functionality', () {
    test('seeded shuffle determinism', () {
      final deck1 = Deck();
      deck1.shuffle('test');
      final cards1 = <Card>[];
      for (int i = 0; i < 52; i++) {
        cards1.add(deck1.drawCard()!);
      }

      final deck2 = Deck();
      deck2.shuffle('test');
      final cards2 = <Card>[];
      for (int i = 0; i < 52; i++) {
        cards2.add(deck2.drawCard()!);
      }

      expect(cards1, cards2);
    });

    test('different seeds differ', () {
      final deck1 = Deck();
      deck1.shuffle('test1');
      final cards1 = <Card>[];
      for (int i = 0; i < 52; i++) {
        cards1.add(deck1.drawCard()!);
      }

      final deck2 = Deck();
      deck2.shuffle('test2');
      final cards2 = <Card>[];
      for (int i = 0; i < 52; i++) {
        cards2.add(deck2.drawCard()!);
      }

      expect(cards1, isNot(equals(cards2)));
    });

    test('shuffle without seed produces different results', () {
      final deck1 = Deck();
      deck1.shuffle();
      final cards1 = <Card>[];
      for (int i = 0; i < 52; i++) {
        cards1.add(deck1.drawCard()!);
      }

      final deck2 = Deck();
      deck2.shuffle();
      final cards2 = <Card>[];
      for (int i = 0; i < 52; i++) {
        cards2.add(deck2.drawCard()!);
      }

      expect(cards1, isNot(equals(cards2))); // Highly unlikely to be the same
    });
  });
}