import 'card.dart';
import '../utils/json_utils.dart';

class TableauColumn {
  List<Card> cards = [];

  Map<String, dynamic> toJson() {
    final json = {
      'cards': cards.map((card) => card.toJson()).toList(),
    };
    
    return json;
  }

  static TableauColumn fromJson(Map<String, dynamic> json) {
    final column = TableauColumn();
    if (json.containsKey('cards') && json['cards'] != null) {
      column.cards = normalizeMapList(json['cards'])
          .map((card) => Card.fromJson(card))
          .toList();
    }

    return column;
  }

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