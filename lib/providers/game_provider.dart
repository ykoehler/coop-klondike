import 'dart:async';
import 'package:flutter/material.dart';
import '../models/card.dart' as game;
import '../models/game_state.dart';
import '../models/game_lock.dart';
import '../models/drag_state.dart';
import '../models/deck.dart';
import '../logic/game_logic.dart';
import '../services/firebase_service.dart';
import '../utils/seed_generator.dart';
import 'dart:math';

class GameProvider extends ChangeNotifier {
  final FirebaseService firebaseService;
  GameState? _gameState; // Changed from late to nullable
  DrawMode _currentDrawMode = DrawMode.three;
  GameLock? _currentLock;
  DragState? _currentDrag;
  int _pendingActionCount = 0;
  final String _playerId;
  String _gameId;
  StreamSubscription? _gameSubscription;
  StreamSubscription? _lockSubscription;
  StreamSubscription? _dragSubscription;
  bool _mounted = true;
  bool _isInitializing = true;
  late FirebaseService _firebaseService;
  late String _actualGameId;
  bool _isInitialSetup;

  // Return a safe game state even if not initialized yet
  GameState get gameState => _gameState ?? GameState(
    gameId: _gameId,
    seedStr: _providedSeedStr ?? SeedGenerator.deriveFromGameId(_gameId),
    drawMode: _currentDrawMode,
  );
  String get gameId => _gameId;
  DrawMode get drawMode => _currentDrawMode;
  String get playerId => _playerId;
  bool get isLocked => _currentLock?.isLocked ?? false;
  bool get isLockedByMe => _currentLock?.playerId == _playerId;
  DragState? get currentDrag => _currentDrag;
  bool get isInitializing => _isInitializing;
  Deck get deck => gameState.stock; // Use the getter instead of direct access
  bool get isInitialSetup => _isInitialSetup;
  bool get hasPendingAction => _pendingActionCount > 0;
  
  // Allow test hooks to mark setup as complete
  void markSetupComplete() {
    _isInitialSetup = false;
    _isInitializing = false;  // Also mark initialization as complete for e2e tests
    if (_mounted) {
      notifyListeners();
    }
  }

