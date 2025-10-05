import 'dart:math';
import 'card.dart';
import '../utils/json_utils.dart';
import 'package:flutter/foundation.dart';

class Deck {
  List<Card> _cards = [];

  Map<String, dynamic> toJson() => {
    'cards': _cards.map((card) => card.toJson()).toList(),
  };

  static Deck fromJson(Map<String, dynamic> json) {
    // Use named constructor to avoid initializing a full deck
    final deck = Deck._empty();
    if (json.containsKey('cards') && json['cards'] != null) {
      final normalizedCards = normalizeMapList(json['cards']);
      deck._cards = normalizedCards
          .map((card) => Card.fromJson(card))
          .toList();
      debugPrint('  📦 DECK fromJson: Loaded ${deck._cards.length} cards from JSON');
    } else {
      debugPrint('  ⚠️  DECK fromJson: No cards in JSON, deck will be empty');
    }
    return deck;
  }

  // Private constructor for deserialization that doesn't initialize cards
  Deck._empty();

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

  /// Shuffles the deck using optional string seed for determinism.
  /// In multiplayer, the same seed (synced via Firebase GameState) ensures all players
  /// initialize with identical deck order, enabling consistent game deals.
  void shuffle([String? seed]) {
    final random = seed != null ? Random(_stringToIntHash(seed)) : Random();
    _cards.shuffle(random);
  }

  /// Converts a string seed to an integer hash for deterministic Random initialization.
  int _stringToIntHash(String seed) {
    int seedInt = 0;
    for (int i = 0; i < seed.length; i++) {
      seedInt = seedInt * 31 + seed.codeUnitAt(i);
    }
    return seedInt;
  }

  Card? drawCard() {
    if (_cards.isEmpty) return null;
    return _cards.removeLast();
  }

  bool get isEmpty => _cards.isEmpty;

  int get length => _cards.length;

  void reset({String? seed}) {
    _initializeDeck();
    shuffle(seed);
  }

  void addCards(List<Card> cards) {
    final beforeCount = _cards.length;
    debugPrint('  📥 DECK addCards: Adding ${cards.length} cards to deck (current size=$beforeCount)');
    
    for (var card in cards) {
      card.faceUp = false;
      _cards.add(card);
    }
    
    debugPrint('  📥 DECK addCards: Complete (new size=${_cards.length})');
  }

  List<Card> get cards => List.unmodifiable(_cards);

  // For debugging
  @override
  String toString() {
    return 'Deck(${_cards.length} cards)';
  }
}