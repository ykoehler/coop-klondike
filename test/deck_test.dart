import 'package:flutter_test/flutter_test.dart';
import '../lib/models/card.dart';
import '../lib/models/deck.dart';

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
  });
}