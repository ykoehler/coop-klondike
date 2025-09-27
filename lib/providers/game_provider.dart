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
    : _gameState = GameState(gameId: gameId, seed: seed),
      _playerId = _generatePlayerId() {
    _gameState.drawMode = _currentDrawMode;
    _initializeGame();
  }

  static String _generatePlayerId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      List.generate(10, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }

  Future<void> _initializeGame() async {
    print('Initializing game with ID: $gameId');
    
    // Use atomic game creation to prevent race conditions
    bool gameCreated = false;
    try {
      print('Attempting to create new game atomically for ID: $gameId');
      gameCreated = await _firebaseService.createGameIfNotExists(gameId, _gameState);
      
      if (gameCreated) {
        print('Successfully created new game in Firebase');
        _gameState.existsInFirebase = true;
      } else {
        print('Game already exists, loading existing state');
        final existingGame = await _firebaseService.getGame(gameId);
        if (existingGame != null) {
          _gameState = existingGame;
          print('Loaded existing game state');
        } else {
          print('Warning: Game creation failed and existing game not found');
          // Fallback: wait and try again
          await Future.delayed(Duration(milliseconds: 500));
          final retryGame = await _firebaseService.getGame(gameId);
          if (retryGame != null) {
            _gameState = retryGame;
            print('Loaded game state on retry');
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
      GameLogic.moveWasteToTableau(_gameState, tableauIndex);
      await _updateGameState();
      await releaseLock();
      notifyListeners();
    }
  }

  void moveWasteToFoundation(int foundationIndex) async {
    if (!GameLogic.canMoveWasteToFoundation(_gameState, foundationIndex)) return;

    if (await acquireLock('moveWasteToFoundation')) {
      GameLogic.moveWasteToFoundation(_gameState, foundationIndex);
      await _updateGameState();
      await releaseLock();
      notifyListeners();
    }
  }

  void moveTableauToTableau(int fromIndex, int toIndex, int cardCount) async {
    if (!GameLogic.canMoveTableauToTableau(_gameState, fromIndex, toIndex, cardCount)) return;

    if (await acquireLock('moveTableauToTableau')) {
      GameLogic.moveTableauToTableau(_gameState, fromIndex, toIndex, cardCount);
      await _updateGameState();
      await releaseLock();
      notifyListeners();
    }
  }

  void moveTableauToFoundation(int tableauIndex, int foundationIndex) async {
    if (!GameLogic.canMoveTableauToFoundation(_gameState, tableauIndex, foundationIndex)) return;

    if (await acquireLock('moveTableauToFoundation')) {
      GameLogic.moveTableauToFoundation(_gameState, tableauIndex, foundationIndex);
      await _updateGameState();
      await releaseLock();
      notifyListeners();
    }
  }

  void moveFoundationToTableau(int foundationIndex, int tableauIndex) async {
    if (!GameLogic.canMoveFoundationToTableau(_gameState, foundationIndex, tableauIndex)) return;

    if (await acquireLock('moveFoundationToTableau')) {
      GameLogic.moveFoundationToTableau(_gameState, foundationIndex, tableauIndex);
      await _updateGameState();
      await releaseLock();
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