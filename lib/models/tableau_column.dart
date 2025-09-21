import 'card.dart';

class TableauColumn {
  List<Card> cards = [];

  bool canAcceptCard(Card card) {
    if (cards.isEmpty) {
      return card.rank == Rank.king; // Only kings can start empty columns
    }
    final topCard = cards.last;
    return card.canStackOn(topCard);
  }

  void addCard(Card card) {
    cards.add(card);
  }

  Card? removeCard() {
    if (cards.isEmpty) return null;
    return cards.removeLast();
  }

  Card? get topCard => cards.isNotEmpty ? cards.last : null;

  bool get isEmpty => cards.isEmpty;

  // Flip the top card if it's face down
  void flipTopCard() {
    if (cards.isNotEmpty && !cards.last.faceUp) {
      cards.last.faceUp = true;
    }
  }

  @override
  String toString() {
    return 'TableauColumn(${cards.length} cards)';
  }
}