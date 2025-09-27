enum Suit { hearts, diamonds, clubs, spades }

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

  bool get isRed => suit == Suit.hearts || suit == Suit.diamonds;
  bool get isBlack => !isRed;

  int get rankValue => rank.index + 1; // ace=1, king=13

  bool canStackOn(Card other) {
    // For tableau: alternating colors, descending rank
    return isRed != other.isRed && rankValue == other.rankValue - 1;
  }

  bool canPlaceOnFoundation(Card other) {
    // For foundation: same suit, ascending rank
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