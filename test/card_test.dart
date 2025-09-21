import 'package:flutter_test/flutter_test.dart';
import '../lib/models/card.dart';

void main() {
  group('Card', () {
    test('Card properties', () {
      final card = Card(suit: Suit.hearts, rank: Rank.ace);
      expect(card.suit, Suit.hearts);
      expect(card.rank, Rank.ace);
      expect(card.faceUp, false);
      expect(card.isRed, true);
      expect(card.isBlack, false);
      expect(card.rankValue, 1);

      final blackCard = Card(suit: Suit.spades, rank: Rank.king);
      expect(blackCard.isRed, false);
      expect(blackCard.isBlack, true);
      expect(blackCard.rankValue, 13);
    });

    test('canStackOn - valid moves', () {
      final redKing = Card(suit: Suit.hearts, rank: Rank.king);
      final blackQueen = Card(suit: Suit.spades, rank: Rank.queen);
      expect(blackQueen.canStackOn(redKing), true);

      final blackJack = Card(suit: Suit.clubs, rank: Rank.jack);
      final redQueen = Card(suit: Suit.diamonds, rank: Rank.queen);
      expect(blackJack.canStackOn(redQueen), true);
    });

    test('canStackOn - invalid moves', () {
      final redKing = Card(suit: Suit.hearts, rank: Rank.king);
      final redQueen = Card(suit: Suit.diamonds, rank: Rank.queen);
      expect(redQueen.canStackOn(redKing), false); // Same color

      final blackKing = Card(suit: Suit.spades, rank: Rank.king);
      final blackQueen = Card(suit: Suit.clubs, rank: Rank.queen);
      expect(blackQueen.canStackOn(blackKing), false); // Same color

      final redTen = Card(suit: Suit.hearts, rank: Rank.ten);
      final blackKing2 = Card(suit: Suit.spades, rank: Rank.king);
      expect(redTen.canStackOn(blackKing2), false); // Not descending
    });

    test('canPlaceOnFoundation - valid moves', () {
      final ace = Card(suit: Suit.hearts, rank: Rank.ace);
      final two = Card(suit: Suit.hearts, rank: Rank.two);
      expect(two.canPlaceOnFoundation(ace), true);

      final three = Card(suit: Suit.hearts, rank: Rank.three);
      expect(three.canPlaceOnFoundation(two), true);
    });

    test('canPlaceOnFoundation - invalid moves', () {
      final ace = Card(suit: Suit.hearts, rank: Rank.ace);
      final two = Card(suit: Suit.hearts, rank: Rank.two);
      expect(ace.canPlaceOnFoundation(two), false); // Descending

      final spadeAce = Card(suit: Suit.spades, rank: Rank.ace);
      expect(spadeAce.canPlaceOnFoundation(ace), false); // Different suit

      final three = Card(suit: Suit.hearts, rank: Rank.three);
      expect(three.canPlaceOnFoundation(ace), false); // Skipping rank
    });

    test('toString', () {
      final card = Card(suit: Suit.hearts, rank: Rank.ace);
      expect(card.toString(), 'aceH');

      final king = Card(suit: Suit.spades, rank: Rank.king);
      expect(king.toString(), 'kingS');
    });

    test('equality', () {
      final card1 = Card(suit: Suit.hearts, rank: Rank.ace);
      final card2 = Card(suit: Suit.hearts, rank: Rank.ace);
      final card3 = Card(suit: Suit.diamonds, rank: Rank.ace);

      expect(card1 == card2, true);
      expect(card1 == card3, false);
      expect(card1.hashCode == card2.hashCode, true);
    });
  });
}