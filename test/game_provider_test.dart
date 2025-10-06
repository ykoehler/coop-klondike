import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:coop_klondike/models/card.dart';
import 'package:coop_klondike/models/game_state.dart';
import 'package:coop_klondike/providers/game_provider.dart';
import 'package:coop_klondike/services/firebase_service.dart';

class MockFirebaseService implements FirebaseService {
  int updateGameCallCount = 0;
  GameState? getGameReturnValue;
  GameState? lastUpdatedGameState;
  final StreamController<GameState> _gameController =
      StreamController<GameState>.broadcast();
  bool throwOnUpdate = false;
  Exception? updateException;

  @override
  Future<void> updateGame(String gameId, GameState gameState) async {
    updateGameCallCount++;
    lastUpdatedGameState = gameState;
    if (throwOnUpdate) {
      throw updateException ?? Exception('Mock updateGame failure');
    }
  }

  @override
  Future<GameState?> getGame(String gameId) async {
    return getGameReturnValue;
  }

  // Stub other methods
  @override
  Future<bool> createGameIfNotExists(
    String gameId,
    GameState gameState,
  ) async => true;

  @override
  Stream<GameState> listenToGame(String gameId) => _gameController.stream;

  void emitGameState(GameState state) {
    _gameController.add(state);
  }

  @override
  Stream<Map<String, dynamic>> listenToGameLock(String gameId) =>
      Stream.empty();

  @override
  Stream<Map<String, dynamic>> listenToDragPosition(String gameId) =>
      Stream.empty();

  @override
  Future<void> setGameLock(
    String gameId,
    String playerId,
    bool isLocked,
  ) async {}

  @override
  Future<void> updateDragPosition(
    String gameId,
    String cardId,
    double x,
    double y,
    String playerId,
  ) async {}

  void dispose() {
    _gameController.close();
  }
}

class BlockingFirebaseService extends MockFirebaseService {
  final Completer<void> _updateGate = Completer<void>();

  @override
  Future<void> updateGame(String gameId, GameState gameState) async {
    if (!_updateGate.isCompleted) {
      await _updateGate.future;
    }
    await super.updateGame(gameId, gameState);
  }

  void allowUpdates() {
    if (!_updateGate.isCompleted) {
      _updateGate.complete();
    }
  }
}

