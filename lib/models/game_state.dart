import 'dart:math';
import 'card.dart';
import 'deck.dart';
import 'tableau_column.dart';
import 'foundation_pile.dart';

enum DrawMode { one, three }

class GameState {
  List<TableauColumn> tableau = List.generate(7, (_) => TableauColumn());
  List<FoundationPile> foundations = [
    FoundationPile(suit: Suit.hearts),
    FoundationPile(suit: Suit.diamonds),
    FoundationPile(suit: Suit.clubs),
    FoundationPile(suit: Suit.spades),
  ];
  Deck stock = Deck();
  List<Card> waste = [];
  late DrawMode drawMode;
  late String gameId;

  GameState({this.drawMode = DrawMode.one, String? gameId, int? seed})
      : gameId = gameId ?? _generateGameId() {
    _dealNewGame(seed: seed ?? this.gameId.hashCode);
  }

  static String _generateGameId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    String part1 = String.fromCharCodes(
      List.generate(5, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
    String part2 = String.fromCharCodes(
      List.generate(5, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
    return '$part1-$part2';
  }

  void _dealNewGame({int? seed}) {
    stock.reset(seed: seed);
    waste.clear();
    tableau = List.generate(7, (_) => TableauColumn());
    foundations = [
      FoundationPile(suit: Suit.hearts),
      FoundationPile(suit: Suit.diamonds),
      FoundationPile(suit: Suit.clubs),
      FoundationPile(suit: Suit.spades),
    ];

    // Deal to tableau
    for (int col = 0; col < 7; col++) {
      for (int row = 0; row <= col; row++) {
        final card = stock.drawCard();
        if (card != null) {
          tableau[col].addCard(card);
          if (row == col) {
            card.faceUp = true; // Top card face up
          }
        }
      }
    }
  }

  void newGame() {
    gameId = _generateGameId();
    _dealNewGame(seed: gameId.hashCode);
  }

  bool get isWon => foundations.every((pile) => pile.isComplete);

  @override
  String toString() {
    return 'GameState(tableau: ${tableau.length}, foundations: ${foundations.length}, stock: ${stock.length}, waste: ${waste.length}, drawMode: $drawMode, gameId: $gameId)';
  }
}