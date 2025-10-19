import 'dart:math';
import 'card.dart';
import '../utils/json_utils.dart';
import 'package:flutter/foundation.dart';

/// Represents the stock pile in Klondike Solitaire.
/// 
/// The deck manages a collection of cards that can be:
/// - Shuffled (with optional seed for reproducible shuffles)
/// - Drawn one at a time
/// - Recycled from waste back to stock
/// 
/// For multiplayer games, the same seed ensures all players initialize
/// with the same card order, enabling consistent and fair gameplay.
class Deck {
  List<Card> _cards = [];

  Map<String, dynamic> toJson() => {
    'cards': _cards.map((card) => card.toJson()).toList(),
  };

  static Deck fromJson(Map<String, dynamic> json) {
    try {
      // Use named constructor to avoid initializing a full deck
      final deck = Deck._empty();
      if (json.containsKey('cards') && json['cards'] != null) {
        final cardsData = json['cards'];
        debugPrint('  📦 DECK fromJson: cards field type = ${cardsData.runtimeType}');
        
        final normalizedCards = normalizeMapList(cardsData);
        debugPrint('  📦 DECK fromJson: Normalized to ${normalizedCards.length} card(s)');
        
        deck._cards = normalizedCards
            .map((card) => Card.fromJson(card))
            .toList();
        debugPrint('  📦 DECK fromJson: Loaded ${deck._cards.length} cards from JSON');
      } else {
        debugPrint('  ⚠️  DECK fromJson: No cards in JSON, deck will be empty');
      }
      return deck;
    } catch (e, stackTrace) {
      debugPrint('  ❌ DECK fromJson ERROR: $e');
      debugPrint('     Input JSON keys: ${json.keys.toList()}');
      debugPrint('     Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Private constructor for deserialization that doesn't initialize cards
  Deck._empty();

  /// Creates a new shuffled deck with all 52 cards.
  Deck() {
    _initializeDeck();
  }

  /// Initializes the deck with all 52 unique cards (4 suits × 13 ranks).
  void _initializeDeck() {
    _cards = [];
    for (var suit in Suit.values) {
      for (var rank in Rank.values) {
        _cards.add(Card(suit: suit, rank: rank));
      }
    }
  }

  /// Shuffles the deck using an optional string seed for deterministic shuffling.
  /// 
  /// **Multiplayer Consideration**: In multiplayer games, the same seed
  /// (synced via Firebase in GameState) ensures all players initialize with
  /// identical deck order, enabling consistent game deals across all clients.
  /// 
  /// Parameters:
  ///   - `seed`: Optional string to seed the random number generator.
  ///     If provided, the same seed will always produce the same shuffle order.
  void shuffle([String? seed]) {
    final random = seed != null ? Random(_stringToIntHash(seed)) : Random();
    _cards.shuffle(random);
  }

  /// Converts a string seed to an integer hash for deterministic Random initialization.
  /// 
  /// Uses a simple polynomial rolling hash that produces consistent results
  /// across different Dart/Flutter versions and platforms.
  int _stringToIntHash(String seed) {
    int seedInt = 0;
    for (int i = 0; i < seed.length; i++) {
      seedInt = seedInt * 31 + seed.codeUnitAt(i);
    }
    return seedInt;
  }

  /// Removes and returns the last card from the deck (top of the stock).
  /// 
  /// Returns null if the deck is empty.
  Card? drawCard() {
    if (_cards.isEmpty) return null;
    return _cards.removeLast();
  }

  /// Returns true if the deck has no cards remaining.
  bool get isEmpty => _cards.isEmpty;

  /// Returns the number of cards currently in the deck.
  int get length => _cards.length;

  /// Resets the deck to a new shuffled state with all 52 cards.
  /// 
  /// Parameters:
  ///   - `seed`: Optional string to seed the shuffle for reproducibility.
  void reset({String? seed}) {
    _initializeDeck();
    shuffle(seed);
  }

  /// Adds multiple cards to the deck, setting them face-down.
  /// 
  /// Used when recycling waste pile back to stock.
  void addCards(List<Card> cards) {
    final beforeCount = _cards.length;
    debugPrint('  📥 DECK addCards: Adding ${cards.length} cards to deck (current size=$beforeCount)');
    
    for (var card in cards) {
      card.faceUp = false;
      _cards.add(card);
    }
    
    debugPrint('  📥 DECK addCards: Complete (new size=${_cards.length})');
  }

  /// Returns an unmodifiable view of all cards in the deck.
  List<Card> get cards => List.unmodifiable(_cards);

  @override
  String toString() {
    return 'Deck(${_cards.length} cards)';
  }
}