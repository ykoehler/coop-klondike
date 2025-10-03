import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:coop_klondike/models/card.dart';
import 'package:coop_klondike/models/game_state.dart';
import 'package:coop_klondike/providers/game_provider.dart';
import 'package:coop_klondike/services/firebase_service.dart';

/// Mock Firebase service that simulates race conditions
class RaceConditionMockFirebaseService implements FirebaseService {
  final StreamController<GameState> _gameController = StreamController<GameState>.broadcast();
  final StreamController<Map<String, dynamic>> _lockController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _dragController = StreamController<Map<String, dynamic>>.broadcast();
  
  GameState? _currentState;
  final int _updateDelayMs = 100; // Simulate network delay
  bool _simulateConflict = false;
  
  /// Enable conflict simulation - will send conflicting updates during actions
  void enableConflictSimulation() {
    _simulateConflict = true;
  }
  
  /// Simulate a delayed state update (as if from another player)
  Future<void> simulateDelayedUpdate(GameState state) async {
    await Future.delayed(Duration(milliseconds: _updateDelayMs));
    _currentState = state;
    _gameController.add(state);
  }

  @override
  Future<void> updateGame(String gameId, GameState gameState) async {
    await Future.delayed(Duration(milliseconds: _updateDelayMs));
    
    if (_simulateConflict && _currentState != null) {
      // Simulate a race condition: another update came in during our update
      final conflictingState = GameState.fromJson(_currentState!.toJson());
      _gameController.add(conflictingState);
    }
    
    _currentState = gameState;
    _gameController.add(gameState);
  }

  @override
  Future<GameState?> getGame(String gameId) async {
    return _currentState;
  }

  @override
  Future<bool> createGameIfNotExists(String gameId, GameState gameState) async {
    if (_currentState == null) {
      _currentState = gameState;
      _gameController.add(gameState);
      return true;
    }
    return false;
  }

  @override
  Stream<GameState> listenToGame(String gameId) => _gameController.stream;

  @override
  Stream<Map<String, dynamic>> listenToGameLock(String gameId) => _lockController.stream;

  @override
  Stream<Map<String, dynamic>> listenToDragPosition(String gameId) => _dragController.stream;

  @override
  Future<void> setGameLock(String gameId, String playerId, bool isLocked) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _lockController.add({
      'isLocked': isLocked,
      'locked': isLocked,
      'playerId': playerId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<void> updateDragPosition(String gameId, String cardId, double x, double y, String playerId) async {
    // Not needed for this test
  }

  void dispose() {
    _gameController.close();
    _lockController.close();
    _dragController.close();
  }
}

void main() {
  // Initialize Flutter bindings for tests
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Firebase race condition simulation', () {
    late RaceConditionMockFirebaseService mockFirebase;
    late GameProvider provider;

    setUp(() {
      mockFirebase = RaceConditionMockFirebaseService();
    });

    tearDown(() {
      provider.dispose();
      mockFirebase.dispose();
    });

    test('Rapid drawCard calls maintain card integrity', () async {
      provider = GameProvider(
        gameId: 'test-game',
        firebaseService: mockFirebase,
      );

      await provider.setupInitialGameState();
      
      // Verify initial state (after auto-draw: 24 - 3 = 21 in stock, 3 in waste)
      expect(provider.gameState.stock.length, 21);
      expect(provider.gameState.waste.length, 3);
      
      final allCardsBefore = _collectAllCards(provider.gameState);
      expect(allCardsBefore.length, 52);
      expect(allCardsBefore.toSet().length, 52);
      
      // Rapidly call drawCard multiple times
      final futures = <Future>[];
      for (int i = 0; i < 5; i++) {
        futures.add(provider.drawCard());
        // Small delay to stagger calls
        await Future.delayed(const Duration(milliseconds: 10));
      }
      
      // Wait for all draws to complete
      await Future.wait(futures);
      await Future.delayed(const Duration(milliseconds: 500)); // Allow Firebase updates to settle
      
      // Verify card integrity
      final allCardsAfter = _collectAllCards(provider.gameState);
      expect(allCardsAfter.length, 52, reason: 'Should still have 52 total cards');
      expect(allCardsAfter.toSet().length, 52, reason: 'Should still have 52 unique cards');
      
      // Verify stock decreased (started at 21 after auto-draw)
      expect(provider.gameState.stock.length, lessThan(21));
      expect(provider.gameState.waste.length, greaterThan(3));
    });

    test('DrawCard during Firebase update maintains integrity', () async {
      provider = GameProvider(
        gameId: 'test-game',
        firebaseService: mockFirebase,
      );

      await provider.setupInitialGameState();
      
      // Enable conflict simulation
      mockFirebase.enableConflictSimulation();
      
      // Verify initial state (after auto-draw: 24 - 3 = 21)
      expect(provider.gameState.stock.length, 21);
      
      final allCardsBefore = _collectAllCards(provider.gameState);
      expect(allCardsBefore.toSet().length, 52);
      
      // Trigger a draw while simulating a conflicting Firebase update
      final drawFuture = provider.drawCard();
      
      // Simulate an update from Firebase while draw is in progress
      await Future.delayed(const Duration(milliseconds: 50));
      final conflictingState = GameState.fromJson(provider.gameState.toJson());
      await mockFirebase.simulateDelayedUpdate(conflictingState);
      
      await drawFuture;
      await Future.delayed(const Duration(milliseconds: 500)); // Allow updates to settle
      
      // Verify card integrity
      final allCardsAfter = _collectAllCards(provider.gameState);
      expect(allCardsAfter.length, 52, reason: 'Should still have 52 total cards');
      expect(allCardsAfter.toSet().length, 52, reason: 'Should still have 52 unique cards');
    });

    test('Drain stock completely with rapid clicks', () async {
      provider = GameProvider(
        gameId: 'test-game',
        firebaseService: mockFirebase,
      );

      await provider.setupInitialGameState();
      
      // Rapidly drain the entire stock
      while (provider.gameState.stock.length > 0) {
        await provider.drawCard();
        // Very small delay to simulate rapid clicking
        await Future.delayed(const Duration(milliseconds: 5));
      }
      
      await Future.delayed(const Duration(milliseconds: 500)); // Allow updates to settle
      
      // Verify final state
      expect(provider.gameState.stock.length, 0);
      expect(provider.gameState.waste.length, 24);
      
      // Verify card integrity
      final allCards = _collectAllCards(provider.gameState);
      expect(allCards.length, 52, reason: 'Should still have 52 total cards');
      expect(allCards.toSet().length, 52, reason: 'Should still have 52 unique cards');
    });
  });
}

/// Helper to collect all cards from game state
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
