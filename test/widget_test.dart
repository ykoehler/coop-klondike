// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:async';

import 'package:coop_klondike/models/game_state.dart';
import 'package:coop_klondike/providers/game_provider.dart';
import 'package:coop_klondike/screens/game_screen.dart';
import 'package:coop_klondike/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class MockFirebaseService implements FirebaseService {
  GameState? getGameReturnValue;
  final StreamController<GameState> _gameController =
      StreamController<GameState>.broadcast();

  @override
  Future<void> updateGame(String gameId, GameState gameState) async {}

  @override
  Future<GameState?> getGame(String gameId) async => getGameReturnValue;

  @override
  Future<bool> createGameIfNotExists(
    String gameId,
    GameState gameState,
  ) async => true;

  @override
  Stream<GameState> listenToGame(String gameId) => _gameController.stream;

  @override
  Stream<Map<String, dynamic>> listenToGameLock(String gameId) =>
  Stream.value({'isLocked': false, 'playerId': null});

  @override
  Stream<Map<String, dynamic>> listenToDragPosition(String gameId) =>
      Stream.value({'cardId': '', 'x': 0.0, 'y': 0.0});

  @override
  Future<void> setGameLock(String gameId, String playerId, bool isLocked) async {}

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

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    final mockService = MockFirebaseService();

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => GameProvider.test(
          firebaseService: mockService,
          synchronous: true,
          isInitialSetup: true,
        ),
        child: const MaterialApp(
          home: GameScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Klondike Solitaire'), findsOneWidget);

    mockService.dispose();
  });
}
