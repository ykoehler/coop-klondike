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
  bool existsInFirebase = false;

  Map<String, dynamic> toJson() {
    print('=== GAMESTATE SERIALIZATION ===');
    print('GameId: $gameId');
    print('Tableau columns: ${tableau.length}');
    for (int i = 0; i < tableau.length; i++) {
      print('Tableau Column $i serialization: ${tableau[i].cards.length} cards');
      for (int j = 0; j < tableau[i].cards.length; j++) {
        final card = tableau[i].cards[j];
        print('  Serializing Card $j: ${card.suit} ${card.rank} (faceUp: ${card.faceUp})');
      }
    }
    
    final json = {
      'tableau': tableau.map((column) => column.toJson()).toList(),
      'foundations': foundations.map((pile) => pile.toJson()).toList(),
      'stock': stock.toJson(),
      'waste': waste.map((card) => card.toJson()).toList(),
      'drawMode': drawMode.toString(),
      'gameId': gameId,
      'existsInFirebase': existsInFirebase,
    };
    
    print('Serialized JSON tableau length: ${(json['tableau'] as List).length}');
    print('=== END GAMESTATE SERIALIZATION ===');
    return json;
  }

  static GameState fromJson(Map<String, dynamic> json) {
    print('=== GAMESTATE DESERIALIZATION ===');
    print('Received JSON gameId: ${json['gameId']}');
    print('Received JSON tableau length: ${(json['tableau'] as List?)?.length}');
    
    final gameState = GameState(
      gameId: json['gameId'] as String,
      drawMode: DrawMode.values.firstWhere(
        (mode) => mode.toString() == json['drawMode'],
        orElse: () => DrawMode.three,
      ),
    );
    gameState.existsInFirebase = true;

    try {
      final tableauJson = json['tableau'] as List?;
      if (tableauJson != null) {
        print('Deserializing ${tableauJson.length} tableau columns');
        gameState.tableau = tableauJson
            .map((column) => TableauColumn.fromJson(column as Map<String, dynamic>))
            .toList();
            
        // Log deserialized tableau
        for (int i = 0; i < gameState.tableau.length; i++) {
          final column = gameState.tableau[i];
          print('Deserialized Tableau Column $i: ${column.cards.length} cards');
          for (int j = 0; j < column.cards.length; j++) {
            final card = column.cards[j];
            print('  Deserialized Card $j: ${card.suit} ${card.rank} (faceUp: ${card.faceUp})');
          }
        }
      }

      final foundationsJson = json['foundations'] as List?;
      if (foundationsJson != null) {
        gameState.foundations = foundationsJson
            .map((pile) => FoundationPile.fromJson(pile as Map<String, dynamic>))
            .toList();
      }

      final stockJson = json['stock'] as Map<String, dynamic>?;
      if (stockJson != null) {
        gameState.stock = Deck.fromJson(stockJson);
      }

      final wasteJson = json['waste'] as List?;
      if (wasteJson != null) {
        gameState.waste = wasteJson
            .map((card) => Card.fromJson(card as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Error parsing game state: $e');
      print('Stack trace: ${StackTrace.current}');
      // Initialize with default values if parsing fails
      gameState._dealNewGame(seed: gameState.gameId.hashCode);
    }

    print('=== END GAMESTATE DESERIALIZATION ===');
    return gameState;
  }

  GameState({this.drawMode = DrawMode.three, String? gameId, int? seed})
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