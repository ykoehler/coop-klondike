import 'card.dart';

class FoundationPile {
  final Suit suit;
  List<Card> cards = [];

  FoundationPile({required this.suit});

  bool canAcceptCard(Card card) {
    if (card.suit != suit) return false;
    if (cards.isEmpty) {
      return card.rank == Rank.ace; // Only aces can start foundations
    }
    final topCard = cards.last;
    return card.canPlaceOnFoundation(topCard);
  }

  void addCard(Card card) {
    cards.add(card);
  }

  Card? get topCard => cards.isNotEmpty ? cards.last : null;

  bool get isEmpty => cards.isEmpty;

  bool get isComplete => cards.length == 13; // All ranks

  @override
  String toString() {
    return 'FoundationPile(${suit.name}: ${cards.length} cards)';
  }
}