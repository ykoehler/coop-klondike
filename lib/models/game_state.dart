import 'dart:math';
import 'card.dart';
import 'deck.dart';
import 'tableau_column.dart';
import 'foundation_pile.dart';
import '../utils/json_utils.dart';
import '../utils/seed_generator.dart';
import 'package:flutter/foundation.dart';

enum DrawMode { one, three }

class GameState {
  List<TableauColumn> tableau = List.generate(7, (_) => TableauColumn());
  List<FoundationPile> foundations = List.generate(4, (_) => FoundationPile());
  Deck stock = Deck();
  List<Card> waste = [];
  late DrawMode drawMode;
  late String gameId;
  bool existsInFirebase = false;
  late String seed;

  Map<String, dynamic> toJson() {
    final json = {
      'tableau': tableau.map((column) => column.toJson()).toList(),
      'foundations': foundations.map((pile) => pile.toJson()).toList(),
      'stock': stock.toJson(),
      'waste': waste.map((card) => card.toJson()).toList(),
      'drawMode': drawMode.toString(),
      'gameId': gameId,
      'existsInFirebase': existsInFirebase,
      'seed': seed, // Synced via Firebase for multiplayer consistency
    };

    return json;
  }

  static GameState fromJson(Map<String, dynamic> json) {
    final gameState = GameState(
      gameId: json['gameId'] as String?,
      drawMode: DrawMode.values.firstWhere(
        (mode) => mode.toString() == json['drawMode'],
        orElse: () => DrawMode.three,
      ),
      seedStr: json['seed'] as String?,
    );
    gameState.existsInFirebase = true;

    try {
      final tableauRaw = json['tableau'];
      if (tableauRaw != null) {
        final tableauList = normalizeMapList(tableauRaw);
        final deserializedColumns = tableauList
            .map(
              (column) => TableauColumn.fromJson(column),
            )
            .toList();
        
        // Always ensure we have exactly 7 tableau columns
        // If deserialized data has fewer, fill with empty columns
        // If it has more, only take the first 7
        gameState.tableau = List.generate(7, (index) {
          if (index < deserializedColumns.length) {
            return deserializedColumns[index];
          } else {
            return TableauColumn();
          }
        });
      }

      final foundationsData = json['foundations'];
      if (foundationsData != null) {
        List<FoundationPile> parsedFoundations = [];

        if (foundationsData is List) {
          parsedFoundations = foundationsData.map((pile) {
            if (pile is Map<String, dynamic>) {
              return FoundationPile.fromJson(pile);
            } else if (pile is Map) {
              return FoundationPile.fromJson(
                Map<String, dynamic>.from(pile),
              );
            }
            return FoundationPile();
          }).toList();
        } else if (foundationsData is Map) {
          final indexedPiles = <int, FoundationPile>{};

          foundationsData.forEach((key, value) {
            final index = int.tryParse(key.toString());
            if (index == null || value is! Map) return;
            indexedPiles[index] = FoundationPile.fromJson(
              Map<String, dynamic>.from(value),
            );
          });

          if (indexedPiles.isNotEmpty) {
            final maxIndex = indexedPiles.keys.reduce((a, b) => a > b ? a : b);
            final targetLength = max(4, maxIndex + 1);
            parsedFoundations = List<FoundationPile>.generate(
              targetLength,
              (i) => indexedPiles[i] ?? FoundationPile(),
            );
          }
        }

        if (parsedFoundations.length > 4) {
          parsedFoundations = parsedFoundations.sublist(0, 4);
        }

        final normalizedLength = max(4, parsedFoundations.length);
        gameState.foundations = List<FoundationPile>.generate(
          normalizedLength,
          (i) => i < parsedFoundations.length
              ? parsedFoundations[i]
              : FoundationPile(),
        );
      } else {
        gameState.foundations =
            List<FoundationPile>.generate(4, (_) => FoundationPile());
      }

      final stockJson = json['stock'];
      if (stockJson != null && stockJson is Map<String, dynamic>) {
        gameState.stock = Deck.fromJson(stockJson);
      }

  if (json.containsKey('waste') && json['waste'] != null) {
    gameState.waste = normalizeMapList(json['waste'])
    .map((card) => Card.fromJson(card))
    .toList();
      }
    } catch (e) {
      // Log the error before redealing
      debugPrint('ERROR: Failed to deserialize GameState from JSON: $e');
      debugPrint('JSON data: $json');
      // Instead of redealing, rethrow the exception to let the caller handle it
      rethrow;
    }

    return gameState;
  }

  GameState({this.drawMode = DrawMode.three, String? gameId, String? seedStr})
    : gameId = gameId ?? _generateGameId() {
    seed = (seedStr != null && seedStr.isNotEmpty) ? seedStr : this.gameId;
    _dealNewGame(seed: seed);
  }