  GameProvider({
    required this.firebaseService,
    String? gameId,
    String? seedStr,
    DrawMode? drawMode,
    bool isInitialSetup = false,
  }) : _providedSeedStr = seedStr,
       _playerId = _generatePlayerId(),
       _gameId = gameId ?? _generateGameId(),
       _isInitialSetup = isInitialSetup {
    _currentDrawMode = drawMode ?? DrawMode.three;
    _firebaseService = firebaseService;
    _actualGameId = _gameId;
    // Initialize with a temporary game state immediately
    _gameState = GameState(
      gameId: _gameId,
      seedStr: seedStr ?? SeedGenerator.deriveFromGameId(_gameId),
      drawMode: _currentDrawMode,
    );
    // Schedule async initialization to run in the next frame to ensure proper zone context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mounted) {
        _initializeGame();
      }
    });
  }

  // Test constructor for synchronous initialization
  GameProvider.test({
    required this.firebaseService,
    String? gameId,
    String? seedStr,
    DrawMode? drawMode,
    bool synchronous = true,
    bool isInitialSetup = false,
  }) : _providedSeedStr = seedStr,
       _playerId = _generatePlayerId(),
       _gameId = gameId ?? _generateGameId(),
       _isInitialSetup = isInitialSetup {
    _currentDrawMode = drawMode ?? DrawMode.three;
    _firebaseService = firebaseService;
    _actualGameId = _gameId;
    if (synchronous) {
      _initializeSynchronously();
    } else {
      _initializeGame();
    }
  }

  void _initializeSynchronously() {
    // Create game state synchronously for testing
    final effectiveSeed =
        _providedSeedStr ?? SeedGenerator.deriveFromGameId(_gameId);
    _gameState = GameState(
      gameId: _gameId,
      seedStr: effectiveSeed,
      drawMode: _currentDrawMode,
    );
    _isInitializing = false;
  }

  final String? _providedSeedStr;
  bool _isDragging = false;
  GameState? _pendingStateUpdate;

  static String _generatePlayerId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      List.generate(10, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
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

  void _applyPendingStateIfAvailable({bool notify = false}) {
    if (_pendingStateUpdate != null) {
      debugPrint(
        '🔄 FIREBASE SYNC: Discarding pending state update - we have local changes (notify=$notify)',
      );
      debugPrint(
        '  Pending: Stock=${_pendingStateUpdate!.stock.length}, Waste=${_pendingStateUpdate!.waste.length}',
      );
      debugPrint(
        '  Current: Stock=${_gameState?.stock.length ?? 0}, Waste=${_gameState?.waste.length ?? 0}',
      );
      
      // Discard the pending update - our local state is more authoritative
      // The next Firebase update after we push our changes will have the correct state
      _pendingStateUpdate = null;
    } else {
      debugPrint('🔄 FIREBASE SYNC: No pending state update to apply');
    }
  }

  GameState _cloneGameState(GameState state) {
    return GameState.fromJson(state.toJson());
  }

  List<game.Card> _collectAllCards(GameState state) {
    final cards = <game.Card>[];
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

  void _logMoveIntegrity(String actionName) {
    final allCards = _collectAllCards(_gameState!);
    final totalCards = allCards.length;
    final uniqueCards = allCards.toSet().length;

    _gameState!.logState(context: 'CARD MOVE: $actionName');
    debugPrint(
      'MOVE INTEGRITY [$actionName]: total=$totalCards, unique=$uniqueCards',
    );

    if (totalCards != 52 || uniqueCards != 52) {
      final cardCounts = <String, int>{};
      final cardLocations = <String, List<String>>{};

      void recordLocation(Iterable<game.Card> cards, String source) {
        for (final card in cards) {
          final key = '${card.suit}-${card.rank}';
          cardLocations.putIfAbsent(key, () => <String>[]).add(source);
          cardCounts[key] = (cardCounts[key] ?? 0) + 1;
        }
      }

      for (var i = 0; i < _gameState!.tableau.length; i++) {
        recordLocation(_gameState!.tableau[i].cards, 'tableau[$i]');
      }
      recordLocation(_gameState!.stock.cards, 'stock');
      recordLocation(_gameState!.waste, 'waste');
      for (var i = 0; i < _gameState!.foundations.length; i++) {
        recordLocation(_gameState!.foundations[i].cards, 'foundation[$i]');
      }

      final duplicates = cardCounts.entries
          .where((entry) => entry.value > 1)
          .toList();
      if (duplicates.isNotEmpty) {
        debugPrint('Duplicate cards detected after $actionName:');
        for (final duplicate in duplicates) {
          final locations = cardLocations[duplicate.key] ?? const [];
          debugPrint(
            '  ${duplicate.key}: ${duplicate.value} copies -> ${locations.join(", ")}',
          );
        }
      }
      throw StateError(
        'Card integrity violation after $actionName: total=$totalCards, unique=$uniqueCards',
      );
    }
  }

  Future<void> _performTransactionalMove({
    required String actionName,
    required String lockName,
    required VoidCallback mutateState,
    bool resetDragging = false,
  }) async {
    debugPrint('🔒 TRANSACTION START [$actionName]: pendingActions=$_pendingActionCount');
    
    // Apply any pending state (there shouldn't be any if sync is working correctly)
    _applyPendingStateIfAvailable();
    
    // Verify we don't have a pending update - this would indicate a sync failure
    if (_pendingStateUpdate != null) {
      debugPrint('⚠️ WARNING: Starting action [$actionName] with pending Firebase update! This indicates sync didn\'t complete.');
      _pendingStateUpdate = null; // Clear it to prevent corruption
    }

    if (_pendingActionCount > 0) {
      debugPrint(
        'ACTION SKIPPED [$actionName]: pending actions=$_pendingActionCount',
      );
      return;
    }

    _pendingActionCount++;
    if (_mounted) {
      notifyListeners();
    }

    bool lockAcquired = false;
    GameState? previousState;

    try {
      debugPrint('🔒 ACQUIRING LOCK [$actionName]');
      lockAcquired = await acquireLock(lockName);
      if (!lockAcquired) {
        debugPrint('🔒 LOCK FAILED [$actionName]');
        // Lock failed - decrement will happen in finally block
        return;
      }
      debugPrint('🔒 LOCK ACQUIRED [$actionName]');

      previousState = _cloneGameState(_gameState!);
      debugPrint('🔒 STATE CLONED [$actionName]: stock=${previousState.stock.length}, waste=${previousState.waste.length}');

      if (resetDragging) {
        _isDragging = false;
      }
      _applyPendingStateIfAvailable();
      debugPrint('🔒 BEFORE MUTATION [$actionName]: stock=${_gameState!.stock.length}, waste=${_gameState!.waste.length}');
      mutateState();
      debugPrint('🔒 AFTER MUTATION [$actionName]: stock=${_gameState!.stock.length}, waste=${_gameState!.waste.length}');
      _logMoveIntegrity(actionName);

      if (_mounted) {
        notifyListeners();
      }

      await _updateGameState();
    } catch (error, stackTrace) {
      if (previousState != null) {
        _gameState = previousState;
      }
      debugPrint('TRANSACTION ROLLBACK [$actionName]: $error');
      debugPrint(stackTrace.toString());
      rethrow;
    } finally {
      if (lockAcquired) {
        await releaseLock();
      }

      if (_pendingActionCount > 0) {
        _pendingActionCount--;
      }

      if (_mounted) {
        notifyListeners();
      }
    }
  }

  Future<void> _initializeGame() async {
    // Use atomic game creation to prevent race conditions
    bool gameCreated = false;
    try {
      // First, try to load existing game
      final existingGame = await _firebaseService.getGame(_actualGameId);

      if (existingGame != null) {
        _gameState = existingGame;
        _gameState!.existsInFirebase = true;
      } else {
        // Create a fresh game state with dealt cards ONLY if Firebase doesn't have it
        final newGameState = GameState(
          gameId: _gameId,
          seedStr: _providedSeedStr ?? SeedGenerator.deriveFromGameId(_gameId),
          drawMode: _currentDrawMode,
        );

        // Try atomic creation
        gameCreated = await _firebaseService.createGameIfNotExists(
          _actualGameId,
          newGameState,
        );

        if (gameCreated) {
          _gameState = newGameState;
          _gameState!.existsInFirebase = true;
        } else {
          // Another player created it in the meantime, load their version
          await Future.delayed(Duration(milliseconds: 300));
          final retryGame = await _firebaseService.getGame(_actualGameId);
          if (retryGame != null) {
            _gameState = retryGame;
            _gameState!.existsInFirebase = true;
          } else {
            // Use our local state as fallback
            _gameState = newGameState;
          }
        }
      }

      // Mark initialization as complete
      _isInitializing = false;
      if (_mounted) notifyListeners();

      // Subscribe to game state changes
      _gameSubscription = _firebaseService
          .listenToGame(_actualGameId)
          .listen(
            (newState) {
              try {
                if (!_mounted) return;

                debugPrint(
                  '📡 FIREBASE UPDATE: stock=${newState.stock.length}, waste=${newState.waste.length}, isDragging=$_isDragging',
                );

                // If we're currently dragging, queue the update instead of applying it immediately
                // This prevents card loss during drag operations
                if (_isDragging) {
                  debugPrint('📡 FIREBASE UPDATE: Queued (dragging) - DISCARDING to prevent stale state');
                  // Don't queue updates during drag - they'll be stale by the time drag finishes
                  // The next Firebase update after drag completes will have the fresh state
                  return;
                }

                // If we have pending actions, queue the update ONLY if we don't already have one
                // This prevents stale updates from overwriting newer queued updates
                if (_pendingActionCount > 0) {
                  if (_pendingStateUpdate == null) {
                    debugPrint('📡 FIREBASE UPDATE: Queued (pending actions=$_pendingActionCount)');
                    _pendingStateUpdate = newState;
                  } else {
                    debugPrint('📡 FIREBASE UPDATE: DISCARDED - already have pending update (pending actions=$_pendingActionCount)');
                  }
                  return;
                }

                debugPrint('📡 FIREBASE UPDATE: Applied immediately');
                _gameState = newState;
                if (_mounted) {
                  notifyListeners();
                }
              } catch (error, stackTrace) {
                debugPrint('GameProvider: Error processing game state: $error');
                debugPrint('Stack trace: $stackTrace');
              }
            },
            onError: (error, stackTrace) {
              // Log deserialization errors but don't crash the app
              debugPrint('GameProvider: Error in game state stream: $error');
              debugPrint('Stack trace: $stackTrace');
              // Continue listening - the stream will keep trying
            },
            cancelOnError: false,
          );

      // Subscribe to lock changes
      _lockSubscription = firebaseService.listenToGameLock(_gameId).listen((
        lockData,
      ) {
        try {
          if (!_mounted) return;
          _currentLock = GameLock.fromJson(lockData);
          if (_mounted) {
            notifyListeners();
          }
        } catch (error, stackTrace) {
          debugPrint('GameProvider: Error processing lock data: $error');
          debugPrint('Stack trace: $stackTrace');
        }
      }, onError: (error, stackTrace) {
        debugPrint('GameProvider: Error in lock stream: $error');
        debugPrint('Stack trace: $stackTrace');
      }, cancelOnError: false);

      // Subscribe to drag position changes with player filtering
      _dragSubscription = firebaseService.listenToDragPosition(_gameId).listen((
        dragData,
      ) {
        try {
          if (!_mounted) return;
          final newDragState = DragState.fromJson(dragData);
          // Only update if we have valid drag data and it's not from this player
          if (newDragState != null && newDragState.playerId != _playerId) {
            _currentDrag = newDragState;
            if (_mounted) {
              notifyListeners();
            }
          }
        } catch (error, stackTrace) {
          debugPrint('GameProvider: Error processing drag data: $error');
          debugPrint('Stack trace: $stackTrace');
        }
      }, onError: (error, stackTrace) {
        debugPrint('GameProvider: Error in drag stream: $error');
        debugPrint('Stack trace: $stackTrace');
      }, cancelOnError: false);
    } catch (e, stackTrace) {
      debugPrint('GameProvider: Error during initialization: $e');
      debugPrint('Stack trace: $stackTrace');
      // Even if there's an error, mark initialization as complete
      // and create a default game state so the app doesn't hang
      _gameState = GameState(
        gameId: _gameId,
        seedStr: _providedSeedStr ?? SeedGenerator.deriveFromGameId(_gameId),
        drawMode: _currentDrawMode,
      );
      _isInitializing = false;
      if (_mounted) {
        notifyListeners();
      }
      // Don't set up listeners if initialization failed
      return;
    }
  }

  Future<void> initializeNewGame(String gameId, [String? seed]) async {
    _gameId = gameId;
    final effectiveSeed = seed ?? SeedGenerator.generateSeed();
    _gameState = GameState(
      gameId: gameId,
      seedStr: effectiveSeed,
      drawMode: _currentDrawMode,
    );
    await _updateGameState();
    if (_mounted) {
      notifyListeners();
    }
  }

  Future<void> redealWithSeed(String seed) async {
    if (await acquireLock('redealWithSeed')) {
      _gameState!.redealWithSeed(seed);
      await _updateGameState();
      await releaseLock();
      if (_mounted) {
        notifyListeners();
      }
    }
  }

  Future<void> init(String gameId) async {
    _gameId = gameId;
    _gameState = GameState(gameId: gameId, drawMode: _currentDrawMode);
    await _updateGameState();
    if (_mounted) {
      notifyListeners();
    }
  }

  Future<void> sync() async {
    await _updateGameState();
  }

  Future<void> load(String gameId) async {
    final loaded = await firebaseService.getGame(gameId);
    if (loaded != null) {
      _gameState = loaded;
    }
    if (_mounted) {
      notifyListeners();
    }
  }

  Future<bool> acquireLock(String action) async {
    if (_currentLock?.isLocked ?? false) {
      if (_currentLock?.isLockExpired ?? false) {
        await _firebaseService.setGameLock(_actualGameId, _playerId, false);
      } else {
        return false;
      }
    }

    await _firebaseService.setGameLock(_actualGameId, _playerId, true);
    return true;
  }

  Future<void> releaseLock() async {
    await _firebaseService.setGameLock(_actualGameId, _playerId, false);
  }

  Future<void> _updateGameState() async {
    await firebaseService.updateGame(_gameId, _gameState!);
  }

  Future<void> updateDragPosition(String cardId, double x, double y) async {
    await _firebaseService.updateDragPosition(
      _actualGameId,
      cardId,
      x,
      y,
      _playerId,
    );
  }

  Future<String?> newGame({String? seed, DrawMode? drawMode}) async {
    if (await acquireLock('newGame')) {
      final mode = drawMode ?? _currentDrawMode;
      _gameState = GameState(drawMode: mode, seedStr: seed);
      _currentDrawMode = mode;
      await _updateGameState();
      await releaseLock();
      if (_mounted) {
        notifyListeners();
      }
      return _gameState!.gameId;
    }
    return null;
  }

  Future<void> setupInitialGameState() async {
    if (await acquireLock('setupGame')) {
      try {
        _gameState!.drawMode = _currentDrawMode;
        await _updateGameState();
      } finally {
        await releaseLock();
      }
      if (_mounted) {
        notifyListeners();
      }
    }
  }

  Future<void> changeDrawMode(DrawMode newMode) async {
    if (await acquireLock('changeDrawMode')) {
      _currentDrawMode = newMode;
      _gameState!.drawMode = newMode;  // Also update the game state's draw mode
      await _updateGameState();
      await releaseLock();
      if (_mounted) {
        notifyListeners();
      }
    }
  }

  Future<void> drawCard() async {
    debugPrint('🎴 DRAW CARD: Starting (stock=${_gameState?.stock.length}, waste=${_gameState?.waste.length}, pending=$_pendingActionCount)');
    
    // Early exit if there's already a pending action
    if (_pendingActionCount > 0) {
      debugPrint('🎴 DRAW CARD: Blocked - pending action in progress');
      return;
    }
    
    _applyPendingStateIfAvailable();
    debugPrint('🎴 DRAW CARD: After pending apply (stock=${_gameState?.stock.length}, waste=${_gameState?.waste.length})');
    
    if (!GameLogic.canDrawCard(_gameState!, _gameState!.drawMode)) {
      debugPrint('🎴 DRAW CARD: Cannot draw - returning');
      return;
    }

    await _performTransactionalMove(
      actionName: 'drawCard',
      lockName: 'drawCard',
      mutateState: () {
        debugPrint('🎴 DRAW CARD: Before mutation (stock=${_gameState!.stock.length}, waste=${_gameState!.waste.length})');
        GameLogic.drawCard(_gameState!, _gameState!.drawMode);
        debugPrint('🎴 DRAW CARD: After mutation (stock=${_gameState!.stock.length}, waste=${_gameState!.waste.length})');
      },
    );
    debugPrint('🎴 DRAW CARD: Completed');
  }

  Future<void> recycleWaste() async {
    debugPrint('🔄 RECYCLE START: Applying pending state if available... (pending=$_pendingActionCount)');
    
    // Early exit if there's already a pending action
    if (_pendingActionCount > 0) {
      debugPrint('🔄 RECYCLE: Blocked - pending action in progress');
      return;
    }
    
    _applyPendingStateIfAvailable();
    debugPrint('🔄 RECYCLE: After applying pending (stock=${_gameState!.stock.length}, waste=${_gameState!.waste.length})');
    
    if (!GameLogic.canRecycleWaste(_gameState!)) {
      debugPrint('🔄 RECYCLE: Cannot recycle (stock.isEmpty=${_gameState!.stock.isEmpty}, waste.isNotEmpty=${_gameState!.waste.isNotEmpty})');
      return;
    }

    debugPrint('🔄 RECYCLE: Can recycle, starting transactional move...');
    await _performTransactionalMove(
      actionName: 'recycleWaste',
      lockName: 'recycleWaste',
      mutateState: () => GameLogic.recycleWaste(_gameState!),
    );
    debugPrint('🔄 RECYCLE: Complete');
  }

  Future<void> moveWasteToTableau(int tableauIndex) async {
    _isDragging = false;
    _applyPendingStateIfAvailable();
    if (!GameLogic.canMoveWasteToTableau(_gameState!, tableauIndex)) return;

    await _performTransactionalMove(
      actionName: 'moveWasteToTableau',
      lockName: 'moveWasteToTableau',
      mutateState: () => GameLogic.moveWasteToTableau(_gameState!, tableauIndex),
      resetDragging: true,
    );
  }

  Future<void> moveWasteToFoundation(int foundationIndex) async {
    _isDragging = false;
    _applyPendingStateIfAvailable();
    if (!GameLogic.canMoveWasteToFoundation(_gameState!, foundationIndex)) {
      return;
    }

    await _performTransactionalMove(
      actionName: 'moveWasteToFoundation',
      lockName: 'moveWasteToFoundation',
      mutateState: () =>
          GameLogic.moveWasteToFoundation(_gameState!, foundationIndex),
      resetDragging: true,
    );
  }

  Future<void> moveTableauToTableau(
    int fromIndex,
    int toIndex,
    int cardCount,
  ) async {
    _isDragging = false;
    _applyPendingStateIfAvailable();
    if (!GameLogic.canMoveTableauToTableau(
      _gameState!,
      fromIndex,
      toIndex,
      cardCount,
    )) {
      return;
    }

    await _performTransactionalMove(
      actionName: 'moveTableauToTableau',
      lockName: 'moveTableauToTableau',
      mutateState: () => GameLogic.moveTableauToTableau(
        _gameState!,
        fromIndex,
        toIndex,
        cardCount,
      ),
      resetDragging: true,
    );
  }

  void setDragging(bool dragging) {
    _isDragging = dragging;
    if (!dragging) {
      _applyPendingStateIfAvailable(notify: true);
    }
  }

  Future<void> moveTableauToFoundation(
    int tableauIndex,
    int foundationIndex,
  ) async {
    _isDragging = false;
    _applyPendingStateIfAvailable();
    if (!GameLogic.canMoveTableauToFoundation(
      _gameState!,
      tableauIndex,
      foundationIndex,
    )) {
      return;
    }

    await _performTransactionalMove(
      actionName: 'moveTableauToFoundation',
      lockName: 'moveTableauToFoundation',
      mutateState: () => GameLogic.moveTableauToFoundation(
        _gameState!,
        tableauIndex,
        foundationIndex,
      ),
      resetDragging: true,
    );
  }

  Future<void> moveFoundationToTableau(
    int foundationIndex,
    int tableauIndex,
  ) async {
    _isDragging = false;
    _applyPendingStateIfAvailable();
    if (!GameLogic.canMoveFoundationToTableau(
      _gameState!,
      foundationIndex,
      tableauIndex,
    )) {
      return;
    }

    await _performTransactionalMove(
      actionName: 'moveFoundationToTableau',
      lockName: 'moveFoundationToTableau',
      mutateState: () => GameLogic.moveFoundationToTableau(
        _gameState!,
        foundationIndex,
        tableauIndex,
      ),
      resetDragging: true,
    );
  }

  bool get isGameWon => GameLogic.isGameWon(_gameState!);
  bool get isGameStuck => GameLogic.isGameStuck(_gameState!);
  bool get mounted => _mounted;
  String get currentSeed => _gameState!.seed;

  @override
  void dispose() {
    _mounted = false;
    _gameSubscription?.cancel();
    _lockSubscription?.cancel();
    _dragSubscription?.cancel();
    super.dispose();
  }
}
