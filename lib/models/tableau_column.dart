import 'card.dart';
import '../utils/json_utils.dart';
import 'package:flutter/foundation.dart' show debugPrint;

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
    try {
      final inferredIndex = json['columnIndex'] ?? json['index'];
      final columnIndex = inferredIndex is int
          ? inferredIndex
          : int.tryParse(inferredIndex?.toString() ?? '') ?? fallbackIndex;

      final column = TableauColumn(columnIndex: columnIndex);
      if (json.containsKey('cards') && json['cards'] != null) {
        final cardsData = json['cards'];
        debugPrint('  📋 TABLEAUCOLUMN $columnIndex fromJson: cards field type = ${cardsData.runtimeType}');
        
        column.cards = normalizeMapList(cardsData)
            .map((card) => Card.fromJson(card))
            .toList();
        
        debugPrint('  📋 TABLEAUCOLUMN $columnIndex fromJson: Loaded ${column.cards.length} cards');
      }

      return column;
    } catch (e, stackTrace) {
      debugPrint('  ❌ TABLEAUCOLUMN fromJson ERROR: $e');
      debugPrint('     Input JSON: ${json.toString().substring(0, 200)}...');
      debugPrint('     Stack trace: $stackTrace');
      rethrow;
    }
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