  static String _generateGameId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    String part1 = String.fromCharCodes(
      List.generate(5, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
    String part2 = String.fromCharCodes(
      List.generate(5, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
    return '$part1-$part2';
  }

  void _dealNewGame({String? seed}) {
    stock.reset(seed: seed);
    waste.clear();
    tableau = List.generate(7, (_) => TableauColumn());
    foundations = List.generate(4, (_) => FoundationPile());

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

    // Automatically draw cards from stock to waste based on draw mode
    // This provides a better starting position for the player
    final numToDraw = drawMode == DrawMode.one ? 1 : (stock.length < 3 ? stock.length : 3);
    for (int i = 0; i < numToDraw; i++) {
      final card = stock.drawCard();
      if (card != null) {
        card.faceUp = true;
        waste.add(card);
      }
    }

    // Log card distribution for debugging duplicate issues
    logState();
  }

  /// Logs the distribution of cards in stock and tableau columns for debugging
  /// This helps identify if duplicate cards are created during game setup
  void logState({String context = 'CARD DISTRIBUTION LOG'}) {
    final buffer = StringBuffer();
    buffer.writeln('=== $context ===');
    buffer.writeln('📍 STACK TRACE: ${StackTrace.current.toString().split('\n').take(3).join('\n')}');
    buffer.writeln('Game ID: $gameId');
    buffer.writeln('Seed: $seed');
    buffer.writeln('Draw Mode: $drawMode');
    buffer.writeln();

    // Log tableau columns
    buffer.writeln('TABLEAU COLUMNS:');
    for (int i = 0; i < tableau.length; i++) {
      buffer.write('Column ${i + 1}: ');
      final cards = tableau[i].cards;
      if (cards.isEmpty) {
        buffer.writeln('(empty)');
      } else {
        for (int j = 0; j < cards.length; j++) {
          final card = cards[j];
          final faceStatus = card.faceUp ? '↑' : '↓';
          buffer.write('$card$faceStatus');
          if (j < cards.length - 1) buffer.write(', ');
        }
        buffer.writeln();
      }
    }
    buffer.writeln();

    // Log stock
    buffer.writeln('STOCK:');
    final stockCards = stock.cards;
    if (stockCards.isEmpty) {
      buffer.writeln('(empty)');
    } else {
      for (int i = 0; i < stockCards.length; i++) {
        final card = stockCards[i];
        buffer.write('$card↓'); // All stock cards are face down
        if (i < stockCards.length - 1) buffer.write(', ');
        if ((i + 1) % 10 == 0) buffer.writeln(); // Line break every 10 cards
      }
      buffer.writeln();
    }
    buffer.writeln('Total stock cards: ${stockCards.length}');
    buffer.writeln();

    // Log waste (should be empty after dealing)
    buffer.writeln(
      'WASTE: ${waste.isEmpty ? "(empty)" : waste.map((c) => '$c↑').join(", ")}',
    );
    buffer.writeln();

    // Log foundations (should be empty after dealing)
    buffer.writeln('FOUNDATIONS:');
    for (int i = 0; i < foundations.length; i++) {
      final suitLabel = foundations[i].suit?.name ?? 'unassigned';
      buffer.writeln('  $suitLabel: (empty)');
    }
    buffer.writeln();

    // Summary statistics
    final allCards = <Card>[];
    for (final column in tableau) {
      allCards.addAll(column.cards);
    }
    allCards.addAll(stockCards);
    allCards.addAll(waste);
    for (final foundation in foundations) {
      allCards.addAll(foundation.cards);
    }

    buffer.writeln('SUMMARY:');
    buffer.writeln('Total cards dealt: ${allCards.length}');
    buffer.writeln(
      'Tableau cards: ${tableau.fold(0, (sum, col) => sum + col.cards.length)}',
    );
    buffer.writeln('Stock cards: ${stockCards.length}');
    buffer.writeln('Waste cards: ${waste.length}');
    buffer.writeln(
      'Foundation cards: ${foundations.fold(0, (sum, f) => sum + f.cards.length)}',
    );
    final uniqueCards = allCards.toSet().length;
    buffer.writeln('Unique cards: $uniqueCards');
    if (uniqueCards != allCards.length) {
      buffer.writeln('Duplicate card signatures detected:');
      final cardCounts = <String, int>{};
      for (final card in allCards) {
        final key = '${card.suit}-${card.rank}';
        cardCounts[key] = (cardCounts[key] ?? 0) + 1;
      }
      cardCounts.entries
          .where((entry) => entry.value > 1)
          .forEach(
            (entry) => buffer.writeln('  ${entry.key}: ${entry.value} copies'),
          );
    }
    buffer.writeln('================================');

    // Use debugPrint for Firebase-friendly logging
    debugPrint(buffer.toString());
  }

  void newGame() {
    gameId = _generateGameId();
    seed = SeedGenerator.generateSeed();
    _dealNewGame(seed: seed);
  }

  void redealWithSeed(String newSeed) {
    seed = newSeed;
    _dealNewGame(seed: seed);
  }

  bool get isWon => foundations.every((pile) => pile.isComplete);

  @override
  String toString() {
    return 'GameState(tableau: ${tableau.length}, foundations: ${foundations.length}, stock: ${stock.length}, waste: ${waste.length}, drawMode: $drawMode, gameId: $gameId)';
  }
}
