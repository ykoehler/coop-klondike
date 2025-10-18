/// Represents the four suits in a standard deck of cards.
enum Suit { hearts, diamonds, clubs, spades }

/// Represents the 13 ranks in a standard deck of cards.
/// Order matters: Ace is lowest (1), King is highest (13).
enum Rank {
  ace,
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king
}

/// Represents a single card in the game.
/// 
/// Cards have a suit, rank, and visibility state (face-up/face-down).
/// They support Klondike solitaire-specific rules for stacking and foundation placement.
class Card {
  final Suit suit;
  final Rank rank;
  bool faceUp;

  Map<String, dynamic> toJson() => {
    'suit': suit.toString(),
    'rank': rank.toString(),
    'faceUp': faceUp,
  };

  static Card fromJson(Map<String, dynamic> json) => Card(
    suit: Suit.values.firstWhere((s) => s.toString() == json['suit']),
    rank: Rank.values.firstWhere((r) => r.toString() == json['rank']),
    faceUp: json['faceUp'] as bool,
  );

  Card({
    required this.suit,
    required this.rank,
    this.faceUp = false,
  });

  /// Returns true if this card is red (hearts or diamonds).
  bool get isRed => suit == Suit.hearts || suit == Suit.diamonds;

  /// Returns true if this card is black (clubs or spades).
  bool get isBlack => !isRed;

  /// Returns the numeric value of the rank (Ace=1, King=13).
  int get rankValue => rank.index + 1;

  /// Checks if this card can stack on another card in the tableau.
  /// 
  /// Tableau stacking rules:
  /// - Cards must alternate in color (red on black, black on red)
  /// - This card must be exactly one rank lower than the other
  /// - Example: 5♥ can stack on 6♠
  bool canStackOn(Card other) {
    return isRed != other.isRed && rankValue == other.rankValue - 1;
  }

  /// Checks if this card can be placed on another card in a foundation pile.
  /// 
  /// Foundation stacking rules:
  /// - Cards must be of the same suit
  /// - This card must be exactly one rank higher than the other
  /// - Example: 3♠ can be placed on 2♠
  bool canPlaceOnFoundation(Card other) {
    return suit == other.suit && rankValue == other.rankValue + 1;
  }

  @override
  String toString() {
    return '${rank.name}${suit.name[0].toUpperCase()}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Card &&
          runtimeType == other.runtimeType &&
          suit == other.suit &&
          rank == other.rank;

  @override
  int get hashCode => suit.hashCode ^ rank.hashCode;
}