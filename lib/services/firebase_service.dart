import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

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
    print('=== FIREBASE UPDATE GAME ===');
    print('GameId: $gameId');
    print('Updating game state to Firebase');
    final json = gameState.toJson();
    print('JSON tableau length being sent to Firebase: ${(json['tableau'] as List).length}');
    
    await _gamesRef.child(gameId).set(json);
    print('Firebase update completed');
    print('=== END FIREBASE UPDATE GAME ===');
  }

  // Atomic game creation - only succeeds if game doesn't exist
  Future<bool> createGameIfNotExists(String gameId, GameState gameState) async {
    try {
      // Use transaction to atomically check-and-set
      final transactionResult = await _gamesRef.child(gameId).runTransaction((currentData) {
        if (currentData != null) {
          // Game already exists, abort transaction
          return Transaction.abort();
        }
        // Game doesn't exist, create it
        return Transaction.success(gameState.toJson());
      });
      
      return transactionResult.committed;
    } catch (e) {
      print('Error in createGameIfNotExists: $e');
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
    return _gamesRef.child(gameId).onValue.map((event) {
      print('=== FIREBASE LISTENER TRIGGERED ===');
      print('GameId: $gameId');
      print('Raw Firebase data received: ${event.snapshot.value != null}');
      
      if (event.snapshot.value == null) {
        print('No data found in Firebase for game: $gameId');
        throw Exception('Game not found');
      }
      
      final rawData = event.snapshot.value!;
      print('Raw data type: ${rawData.runtimeType}');
      
      final data = _convertToStringDynamicMap(rawData);
      print('Converted data tableau length: ${(data['tableau'] as List?)?.length}');
      print('=== END FIREBASE LISTENER ===');
      
      return GameState.fromJson(data);
    });
  }

  // Set game lock
  Future<void> setGameLock(String gameId, String playerId, bool isLocked) async {
    await _gamesRef.child('$gameId/lock').set({
      'locked': isLocked,
      'playerId': playerId,
      'timestamp': ServerValue.timestamp,
    });
  }

  // Listen to game lock changes
  Stream<Map<String, dynamic>> listenToGameLock(String gameId) {
    return _gamesRef.child('$gameId/lock').onValue.map((event) {
      if (event.snapshot.value == null) {
        return {'locked': false, 'playerId': null, 'timestamp': DateTime.now().millisecondsSinceEpoch};
      }
      return _convertToStringDynamicMap(event.snapshot.value!);
    });
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
    return _gamesRef.child('$gameId/dragState').onValue.map((event) {
      if (event.snapshot.value == null) {
        return {'cardId': '', 'x': 0.0, 'y': 0.0, 'timestamp': DateTime.now().millisecondsSinceEpoch};
      }
      return _convertToStringDynamicMap(event.snapshot.value!);
    });
  }
}