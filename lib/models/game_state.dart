import 'card.dart';
import 'deck.dart';
import 'tableau_column.dart';
import 'foundation_pile.dart';

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

  GameState() {
    _dealNewGame();
  }

  void _dealNewGame() {
    stock.reset();
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
    _dealNewGame();
  }

  bool get isWon => foundations.every((pile) => pile.isComplete);

  @override
  String toString() {
    return 'GameState(tableau: ${tableau.length}, foundations: ${foundations.length}, stock: ${stock.length}, waste: ${waste.length})';
  }
}