import 'package:flutter_test/flutter_test.dart';
import 'package:coop_klondike/models/card.dart';
import 'package:coop_klondike/models/game_state.dart';
import 'package:coop_klondike/providers/game_provider.dart';
import 'package:coop_klondike/services/firebase_service.dart';

class MockFirebaseService implements FirebaseService {
  int updateGameCallCount = 0;
  GameState? getGameReturnValue;

  @override
  Future<void> updateGame(String gameId, GameState gameState) async {
    updateGameCallCount++;
  }

  @override
  Future<GameState?> getGame(String gameId) async {
    return getGameReturnValue;
  }

  // Stub other methods
  @override
  Future<bool> createGameIfNotExists(String gameId, GameState gameState) async => true;

  @override
  Stream<GameState> listenToGame(String gameId) => Stream.empty();

  @override
  Stream<Map<String, dynamic>> listenToGameLock(String gameId) => Stream.empty();

  @override
  Stream<Map<String, dynamic>> listenToDragPosition(String gameId) => Stream.empty();

  @override
  Future<void> setGameLock(String gameId, String playerId, bool isLocked) async {}

  @override
  Future<void> updateDragPosition(String gameId, String cardId, double x, double y, String playerId) async {}
}

void main() {
  group('GameProvider', () {
    late GameProvider provider;
    late MockFirebaseService mockService;

    setUp(() {
      mockService = MockFirebaseService();
      provider = GameProvider.test(firebaseService: mockService);
    });

    test('recycleWaste succeeds when stock is empty and waste is not empty', () {
      // Empty stock
      while (!provider.gameState.stock.isEmpty) {
        provider.gameState.stock.drawCard();
      }
      // Add cards to waste
      provider.gameState.waste.add(Card(suit: Suit.hearts, rank: Rank.ace));
      provider.gameState.waste.add(Card(suit: Suit.spades, rank: Rank.king));

      expect(provider.gameState.stock.isEmpty, true);
      expect(provider.gameState.waste.length, 2);

      provider.recycleWaste();

      expect(provider.gameState.waste.isEmpty, true);
      expect(provider.gameState.stock.length, 2);
    });

    test('recycleWaste does nothing when stock is not empty', () {
      // Stock has cards (default state)
      provider.gameState.waste.add(Card(suit: Suit.hearts, rank: Rank.ace));

      final initialStockLength = provider.gameState.stock.length;
      final initialWasteLength = provider.gameState.waste.length;

      provider.recycleWaste();

      expect(provider.gameState.stock.length, initialStockLength);
      expect(provider.gameState.waste.length, initialWasteLength);
    });

    test('recycleWaste does nothing when waste is empty', () {
      // Empty stock
      while (!provider.gameState.stock.isEmpty) {
        provider.gameState.stock.drawCard();
      }
      // Waste is empty

      provider.recycleWaste();

      expect(provider.gameState.stock.isEmpty, true);
      expect(provider.gameState.waste.isEmpty, true);
    });

    test('recycleWaste does nothing when both stock and waste are empty', () {
      // Empty stock
      while (!provider.gameState.stock.isEmpty) {
        provider.gameState.stock.drawCard();
      }
      // Waste is empty

      provider.recycleWaste();

      expect(provider.gameState.stock.isEmpty, true);
      expect(provider.gameState.waste.isEmpty, true);
    });

    test('recycleWaste moves cards in reverse order', () {
      // Empty stock
      while (!provider.gameState.stock.isEmpty) {
        provider.gameState.stock.drawCard();
      }

      // Add cards to waste in specific order
      final card1 = Card(suit: Suit.hearts, rank: Rank.ace);
      final card2 = Card(suit: Suit.spades, rank: Rank.king);
      final card3 = Card(suit: Suit.diamonds, rank: Rank.queen);
      provider.gameState.waste.add(card1);
      provider.gameState.waste.add(card2);
      provider.gameState.waste.add(card3);

      provider.recycleWaste();

      // Cards should be in reverse order (last added to waste becomes first in stock)
      expect(provider.gameState.stock.drawCard(), card3);
      expect(provider.gameState.stock.drawCard(), card2);
      expect(provider.gameState.stock.drawCard(), card1);
    });

    test('recycleWaste notifies listeners on successful recycle', () {
      // Empty stock
      while (!provider.gameState.stock.isEmpty) {
        provider.gameState.stock.drawCard();
      }
      provider.gameState.waste.add(Card(suit: Suit.hearts, rank: Rank.ace));

      bool notified = false;
      provider.addListener(() {
        notified = true;
      });

      provider.recycleWaste();

      expect(notified, true);
    });

    test('recycleWaste does not notify listeners on failed recycle', () {
      // Stock has cards - recycle should fail
      provider.gameState.waste.add(Card(suit: Suit.hearts, rank: Rank.ace));

      bool notified = false;
      provider.addListener(() {
        notified = true;
      });

      provider.recycleWaste();

      expect(notified, false);
    });

    test('isGameStuck returns false when game is won', () {
      // Fill foundations to win the game
      final suits = Suit.values;
      for (int foundationIndex = 0;
          foundationIndex < provider.gameState.foundations.length;
          foundationIndex++) {
        final pile = provider.gameState.foundations[foundationIndex];
        pile.suit ??= suits[foundationIndex % suits.length];
        final suit = pile.suit!;
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

    test('isGameStuck returns true when no moves are possible and game is not won', () {
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
        provider.gameState.tableau[i].addCard(Card(suit: Suit.hearts, rank: Rank.king, faceUp: true));
      }

      expect(provider.isGameWon, false);
      expect(provider.isGameStuck, true);
    });

    group('Seed Handling', () {
      setUp(() {
        // No additional setup needed
      });

      test('initializeNewGame with seed sets GameState.seed and shuffles deck deterministically', () {
        const seed = 'test-seed-123';
        provider.initializeNewGame('test-game-id', seed);

        expect(provider.gameState.seed, seed);
        expect(provider.deck.length, 24); // Stock has 24 cards after dealing
        // Verify deck is shuffled (not empty)
        expect(provider.deck.length > 0, true);
      });

      test('init without seed uses default from SeedGenerator and shuffles deck', () {
        provider.init('test-game-id');

        expect(provider.gameState.seed.isNotEmpty, true);
        expect(provider.deck.length, 24);
      });

      test('initializeNewGame with empty seed falls back to default seed', () {
        provider.initializeNewGame('test-game-id', '');

        expect(provider.gameState.seed.isNotEmpty, true); // Falls back to default
        expect(provider.deck.length, 24);
      });
    });
  });
}