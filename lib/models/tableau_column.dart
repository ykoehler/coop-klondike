import 'card.dart';
import '../utils/json_utils.dart';

class TableauColumn {
  TableauColumn({this.columnIndex = 0, List<Card>? initialCards})
      : cards = initialCards ?? [];

  int columnIndex;
  List<Card> cards;

  Map<String, dynamic> toJson() {
    final json = {
      'columnIndex': columnIndex,
      'cards': cards.map((card) => card.toJson()).toList(),
    };

    return json;
  }

  static TableauColumn fromJson(
    Map<String, dynamic> json, {
    required int fallbackIndex,
  }) {
    final inferredIndex = json['columnIndex'] ?? json['index'];
    final columnIndex = inferredIndex is int
        ? inferredIndex
        : int.tryParse(inferredIndex?.toString() ?? '') ?? fallbackIndex;

    final column = TableauColumn(columnIndex: columnIndex);
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