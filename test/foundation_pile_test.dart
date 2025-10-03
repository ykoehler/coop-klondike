import 'package:flutter_test/flutter_test.dart';
import 'package:coop_klondike/models/card.dart';
import 'package:coop_klondike/models/foundation_pile.dart';

void main() {
  group('FoundationPile', () {
    test('empty pile accepts any ace and locks suit after first card', () {
      final pile = FoundationPile();
      final heartsAce = Card(suit: Suit.hearts, rank: Rank.ace);
      final spadesAce = Card(suit: Suit.spades, rank: Rank.ace);

      expect(pile.canAcceptCard(heartsAce), true);
      expect(pile.canAcceptCard(spadesAce), true);

      pile.addCard(spadesAce);
      expect(pile.suit, Suit.spades);

      final heartsTwo = Card(suit: Suit.hearts, rank: Rank.two);
      expect(pile.canAcceptCard(heartsTwo), false);
    });

    test('accepts ascending cards of same suit', () {
      final pile = FoundationPile();
      final ace = Card(suit: Suit.hearts, rank: Rank.ace);
      pile.addCard(ace);

      final two = Card(suit: Suit.hearts, rank: Rank.two);
      expect(pile.canAcceptCard(two), true);

      pile.addCard(two);
      final three = Card(suit: Suit.hearts, rank: Rank.three);
      expect(pile.canAcceptCard(three), true);
    });

    test('rejects wrong suit or non-ascending', () {
      final pile = FoundationPile();
      final ace = Card(suit: Suit.hearts, rank: Rank.ace);
      pile.addCard(ace);

      final spadeTwo = Card(suit: Suit.spades, rank: Rank.two);
      expect(pile.canAcceptCard(spadeTwo), false);

      final heartsThree = Card(suit: Suit.hearts, rank: Rank.three);
      expect(pile.canAcceptCard(heartsThree), false); // Skipping two

      final heartsAce = Card(suit: Suit.hearts, rank: Rank.ace);
      expect(pile.canAcceptCard(heartsAce), false); // Descending
    });

    test('addCard and topCard', () {
      final pile = FoundationPile();
      expect(pile.isEmpty, true);
      expect(pile.topCard, null);

      final ace = Card(suit: Suit.hearts, rank: Rank.ace);
      pile.addCard(ace);
      expect(pile.isEmpty, false);
      expect(pile.topCard, ace);
    });

    test('isComplete when 13 cards', () {
      final pile = FoundationPile();
      expect(pile.isComplete, false);

      for (int i = 0; i < 13; i++) {
        final rank = Rank.values[i];
        final card = Card(suit: Suit.hearts, rank: rank);
        pile.addCard(card);
      }
      expect(pile.isComplete, true);
    });

    test('suit remains locked even when cards are removed', () {
      final pile = FoundationPile();
      final ace = Card(suit: Suit.diamonds, rank: Rank.ace);
      final two = Card(suit: Suit.diamonds, rank: Rank.two);

      pile.addCard(ace);
      pile.addCard(two);
      expect(pile.suit, Suit.diamonds);

      pile.cards.removeLast();
      pile.cards.removeLast();
      expect(pile.cards, isEmpty);
      expect(pile.suit, Suit.diamonds);

      final spadeAce = Card(suit: Suit.spades, rank: Rank.ace);
      expect(pile.canAcceptCard(spadeAce), false);

      final diamondAce = Card(suit: Suit.diamonds, rank: Rank.ace);
      expect(pile.canAcceptCard(diamondAce), true);
    });
  });
}