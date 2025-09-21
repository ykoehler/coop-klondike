import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../logic/game_logic.dart';

class GameProvider extends ChangeNotifier {
  GameState _gameState = GameState();

  GameState get gameState => _gameState;

  void newGame() {
    _gameState = GameState();
    notifyListeners();
  }

  void drawCard() {
    if (GameLogic.canDrawCard(_gameState)) {
      GameLogic.drawCard(_gameState);
      notifyListeners();
    }
  }

  void moveWasteToTableau(int tableauIndex) {
    if (GameLogic.canMoveWasteToTableau(_gameState, tableauIndex)) {
      GameLogic.moveWasteToTableau(_gameState, tableauIndex);
      notifyListeners();
    }
  }

  void moveWasteToFoundation(int foundationIndex) {
    if (GameLogic.canMoveWasteToFoundation(_gameState, foundationIndex)) {
      GameLogic.moveWasteToFoundation(_gameState, foundationIndex);
      notifyListeners();
    }
  }

  void moveTableauToTableau(int fromIndex, int toIndex, int cardCount) {
    if (GameLogic.canMoveTableauToTableau(_gameState, fromIndex, toIndex, cardCount)) {
      GameLogic.moveTableauToTableau(_gameState, fromIndex, toIndex, cardCount);
      notifyListeners();
    }
  }

  void moveTableauToFoundation(int tableauIndex, int foundationIndex) {
    if (GameLogic.canMoveTableauToFoundation(_gameState, tableauIndex, foundationIndex)) {
      GameLogic.moveTableauToFoundation(_gameState, tableauIndex, foundationIndex);
      notifyListeners();
    }
  }

  void moveFoundationToTableau(int foundationIndex, int tableauIndex) {
    if (GameLogic.canMoveFoundationToTableau(_gameState, foundationIndex, tableauIndex)) {
      GameLogic.moveFoundationToTableau(_gameState, foundationIndex, tableauIndex);
      notifyListeners();
    }
  }

  bool get isGameWon => GameLogic.isGameWon(_gameState);
}