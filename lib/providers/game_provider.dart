import 'dart:async';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/game_lock.dart';
import '../models/drag_state.dart';
import '../logic/game_logic.dart';
import '../services/firebase_service.dart';
import 'dart:math';

class GameProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  GameState _gameState;
  DrawMode _currentDrawMode = DrawMode.three;
  GameLock? _currentLock;
  DragState? _currentDrag;
  final String _playerId;
  StreamSubscription? _gameSubscription;
  StreamSubscription? _lockSubscription;
  StreamSubscription? _dragSubscription;
  bool _mounted = true;
  bool _isInitializing = true;

  GameState get gameState => _gameState;
  String get gameId => _gameState.gameId;
  DrawMode get drawMode => _currentDrawMode;
  String get playerId => _playerId;
  bool get isLocked => _currentLock?.isLocked ?? false;
  bool get isLockedByMe => _currentLock?.playerId == _playerId;
  DragState? get currentDrag => _currentDrag;
  bool get isInitializing => _isInitializing;

  GameProvider({String? gameId, int? seed})
    : _providedGameId = gameId,
      _providedSeed = seed,
      _playerId = _generatePlayerId(),
      _gameState = GameState(gameId: gameId, seed: 0) { // Temporary placeholder
    _initializeGame();
  }

  final String? _providedGameId;
  final int? _providedSeed;
  bool _isDragging = false;
  GameState? _pendingStateUpdate;

  static String _generatePlayerId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      List.generate(10, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
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

  Future<void> _initializeGame() async {
    final actualGameId = _providedGameId ?? _generateGameId();
    print('Initializing game with ID: $actualGameId');
    
    // Use atomic game creation to prevent race conditions
    bool gameCreated = false;
    try {
      // First, try to load existing game
      print('Checking if game exists for ID: $actualGameId');
      final existingGame = await _firebaseService.getGame(actualGameId);
      
      if (existingGame != null) {
        print('Game already exists, loading existing state');
        _gameState = existingGame;
        _gameState.existsInFirebase = true;
        print('Loaded existing game state with ${_gameState.stock.length} cards in stock');
      } else {
        print('Game does not exist, creating new game atomically');
        // Create a fresh game state with dealt cards ONLY if Firebase doesn't have it
        final newGameState = GameState(
          gameId: actualGameId,
          seed: _providedSeed ?? actualGameId.hashCode,
          drawMode: _currentDrawMode
        );
        
        // Try atomic creation
        gameCreated = await _firebaseService.createGameIfNotExists(actualGameId, newGameState);
        
        if (gameCreated) {
          print('Successfully created new game in Firebase');
          _gameState = newGameState;
          _gameState.existsInFirebase = true;
        } else {
          print('Race condition: Another player created the game, loading their state');
          // Another player created it in the meantime, load their version
          await Future.delayed(Duration(milliseconds: 300));
          final retryGame = await _firebaseService.getGame(actualGameId);
          if (retryGame != null) {
            _gameState = retryGame;
            _gameState.existsInFirebase = true;
            print('Loaded game state on retry');
          } else {
            print('ERROR: Could not load game after race condition');
            // Use our local state as fallback
            _gameState = newGameState;
          }
        }
      }
      
      if (_mounted) notifyListeners();
    } catch (e) {
      print('Error in atomic game initialization: $e');
      return;
    }
    
    // Mark initialization as complete
    _isInitializing = false;

    // Subscribe to game state changes
    _gameSubscription = _firebaseService.listenToGame(gameId).listen((newState) {
      if (!_mounted) return;
      print('=== FIREBASE GAME STATE UPDATE RECEIVED ===');
      print('Player ID: $_playerId');
      print('Game ID: $gameId');
      print('Is Dragging: $_isDragging');
      print('New State GameId: ${newState.gameId}');
      print('Tableau columns count: ${newState.tableau.length}');
      
      // Log detailed tableau state
      for (int i = 0; i < newState.tableau.length; i++) {
        final column = newState.tableau[i];
        print('Tableau Column $i: ${column.cards.length} cards');
        for (int j = 0; j < column.cards.length; j++) {
          final card = column.cards[j];
          print('  Card $j: ${card.suit} ${card.rank} (faceUp: ${card.faceUp})');
        }
      }
      
      // If we're currently dragging, queue the update instead of applying it immediately
      // This prevents card loss during drag operations
      if (_isDragging) {
        print('Dragging in progress, queueing state update');
        _pendingStateUpdate = newState;
        return;
      }
      
      print('Current local state before update:');
      print('Local tableau columns count: ${_gameState.tableau.length}');
      for (int i = 0; i < _gameState.tableau.length; i++) {
        final column = _gameState.tableau[i];
        print('Local Tableau Column $i: ${column.cards.length} cards');
        for (int j = 0; j < column.cards.length; j++) {
          final card = column.cards[j];
          print('  Local Card $j: ${card.suit} ${card.rank} (faceUp: ${card.faceUp})');
        }
      }
      
      _gameState = newState;
      print('State updated, calling notifyListeners()');
      notifyListeners();
      print('notifyListeners() completed');
      print('=== END FIREBASE GAME STATE UPDATE ===');
    }, onError: (error) {
      print('Error in game state subscription: $error');
    });

    // Subscribe to lock changes
    _lockSubscription = _firebaseService.listenToGameLock(gameId).listen((lockData) {
      if (!_mounted) return;
      print('Received lock update: $lockData');
      _currentLock = GameLock.fromJson(lockData);
      notifyListeners();
    }, onError: (error) {
      print('Error in lock subscription: $error');
    });

    // Subscribe to drag position changes with player filtering
    _dragSubscription = _firebaseService.listenToDragPosition(gameId).listen((dragData) {
      if (!_mounted) return;
      final newDragState = DragState.fromJson(dragData);
      // Only update if we have valid drag data and it's not from this player
      if (newDragState != null && newDragState.playerId != _playerId) {
        _currentDrag = newDragState;
        notifyListeners();
      }
    });
  }

  Future<bool> acquireLock(String action) async {
    print('Attempting to acquire lock for $action');
    if (_currentLock?.isLocked ?? false) {
      print('Lock status: locked=${_currentLock?.isLocked}, playerId=${_currentLock?.playerId}, isExpired=${_currentLock?.isLockExpired}');
      if (_currentLock?.isLockExpired ?? false) {
        print('Forcing release of expired lock');
        await _firebaseService.setGameLock(gameId, _playerId, false);
      } else {
        print('Lock acquisition failed: already locked');
        return false;
      }
    }

    print('Setting lock for player $_playerId');
    await _firebaseService.setGameLock(gameId, _playerId, true);
    return true;
  }

  Future<void> releaseLock() async {
    await _firebaseService.setGameLock(gameId, _playerId, false);
  }

  Future<void> _updateGameState() async {
    await _firebaseService.updateGame(gameId, _gameState);
  }

  Future<void> updateDragPosition(String cardId, double x, double y) async {
    await _firebaseService.updateDragPosition(
      gameId,
      cardId,
      x,
      y,
      _playerId,
    );
  }

  Future<String?> newGame() async {
    if (await acquireLock('newGame')) {
      _gameState = GameState(drawMode: _currentDrawMode);
      await _updateGameState();
      await releaseLock();
      notifyListeners();
      return _gameState.gameId;
    }
    return null;
  }

  Future<void> setupInitialGameState() async {
    if (await acquireLock('setupGame')) {
      try {
        print('Setting up initial game state for ID: $gameId');
        _gameState.drawMode = _currentDrawMode;
        await _updateGameState();
        print('Game state updated with mode: ${_currentDrawMode}');
      } catch (e) {
        print('Error setting up initial game state: $e');
      } finally {
        await releaseLock();
      }
      notifyListeners();
    }
  }

  void changeDrawMode(DrawMode newMode) async {
    if (await acquireLock('changeDrawMode')) {
      _currentDrawMode = newMode;
      await _updateGameState();
      await releaseLock();
      notifyListeners();
    }
  }

  void drawCard() async {
    if (!GameLogic.canDrawCard(_gameState, _gameState.drawMode)) return;
    
    if (await acquireLock('drawCard')) {
      GameLogic.drawCard(_gameState, _gameState.drawMode);
      await _updateGameState();
      await releaseLock();
      notifyListeners();
    }
  }

  void recycleWaste() async {
    if (!GameLogic.canRecycleWaste(_gameState)) return;

    if (await acquireLock('recycleWaste')) {
      GameLogic.recycleWaste(_gameState);
      await _updateGameState();
      await releaseLock();
      notifyListeners();
    }
  }

  void moveWasteToTableau(int tableauIndex) async {
    if (!GameLogic.canMoveWasteToTableau(_gameState, tableauIndex)) return;

    if (await acquireLock('moveWasteToTableau')) {
      _isDragging = false;
      GameLogic.moveWasteToTableau(_gameState, tableauIndex);
      await _updateGameState();
      await releaseLock();
      
      if (_pendingStateUpdate != null) {
        _gameState = _pendingStateUpdate!;
        _pendingStateUpdate = null;
      }
      
      notifyListeners();
    }
  }

  void moveWasteToFoundation(int foundationIndex) async {
    if (!GameLogic.canMoveWasteToFoundation(_gameState, foundationIndex)) return;

    if (await acquireLock('moveWasteToFoundation')) {
      _isDragging = false;
      GameLogic.moveWasteToFoundation(_gameState, foundationIndex);
      await _updateGameState();
      await releaseLock();
      
      if (_pendingStateUpdate != null) {
        _gameState = _pendingStateUpdate!;
        _pendingStateUpdate = null;
      }
      
      notifyListeners();
    }
  }

  void moveTableauToTableau(int fromIndex, int toIndex, int cardCount) async {
    if (!GameLogic.canMoveTableauToTableau(_gameState, fromIndex, toIndex, cardCount)) return;

    if (await acquireLock('moveTableauToTableau')) {
      _isDragging = false; // Drag completed successfully
      GameLogic.moveTableauToTableau(_gameState, fromIndex, toIndex, cardCount);
      await _updateGameState();
      await releaseLock();
      
      // Apply any pending state updates that arrived during drag
      if (_pendingStateUpdate != null) {
        print('Applying pending state update after drag completion');
        _gameState = _pendingStateUpdate!;
        _pendingStateUpdate = null;
      }
      
      notifyListeners();
    }
  }
  
  void setDragging(bool dragging) {
    _isDragging = dragging;
    if (!dragging && _pendingStateUpdate != null) {
      print('Drag cancelled, applying pending state update');
      _gameState = _pendingStateUpdate!;
      _pendingStateUpdate = null;
      notifyListeners();
    }
  }

  void moveTableauToFoundation(int tableauIndex, int foundationIndex) async {
    if (!GameLogic.canMoveTableauToFoundation(_gameState, tableauIndex, foundationIndex)) return;

    if (await acquireLock('moveTableauToFoundation')) {
      _isDragging = false;
      GameLogic.moveTableauToFoundation(_gameState, tableauIndex, foundationIndex);
      await _updateGameState();
      await releaseLock();
      
      if (_pendingStateUpdate != null) {
        _gameState = _pendingStateUpdate!;
        _pendingStateUpdate = null;
      }
      
      notifyListeners();
    }
  }

  void moveFoundationToTableau(int foundationIndex, int tableauIndex) async {
    if (!GameLogic.canMoveFoundationToTableau(_gameState, foundationIndex, tableauIndex)) return;

    if (await acquireLock('moveFoundationToTableau')) {
      _isDragging = false;
      GameLogic.moveFoundationToTableau(_gameState, foundationIndex, tableauIndex);
      await _updateGameState();
      await releaseLock();
      
      if (_pendingStateUpdate != null) {
        _gameState = _pendingStateUpdate!;
        _pendingStateUpdate = null;
      }
      
      notifyListeners();
    }
  }

  bool get isGameWon => GameLogic.isGameWon(_gameState);
  bool get isGameStuck => GameLogic.isGameStuck(_gameState);
  bool get mounted => _mounted;

  @override
  void dispose() {
    _mounted = false;
    _gameSubscription?.cancel();
    _lockSubscription?.cancel();
    _dragSubscription?.cancel();
    super.dispose();
  }
}