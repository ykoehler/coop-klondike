import 'card.dart';

class TableauColumn {
  List<Card> cards = [];

  Map<String, dynamic> toJson() {
    print('=== TABLEAU COLUMN SERIALIZATION ===');
    print('Column has ${cards.length} cards');
    for (int i = 0; i < cards.length; i++) {
      final card = cards[i];
      print('  Serializing column card $i: ${card.suit} ${card.rank} (faceUp: ${card.faceUp})');
    }
    
    final json = {
      'cards': cards.map((card) => card.toJson()).toList(),
    };
    
    print('Serialized column JSON cards length: ${(json['cards'] as List).length}');
    print('=== END TABLEAU COLUMN SERIALIZATION ===');
    return json;
  }

  static TableauColumn fromJson(Map<String, dynamic> json) {
    print('=== TABLEAU COLUMN DESERIALIZATION ===');
    final column = TableauColumn();
    final cardsList = json['cards'] as List?;
    print('Column JSON cards list length: ${cardsList?.length}');
    
    if (cardsList != null) {
      column.cards = cardsList
          .map((card) => Card.fromJson(card as Map<String, dynamic>))
          .toList();
          
      print('Deserialized column has ${column.cards.length} cards');
      for (int i = 0; i < column.cards.length; i++) {
        final card = column.cards[i];
        print('  Deserialized column card $i: ${card.suit} ${card.rank} (faceUp: ${card.faceUp})');
      }
    }
    
    print('=== END TABLEAU COLUMN DESERIALIZATION ===');
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