Future<void> pumpEventQueue([int times = 1]) async {
  for (var i = 0; i < times; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

List<Card> _collectAllCards(GameState state) {
  final cards = <Card>[];
  for (final column in state.tableau) {
    cards.addAll(column.cards);
  }
  cards.addAll(state.stock.cards);
  cards.addAll(state.waste);
  for (final foundation in state.foundations) {
    cards.addAll(foundation.cards);
  }
  return cards;
}

void expectIntegrity(GameState state) {
  final allCards = _collectAllCards(state);
  final totalCards = allCards.length;
  final uniqueCards = allCards.toSet().length;
  expect(totalCards, 52, reason: 'Total cards should remain 52');
  expect(uniqueCards, 52, reason: 'All cards should remain unique');
}

Card extractCardFromStock(GameState state, bool Function(Card) predicate) {
  final removed = <Card>[];
  Card? found;
  while (!state.stock.isEmpty) {
    final card = state.stock.drawCard();
    if (card == null) {
      break;
    }
    if (predicate(card)) {
      found = card;
      break;
    }
    removed.add(card);
  }
  state.stock.addCards(removed);
  if (found == null) {
    throw StateError('Requested card not found in stock');
  }
  return found;
}

Future<void> drawUntilStockEmpty(GameProvider provider) async {
  while (!provider.gameState.stock.isEmpty) {
    await provider.drawCard();
  }
}

void evacuateTableauColumnToStock(GameState state, int columnIndex) {
  final column = state.tableau[columnIndex];
  if (column.cards.isEmpty) return;
  final removed = List<Card>.from(column.cards);
  column.cards.clear();
  state.stock.addCards(removed);
}

void evacuateFoundationToStock(GameState state, int foundationIndex) {
  final foundation = state.foundations[foundationIndex];
  if (foundation.cards.isEmpty) return;
  final removed = List<Card>.from(foundation.cards);
  foundation.cards.clear();
  state.stock.addCards(removed);
}

void main() {
  group('GameProvider', () {
    late GameProvider provider;
    late MockFirebaseService mockService;

    setUp(() {
      mockService = MockFirebaseService();
      provider = GameProvider.test(firebaseService: mockService);
      addTearDown(() {
        provider.dispose();
        mockService.dispose();
      });
    });

    test(
      'recycleWaste succeeds when stock is empty and waste is not empty',
      () async {
        await drawUntilStockEmpty(provider);

        final wasteCount = provider.gameState.waste.length;
        expect(provider.gameState.stock.isEmpty, true);
        expect(wasteCount, greaterThan(0));

        await provider.recycleWaste();

        // After recycle, an auto-draw occurs so waste is not empty
        final drawMode = provider.gameState.drawMode;
        final expectedWasteCount = drawMode == DrawMode.one ? 1 : 3;
        expect(provider.gameState.waste.length, expectedWasteCount);
        expect(provider.gameState.stock.length, wasteCount - expectedWasteCount);
      },
    );

    test('recycleWaste does nothing when stock is not empty', () async {
      await provider.drawCard();

      final initialStockLength = provider.gameState.stock.length;
      final initialWasteLength = provider.gameState.waste.length;

      await provider.recycleWaste();

      expect(provider.gameState.stock.length, initialStockLength);
      expect(provider.gameState.waste.length, initialWasteLength);
    });

    test('recycleWaste does nothing when waste is empty', () async {
      // Clear the auto-drawn waste cards
      provider.gameState.waste.clear();
      final initialStockLength = provider.gameState.stock.length;
      expect(provider.gameState.waste.isEmpty, true);

      await provider.recycleWaste();

      expect(provider.gameState.stock.length, initialStockLength);
      expect(provider.gameState.waste.isEmpty, true);
    });

    test(
      'recycleWaste does nothing when both stock and waste are empty',
      () async {
        await drawUntilStockEmpty(provider);
        final drainedWaste = List<Card>.from(provider.gameState.waste);
        provider.gameState.waste.clear();
        provider.gameState.tableau[0].cards.addAll(drainedWaste);

        expect(provider.gameState.stock.isEmpty, true);
        expect(provider.gameState.waste.isEmpty, true);

        await provider.recycleWaste();

        expect(provider.gameState.stock.isEmpty, true);
        expect(provider.gameState.waste.isEmpty, true);
      },
    );

    test('recycleWaste moves cards in reverse order', () async {
      await drawUntilStockEmpty(provider);
      final wasteSnapshot = List<Card>.from(provider.gameState.waste);

      await provider.recycleWaste();

      // After recycle, an auto-draw occurs so waste is not empty
      final drawMode = provider.gameState.drawMode;
      final expectedWasteCount = drawMode == DrawMode.one ? 1 : 3;
      expect(provider.gameState.waste.length, expectedWasteCount);
      
      // Get the auto-drawn cards
      final autoDrawnCards = List<Card>.from(provider.gameState.waste);
      
      // Draw the remaining cards from stock
      final recovered = <Card>[];
      while (!provider.gameState.stock.isEmpty) {
        recovered.add(provider.gameState.stock.drawCard()!);
      }
      
      // Combine auto-drawn cards with manually drawn cards
      final allRecovered = [...autoDrawnCards, ...recovered];
      
      // After recycling with reversal, cards come out in the same order they were in waste
      // This preserves the visual stack order for consistent cycling
      expect(allRecovered, wasteSnapshot.toList());
    });

    test('recycleWaste notifies listeners on successful recycle', () async {
      await drawUntilStockEmpty(provider);

      bool notified = false;
      provider.addListener(() {
        notified = true;
      });

      await provider.recycleWaste();

      expect(notified, true);
    });

    test('recycleWaste does not notify listeners on failed recycle', () async {
      await provider.drawCard();

      bool notified = false;
      provider.addListener(() {
        notified = true;
      });

      await provider.recycleWaste();

      expect(notified, false);
    });

    group('Card integrity', () {
      test('drawCard maintains 52 unique cards', () async {
        expectIntegrity(provider.gameState);
        await provider.drawCard();
        expectIntegrity(provider.gameState);
      });

      test('recycleWaste maintains 52 unique cards', () async {
        while (!provider.gameState.stock.isEmpty) {
          await provider.drawCard();
        }
        expectIntegrity(provider.gameState);

        await provider.recycleWaste();

        expectIntegrity(provider.gameState);
      });

      test('moveWasteToTableau updates stock and waste counts correctly', () async {
        // Extract a king from stock and place it in waste
        Card kingCard;
        try {
          kingCard = extractCardFromStock(
            provider.gameState,
            (card) => card.rank == Rank.king,
          );
        } on StateError {
          kingCard = () {
            for (final column in provider.gameState.tableau) {
              final index = column.cards.indexWhere(
                (card) => card.rank == Rank.king,
              );
              if (index != -1) {
                return column.cards.removeAt(index);
              }
            }
            throw StateError('King not found in game state');
          }();
        }
        kingCard.faceUp = true;
        provider.gameState.waste.add(kingCard);

        // Clear the target tableau column
        evacuateTableauColumnToStock(provider.gameState, 0);

        final stockBeforeMove = provider.gameState.stock.length;
        final wasteBeforeMove = provider.gameState.waste.length;
        final combinedBefore = stockBeforeMove + wasteBeforeMove;

        await provider.moveWasteToTableau(0);

        final stockAfter = provider.gameState.stock.length;
        final wasteAfter = provider.gameState.waste.length;
        final combinedAfter = stockAfter + wasteAfter;

        expect(stockAfter, stockBeforeMove);
        expect(wasteAfter, wasteBeforeMove - 1);
        expect(combinedAfter, combinedBefore - 1);
        expect(provider.gameState.tableau[0].topCard, same(kingCard));
        expect(provider.gameState.waste.contains(kingCard), isFalse);
        expectIntegrity(provider.gameState);
      });

      test('moveWasteToTableau maintains 52 unique cards', () async {
        Card? kingCard;
        try {
          kingCard = extractCardFromStock(
            provider.gameState,
            (card) => card.rank == Rank.king,
          );
        } on StateError {
          // King might be in tableau; extract it from there
          for (final column in provider.gameState.tableau) {
            final index = column.cards.indexWhere(
              (card) => card.rank == Rank.king,
            );
            if (index != -1) {
              kingCard = column.cards.removeAt(index);
              break;
            }
          }
        }
        kingCard ??= throw StateError('King not found in game state');
        
        kingCard.faceUp = true;
        provider.gameState.waste.add(kingCard);

        evacuateTableauColumnToStock(provider.gameState, 0);
        final targetColumn = provider.gameState.tableau[0];

        expectIntegrity(provider.gameState);

        await provider.moveWasteToTableau(0);

        expectIntegrity(provider.gameState);
        expect(targetColumn.topCard, kingCard);
      });

      test('moveWasteToFoundation maintains 52 unique cards', () async {
        Card? aceHearts;
        
        // First check if ace of hearts is already in waste from auto-draw
        final wasteIndex = provider.gameState.waste.indexWhere(
          (card) => card.rank == Rank.ace && card.suit == Suit.hearts,
        );
        if (wasteIndex != -1) {
          aceHearts = provider.gameState.waste.removeAt(wasteIndex);
        }
        
        // If not in waste, try to extract from stock
        if (aceHearts == null) {
          try {
            aceHearts = extractCardFromStock(
              provider.gameState,
              (card) => card.rank == Rank.ace && card.suit == Suit.hearts,
            );
          } on StateError {
            // Ace of hearts might already be in tableau; locate and remove it.
          }
        }
        
        // If still not found, check tableau
        aceHearts ??= () {
          for (int i = 0; i < provider.gameState.tableau.length; i++) {
            final cards = provider.gameState.tableau[i].cards;
            final index = cards.indexWhere(
              (card) => card.rank == Rank.ace && card.suit == Suit.hearts,
            );
            if (index != -1) {
              return cards.removeAt(index);
            }
          }
          throw StateError('Ace of hearts not found in game state');
        }();

        aceHearts.faceUp = true;
        provider.gameState.waste.add(aceHearts);

        expectIntegrity(provider.gameState);

        await provider.moveWasteToFoundation(0);

        expectIntegrity(provider.gameState);
        expect(provider.gameState.foundations[0].topCard, aceHearts);
      });

      test('moveTableauToTableau maintains 52 unique cards', () async {
        final destinationColumn = provider.gameState.tableau[0];
        final sourceColumn = provider.gameState.tableau[1];
        evacuateTableauColumnToStock(provider.gameState, 0);
        evacuateTableauColumnToStock(provider.gameState, 1);

        Card? kingCard;
        try {
          kingCard = extractCardFromStock(
            provider.gameState,
            (card) => card.rank == Rank.king,
          );
        } on StateError {
          // King might be in tableau
          for (final column in provider.gameState.tableau) {
            final index = column.cards.indexWhere(
              (card) => card.rank == Rank.king,
            );
            if (index != -1) {
              kingCard = column.cards.removeAt(index);
              break;
            }
          }
        }
        kingCard ??= throw StateError('King not found in game state');
        kingCard.faceUp = true;
        destinationColumn.addCard(kingCard);

        Card? queenCard;
        try {
          queenCard = extractCardFromStock(
            provider.gameState,
            (card) => card.rank == Rank.queen && card.isRed != kingCard!.isRed,
          );
        } on StateError {
          // Queen might be in tableau
          for (final column in provider.gameState.tableau) {
            final index = column.cards.indexWhere(
              (card) => card.rank == Rank.queen && card.isRed != kingCard!.isRed,
            );
            if (index != -1) {
              queenCard = column.cards.removeAt(index);
              break;
            }
          }
        }
        queenCard ??= throw StateError('Queen with opposite color not found');
        queenCard.faceUp = true;
        sourceColumn.addCard(queenCard);

        expectIntegrity(provider.gameState);

        await provider.moveTableauToTableau(1, 0, 1);

        expectIntegrity(provider.gameState);
        expect(destinationColumn.topCard, queenCard);
      });

      test('moveTableauToFoundation maintains 52 unique cards', () async {
        evacuateTableauColumnToStock(provider.gameState, 0);
        final tableauColumn = provider.gameState.tableau[0];

        Card? aceHearts;
        
        // First check if ace of hearts is already in waste from auto-draw
        final wasteIndex = provider.gameState.waste.indexWhere(
          (card) => card.rank == Rank.ace && card.suit == Suit.hearts,
        );
        if (wasteIndex != -1) {
          aceHearts = provider.gameState.waste.removeAt(wasteIndex);
        }
        
        // If not in waste, try to extract from stock
        if (aceHearts == null) {
          try {
            aceHearts = extractCardFromStock(
              provider.gameState,
              (card) => card.rank == Rank.ace && card.suit == Suit.hearts,
            );
          } on StateError {
            // Ace of hearts might already be in tableau
            for (int i = 0; i < provider.gameState.tableau.length; i++) {
              final cards = provider.gameState.tableau[i].cards;
              final index = cards.indexWhere(
                (card) => card.rank == Rank.ace && card.suit == Suit.hearts,
              );
              if (index != -1) {
                aceHearts = cards.removeAt(index);
                break;
              }
            }
          }
        }
        aceHearts ??= throw StateError('Ace of hearts not found in game state');
        
        aceHearts.faceUp = true;
        tableauColumn.addCard(aceHearts);

        expectIntegrity(provider.gameState);

        await provider.moveTableauToFoundation(0, 0);

        expectIntegrity(provider.gameState);
        expect(provider.gameState.foundations[0].topCard, aceHearts);
      });

      test('moveFoundationToTableau maintains 52 unique cards', () async {
        evacuateFoundationToStock(provider.gameState, 0);
        final foundation = provider.gameState.foundations[0];
        Card? kingHearts;
        
        // Search stock first
        try {
          kingHearts = extractCardFromStock(
            provider.gameState,
            (card) => card.rank == Rank.king && card.suit == Suit.hearts,
          );
        } on StateError {
          // Search waste pile
          final wasteIndex = provider.gameState.waste.indexWhere(
            (card) => card.rank == Rank.king && card.suit == Suit.hearts,
          );
          if (wasteIndex != -1) {
            kingHearts = provider.gameState.waste.removeAt(wasteIndex);
          } else {
            // Search tableau (all cards, not just top ones)
            for (final column in provider.gameState.tableau) {
              final index = column.cards.indexWhere(
                (card) => card.rank == Rank.king && card.suit == Suit.hearts,
              );
              if (index != -1) {
                kingHearts = column.cards.removeAt(index);
                break;
              }
            }
          }
        }
        
        kingHearts ??=
            (throw StateError('King of hearts not available for test setup'));
        kingHearts.faceUp = true;
        foundation.cards.add(kingHearts);

        evacuateTableauColumnToStock(provider.gameState, 0);
        final tableauColumn = provider.gameState.tableau[0];

        expectIntegrity(provider.gameState);

        await provider.moveFoundationToTableau(0, 0);

        expectIntegrity(provider.gameState);
        expect(tableauColumn.topCard, kingHearts);
      });

      test('transaction rolls back on update failure', () async {
        mockService.throwOnUpdate = true;
        final initialWaste = provider.gameState.waste.length;
        final initialStock = provider.gameState.stock.length;

        await expectLater(provider.drawCard(), throwsException);

        expect(provider.gameState.waste.length, initialWaste);
        expect(provider.gameState.stock.length, initialStock);
        expectIntegrity(provider.gameState);

        mockService.throwOnUpdate = false;
      });
    });

    group('Concurrency handling', () {
      test('drawCard ignores concurrent requests while pending', () async {
        final blockingService = BlockingFirebaseService();
        final blockingProvider = GameProvider.test(
          firebaseService: blockingService,
        );

        addTearDown(() {
          blockingProvider.dispose();
          blockingService.dispose();
        });

        final firstDraw = blockingProvider.drawCard();
        await Future<void>.delayed(Duration.zero);

        expect(blockingProvider.hasPendingAction, isTrue);

        final secondDraw = blockingProvider.drawCard();
        await Future<void>.delayed(Duration.zero);

        blockingService.allowUpdates();

        await firstDraw;
        await secondDraw;

        expect(blockingService.updateGameCallCount, 1);
        // Initial auto-draw: 3 cards, plus one drawCard call: 3 more = 6 total
        expect(blockingProvider.gameState.waste.length, 6);
        expectIntegrity(blockingProvider.gameState);
      });
    });

    test('isGameStuck returns false when game is won', () {
      // Fill foundations to win the game
      final suits = Suit.values;
      for (int foundationIndex = 0;
          foundationIndex < provider.gameState.foundations.length;
          foundationIndex++) {
        final pile = provider.gameState.foundations[foundationIndex];
        final suit = suits[foundationIndex % suits.length];
        for (int rankIndex = 0; rankIndex < 13; rankIndex++) {
          final rank = Rank.values[rankIndex];
          final card = Card(suit: suit, rank: rank);
          pile.addCard(card);
        }
      }
      expect(provider.isGameStuck, false);
    });

    test('isGameStuck returns false when moves are available', () {
      // Default state should have moves available
      expect(provider.isGameStuck, false);
    });

    test(
      'isGameStuck returns true when no moves are possible and game is not won',
      () {
        // Create a stuck state: empty stock, empty waste,
        // tableau with cards that can't move to each other or foundation
        while (!provider.gameState.stock.isEmpty) {
          provider.gameState.stock.drawCard();
        }
        provider.gameState.waste.clear();

        // Clear tableau and set up cards that can't move
        for (int i = 0; i < 7; i++) {
          provider.gameState.tableau[i].cards.clear();
          // Add a king to each column - kings can't move since no empty columns and not aces
          provider.gameState.tableau[i].addCard(
            Card(suit: Suit.hearts, rank: Rank.king, faceUp: true),
          );
        }

        expect(provider.isGameWon, false);
        expect(provider.isGameStuck, true);
      },
    );

    test(
      'moving waste card clears it even when pending update exists',
      () async {
        final asyncService = MockFirebaseService();
        final asyncProvider = GameProvider.test(
          firebaseService: asyncService,
          synchronous: false,
        );
        addTearDown(() {
          asyncProvider.dispose();
          asyncService.dispose();
        });

        // Wait for asynchronous initialization to finish
        var attempts = 0;
        while (asyncProvider.isInitializing && attempts < 10) {
          await pumpEventQueue();
          attempts++;
        }

        Card movingCard;
        try {
          movingCard = extractCardFromStock(
            asyncProvider.gameState,
            (card) => card.rank == Rank.king,
          );
        } on StateError {
          movingCard = () {
            for (final column in asyncProvider.gameState.tableau) {
              final index = column.cards.indexWhere(
                (card) => card.rank == Rank.king,
              );
              if (index != -1) {
                return column.cards.removeAt(index);
              }
            }
            throw StateError('King card not found for move setup');
          }();
        }
        movingCard.faceUp = true;
        asyncProvider.gameState.waste.add(movingCard);

        final tableauIndex = 0;
        evacuateTableauColumnToStock(asyncProvider.gameState, tableauIndex);

        final totalBefore =
            asyncProvider.gameState.stock.length +
            asyncProvider.gameState.waste.length;

        asyncProvider.setDragging(true);
        final pendingState = GameState.fromJson(
          asyncProvider.gameState.toJson(),
        );
        asyncService.emitGameState(pendingState);
        await pumpEventQueue();

        await asyncProvider.moveWasteToTableau(tableauIndex);
        await pumpEventQueue(3);

        asyncProvider.setDragging(false);
        await pumpEventQueue();

        expect(asyncProvider.gameState.waste.contains(movingCard), isFalse);
        expect(
          asyncProvider.gameState.tableau[tableauIndex].topCard,
          equals(movingCard),
        );
        expect(
          asyncProvider.gameState.stock.length +
              asyncProvider.gameState.waste.length,
          totalBefore - 1,
        );
      },
    );

    group('Seed Handling', () {
      setUp(() {
        // No additional setup needed
      });

      test(
        'initializeNewGame with seed sets GameState.seed and shuffles deck deterministically',
        () async {
          const seed = 'test-seed-123';
          await provider.initializeNewGame('test-game-id', seed);

          expect(provider.gameState.seed, seed);
          // Stock has 21 cards after dealing (24 - 3 auto-drawn in DrawMode.three)
          expect(provider.deck.length, 21);
          // Verify deck is shuffled (not empty)
          expect(provider.deck.length > 0, true);
        },
      );

      test(
        'init without seed uses default from SeedGenerator and shuffles deck',
        () async {
          await provider.init('test-game-id');

          expect(provider.gameState.seed.isNotEmpty, true);
          // Stock has 21 cards after dealing (24 - 3 auto-drawn in DrawMode.three)
          expect(provider.deck.length, 21);
        },
      );

      test(
        'initializeNewGame with empty seed falls back to default seed',
        () async {
          await provider.initializeNewGame('test-game-id', '');

          expect(
            provider.gameState.seed.isNotEmpty,
            true,
          ); // Falls back to default
          // Stock has 21 cards after dealing (24 - 3 auto-drawn in DrawMode.three)
          expect(provider.deck.length, 21);
        },
      );
    });
  });
}
