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

      deck1.shuffle(42);
      deck2.shuffle(42);

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

      deck1.shuffle(42);
      deck2.shuffle(43);

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

      deck1.reset(seed: 123);
      deck2.reset(seed: 123);

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
  });
}