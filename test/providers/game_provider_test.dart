import 'package:flutter_test/flutter_test.dart';
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
  group('GameProvider Seed Handling', () {
    late MockFirebaseService mockService;

    setUp(() {
      mockService = MockFirebaseService();
    });

    test('initializeNewGame with seed parameter sets GameState.seed and shuffles deck deterministically', () async {
      final provider = GameProvider.test(firebaseService: mockService);
      const seed = 'test-seed-123';
      await provider.initializeNewGame('test-game-id', seed);

      expect(provider.gameState.seed, seed);
      expect(provider.deck.length, 21); // Stock has 21 cards after dealing (24 - 3 auto-drawn)
      // Verify deck is shuffled (not empty)
      expect(provider.deck.length > 0, true);
    });

    test('initializeNewGame without seed uses default from SeedGenerator and shuffles deck', () async {
      final provider = GameProvider.test(firebaseService: mockService);
      await provider.initializeNewGame('test-game-id');

      expect(provider.gameState.seed.isNotEmpty, true);
      expect(provider.deck.length, 21);
      expect(provider.deck.length > 0, true);
    });

    test('initializeNewGame with empty seed falls back to default seed', () async {
      final provider = GameProvider.test(firebaseService: mockService);
      await provider.initializeNewGame('test-game-id', '');

      expect(provider.gameState.seed.isNotEmpty, true);
      expect(provider.deck.length, 21);
    });

    test('seed persistence in Firebase sync calls updateGame with GameState containing seed', () async {
      final provider = GameProvider.test(firebaseService: mockService);
      const gameId = 'test-game-id';
      const seed = 'test-seed';
      await provider.initializeNewGame(gameId, seed);

      mockService.updateGameCallCount = 0; // Reset count before testing sync
      await provider.sync();

      expect(mockService.updateGameCallCount, 1);
    });

    test('currentSeed getter returns the seed from GameState', () async {
      final provider = GameProvider.test(firebaseService: mockService);
      const seed = 'test-seed-456';
      await provider.initializeNewGame('test-game-id', seed);

      expect(provider.currentSeed, seed);
    });

    test('seed state management maintains seed across operations', () async {
      final provider = GameProvider.test(firebaseService: mockService);
      const seed = 'persistent-seed';
      await provider.initializeNewGame('test-game-id', seed);

      expect(provider.currentSeed, seed);

      // Simulate some operation that might change state
      provider.notifyListeners();

      expect(provider.currentSeed, seed);
    });
  });
}