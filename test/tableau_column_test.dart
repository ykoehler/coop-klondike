import 'package:flutter_test/flutter_test.dart';
import '../lib/models/card.dart';
import '../lib/models/tableau_column.dart';

void main() {
  group('TableauColumn', () {
    test('empty column accepts kings', () {
      final column = TableauColumn();
      final king = Card(suit: Suit.hearts, rank: Rank.king);
      expect(column.canAcceptCard(king), true);

      final queen = Card(suit: Suit.hearts, rank: Rank.queen);
      expect(column.canAcceptCard(queen), false);
    });

    test('non-empty column accepts alternating colors descending', () {
      final column = TableauColumn();
      final king = Card(suit: Suit.hearts, rank: Rank.king);
      column.addCard(king);

      final queen = Card(suit: Suit.spades, rank: Rank.queen); // Black on red
      expect(column.canAcceptCard(queen), true);

      final redJack = Card(suit: Suit.diamonds, rank: Rank.jack); // Same color
      expect(column.canAcceptCard(redJack), false);

      final blackTen = Card(suit: Suit.clubs, rank: Rank.ten); // Not descending
      expect(column.canAcceptCard(blackTen), false);
    });

    test('invalid moves on non-empty column', () {
      final column = TableauColumn();
      final king = Card(suit: Suit.hearts, rank: Rank.king);
      column.addCard(king);

      final redQueen = Card(suit: Suit.diamonds, rank: Rank.queen); // Same color
      expect(column.canAcceptCard(redQueen), false);

      final blackKing = Card(suit: Suit.spades, rank: Rank.king); // Same rank, wrong direction
      expect(column.canAcceptCard(blackKing), false);

      final blackAce = Card(suit: Suit.spades, rank: Rank.ace); // Not descending
      expect(column.canAcceptCard(blackAce), false);
    });

    test('add and remove cards', () {
      final column = TableauColumn();
      final card1 = Card(suit: Suit.hearts, rank: Rank.king);
      final card2 = Card(suit: Suit.spades, rank: Rank.queen);

      column.addCard(card1);
      expect(column.isEmpty, false);
      expect(column.topCard, card1);

      column.addCard(card2);
      expect(column.topCard, card2);

      final removed = column.removeCard();
      expect(removed, card2);
      expect(column.topCard, card1);

      final removed2 = column.removeCard();
      expect(removed2, card1);
      expect(column.isEmpty, true);
      expect(column.topCard, null);
    });

    test('removeCard on empty column returns null', () {
      final column = TableauColumn();
      expect(column.removeCard(), null);
    });

    test('flipTopCard flips face-down card', () {
      final column = TableauColumn();
      final card = Card(suit: Suit.hearts, rank: Rank.king, faceUp: false);
      column.addCard(card);

      expect(card.faceUp, false);
      column.flipTopCard();
      expect(card.faceUp, true);
    });

    test('flipTopCard does nothing if already face up', () {
      final column = TableauColumn();
      final card = Card(suit: Suit.hearts, rank: Rank.king, faceUp: true);
      column.addCard(card);

      column.flipTopCard();
      expect(card.faceUp, true);
    });

    test('flipTopCard on empty column does nothing', () {
      final column = TableauColumn();
      column.flipTopCard(); // Should not crash
    });
  });
}