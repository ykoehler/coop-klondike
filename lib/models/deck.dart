import 'dart:math';
import 'card.dart';

class Deck {
  List<Card> _cards = [];

  Map<String, dynamic> toJson() => {
    'cards': _cards.map((card) => card.toJson()).toList(),
  };

  static Deck fromJson(Map<String, dynamic> json) {
    final deck = Deck();
    final cardsList = json['cards'] as List?;
    if (cardsList != null) {
      deck._cards = cardsList
          .map((card) => Card.fromJson(card as Map<String, dynamic>))
          .toList();
    } else {
      deck._initializeDeck();
    }
    return deck;
  }

  Deck() {
    _initializeDeck();
  }

  void _initializeDeck() {
    _cards = [];
    for (var suit in Suit.values) {
      for (var rank in Rank.values) {
        _cards.add(Card(suit: suit, rank: rank));
      }
    }
  }

  void shuffle([int? seed]) {
    final random = seed != null ? Random(seed) : Random();
    _cards.shuffle(random);
  }

  Card? drawCard() {
    if (_cards.isEmpty) return null;
    return _cards.removeLast();
  }

  bool get isEmpty => _cards.isEmpty;

  int get length => _cards.length;

  void reset({int? seed}) {
    _initializeDeck();
    shuffle(seed);
  }

  void addCards(List<Card> cards) {
    for (var card in cards) {
      card.faceUp = false;
    }
    _cards.addAll(cards);
  }

  // For debugging
  @override
  String toString() {
    return 'Deck(${_cards.length} cards)';
  }
}