import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../models/game_state.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  late final DatabaseReference _gamesRef;
  
  // Singleton factory constructor
  factory FirebaseService() {
    return _instance;
  }

  Map<String, dynamic> _convertToStringDynamicMap(Object value) {
    if (value is Map) {
      return value.map((key, value) {
        if (value is Map) {
          return MapEntry(key.toString(), _convertToStringDynamicMap(value));
        } else if (value is List) {
          return MapEntry(key.toString(), value.map((e) => e is Map ? _convertToStringDynamicMap(e) : e).toList());
        } else {
          return MapEntry(key.toString(), value);
        }
      });
    }
    throw Exception('Value is not a Map: $value');
  }

  FirebaseService._internal() {
    _database.setLoggingEnabled(false); // Disable logging to suppress warnings
    _gamesRef = _database.ref('games');
  }

  // Initialize Firebase
  static Future<void> initialize() async {
    // No need for explicit initialization as it's handled in main.dart
    return;
  }

  // Create or update a game
  Future<void> updateGame(String gameId, GameState gameState) async {
    final json = gameState.toJson();
    
    debugPrint('📤 FIREBASE OUT [updateGame]: gameId=$gameId');
    debugPrint('   Stock: ${gameState.stock.length} cards, Waste: ${gameState.waste.length} cards');
    debugPrint('   Total cards: ${_countTotalCards(gameState)}');
    
    await _gamesRef.child(gameId).set(json);
    
    debugPrint('✅ FIREBASE OUT [updateGame]: Complete');
  }
  
  int _countTotalCards(GameState state) {
    int total = 0;
    for (final column in state.tableau) {
      total += column.cards.length;
    }
    total += state.stock.length;
    total += state.waste.length;
    for (final foundation in state.foundations) {
      total += foundation.cards.length;
    }
    return total;
  }

  // Atomic game creation - only succeeds if game doesn't exist
  Future<bool> createGameIfNotExists(String gameId, GameState gameState) async {
    try {
      debugPrint('📤 FIREBASE OUT [createGameIfNotExists]: gameId=$gameId');
      debugPrint('   Stock: ${gameState.stock.length} cards, Waste: ${gameState.waste.length} cards');
      
      // Use transaction to atomically check-and-set
      final transactionResult = await _gamesRef.child(gameId).runTransaction((currentData) {
        if (currentData != null) {
          // Game already exists, abort transaction
          debugPrint('⚠️  FIREBASE OUT [createGameIfNotExists]: Game already exists, aborting');
          return Transaction.abort();
        }
        // Game doesn't exist, create it
        return Transaction.success(gameState.toJson());
      });
      
      debugPrint('✅ FIREBASE OUT [createGameIfNotExists]: ${transactionResult.committed ? "Created" : "Already exists"}');
      return transactionResult.committed;
    } catch (e) {
      debugPrint('❌ FIREBASE OUT [createGameIfNotExists]: Error - $e');
      return false;
    }
  }

  // Get a game by ID
  Future<GameState?> getGame(String gameId) async {
    final snapshot = await _gamesRef.child(gameId).get();
    if (snapshot.exists && snapshot.value != null) {
      final data = _convertToStringDynamicMap(snapshot.value!);
      return GameState.fromJson(data);
    }
    return null;
  }

  // Listen to game changes
  Stream<GameState> listenToGame(String gameId) {
    return _gamesRef.child(gameId).onValue.transform(
      StreamTransformer<DatabaseEvent, GameState>.fromHandlers(
        handleData: (event, sink) {
          try {
            if (event.snapshot.value == null) {
              sink.addError(Exception('Game not found'));
              return;
            }
            
            final rawData = event.snapshot.value!;
            final data = _convertToStringDynamicMap(rawData);
            final gameState = GameState.fromJson(data);
            
            debugPrint('📥 FIREBASE IN [listenToGame]: gameId=$gameId');
            debugPrint('   Stock: ${gameState.stock.length} cards, Waste: ${gameState.waste.length} cards');
            debugPrint('   Total cards: ${_countTotalCards(gameState)}');
            
            sink.add(gameState);
          } catch (e, stackTrace) {
            debugPrint('❌ FIREBASE IN [listenToGame]: Failed to deserialize game state: $e');
            debugPrint('Stack trace: $stackTrace');
            sink.addError(e, stackTrace);
          }
        },
        handleError: (error, stackTrace, sink) {
          debugPrint('❌ FIREBASE IN [listenToGame]: Stream error: $error');
          sink.addError(error, stackTrace);
        },
      ),
    );
  }

  // Set game lock
  Future<void> setGameLock(String gameId, String playerId, bool isLocked) async {
    await _gamesRef.child('$gameId/lock').set({
      'isLocked': isLocked,
      'locked': isLocked, // legacy compatibility
      'playerId': playerId,
      'timestamp': ServerValue.timestamp,
    });
  }

  // Listen to game lock changes
  Stream<Map<String, dynamic>> listenToGameLock(String gameId) {
    return _gamesRef.child('$gameId/lock').onValue.transform(
      StreamTransformer<DatabaseEvent, Map<String, dynamic>>.fromHandlers(
        handleData: (event, sink) {
          try {
            if (event.snapshot.value == null) {
              sink.add({
                'isLocked': false,
                'locked': false,
                'playerId': null,
                'timestamp': DateTime.now().millisecondsSinceEpoch,
              });
              return;
            }
            final data = _convertToStringDynamicMap(event.snapshot.value!);
            sink.add(data);
          } catch (e, stackTrace) {
            debugPrint('Firebase lock listener: Error: $e');
            sink.addError(e, stackTrace);
          }
        },
        handleError: (error, stackTrace, sink) {
          debugPrint('Firebase lock listener: Stream error: $error');
          sink.addError(error, stackTrace);
        },
      ),
    );
  }

  // Update card drag position
  Future<void> updateDragPosition(String gameId, String cardId, double x, double y, String playerId) async {
    await _gamesRef.child('$gameId/dragState').set({
      'cardId': cardId,
      'x': x,
      'y': y,
      'timestamp': ServerValue.timestamp,
      'playerId': playerId,
    });
  }

  // Listen to card drag position changes
  Stream<Map<String, dynamic>> listenToDragPosition(String gameId) {
    return _gamesRef.child('$gameId/dragState').onValue.transform(
      StreamTransformer<DatabaseEvent, Map<String, dynamic>>.fromHandlers(
        handleData: (event, sink) {
          try {
            if (event.snapshot.value == null) {
              sink.add({'cardId': '', 'x': 0.0, 'y': 0.0, 'timestamp': DateTime.now().millisecondsSinceEpoch});
              return;
            }
            final data = _convertToStringDynamicMap(event.snapshot.value!);
            sink.add(data);
          } catch (e, stackTrace) {
            debugPrint('Firebase drag listener: Error: $e');
            sink.addError(e, stackTrace);
          }
        },
        handleError: (error, stackTrace, sink) {
          debugPrint('Firebase drag listener: Stream error: $error');
          sink.addError(error, stackTrace);
        },
      ),
    );
  }
}