import 'card.dart';
import '../utils/json_utils.dart';

class FoundationPile {
  Suit? suit;
  List<Card> cards = [];

  Map<String, dynamic> toJson() => {
    'suit': suit?.toString(),
    'cards': cards.map((card) => card.toJson()).toList(),
  };

  static FoundationPile fromJson(Map<String, dynamic> json) {
    final suitString = json['suit'] as String?;
    Suit? parsedSuit;
    if (suitString != null) {
      for (final suit in Suit.values) {
        if (suit.toString() == suitString) {
          parsedSuit = suit;
          break;
        }
      }
    }
    final pile = FoundationPile(
      suit: parsedSuit,
    );
    if (json.containsKey('cards') && json['cards'] != null) {
      pile.cards = normalizeMapList(json['cards'])
          .map((card) => Card.fromJson(card))
          .toList();
    }
    if (pile.suit == null && pile.cards.isNotEmpty) {
      pile.suit = pile.cards.first.suit;
    }
    return pile;
  }

  FoundationPile({this.suit});

  bool canAcceptCard(Card card) {
    if (cards.isEmpty) {
      if (suit == null) {
        return card.rank == Rank.ace;
      }
      return card.rank == Rank.ace && card.suit == suit;
    }
    if (suit != null && card.suit != suit) return false;
    final topCard = cards.last;
    return card.canPlaceOnFoundation(topCard);
  }

  void addCard(Card card) {
    if (cards.isEmpty && suit == null) {
      suit = card.suit;
    }
    cards.add(card);
  }

  Card? get topCard => cards.isNotEmpty ? cards.last : null;

  bool get isEmpty => cards.isEmpty;

  bool get isComplete => cards.length == 13; // All ranks

  @override
  String toString() {
    final suitLabel = suit?.name ?? 'unassigned';
    return 'FoundationPile($suitLabel: ${cards.length} cards)';
  }
}