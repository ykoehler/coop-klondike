import 'package:flutter_test/flutter_test.dart';
import '../lib/models/card.dart';
import '../lib/models/foundation_pile.dart';

void main() {
  group('FoundationPile', () {
    test('empty pile accepts aces of matching suit', () {
      final heartsPile = FoundationPile(suit: Suit.hearts);
      final ace = Card(suit: Suit.hearts, rank: Rank.ace);
      expect(heartsPile.canAcceptCard(ace), true);

      final spadeAce = Card(suit: Suit.spades, rank: Rank.ace);
      expect(heartsPile.canAcceptCard(spadeAce), false);

      final two = Card(suit: Suit.hearts, rank: Rank.two);
      expect(heartsPile.canAcceptCard(two), false);
    });

    test('accepts ascending cards of same suit', () {
      final heartsPile = FoundationPile(suit: Suit.hearts);
      final ace = Card(suit: Suit.hearts, rank: Rank.ace);
      heartsPile.addCard(ace);

      final two = Card(suit: Suit.hearts, rank: Rank.two);
      expect(heartsPile.canAcceptCard(two), true);

      heartsPile.addCard(two);
      final three = Card(suit: Suit.hearts, rank: Rank.three);
      expect(heartsPile.canAcceptCard(three), true);
    });

    test('rejects wrong suit or non-ascending', () {
      final heartsPile = FoundationPile(suit: Suit.hearts);
      final ace = Card(suit: Suit.hearts, rank: Rank.ace);
      heartsPile.addCard(ace);

      final spadeTwo = Card(suit: Suit.spades, rank: Rank.two);
      expect(heartsPile.canAcceptCard(spadeTwo), false);

      final heartsThree = Card(suit: Suit.hearts, rank: Rank.three);
      expect(heartsPile.canAcceptCard(heartsThree), false); // Skipping two

      final heartsAce = Card(suit: Suit.hearts, rank: Rank.ace);
      expect(heartsPile.canAcceptCard(heartsAce), false); // Descending
    });

    test('addCard and topCard', () {
      final pile = FoundationPile(suit: Suit.hearts);
      expect(pile.isEmpty, true);
      expect(pile.topCard, null);

      final ace = Card(suit: Suit.hearts, rank: Rank.ace);
      pile.addCard(ace);
      expect(pile.isEmpty, false);
      expect(pile.topCard, ace);
    });

    test('isComplete when 13 cards', () {
      final pile = FoundationPile(suit: Suit.hearts);
      expect(pile.isComplete, false);

      for (int i = 0; i < 13; i++) {
        final rank = Rank.values[i];
        final card = Card(suit: Suit.hearts, rank: rank);
        pile.addCard(card);
      }
      expect(pile.isComplete, true);
    });
  });
}