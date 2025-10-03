import 'package:flutter_test/flutter_test.dart';
import 'package:coop_klondike/models/card.dart';
import 'package:coop_klondike/models/game_state.dart';
import 'package:coop_klondike/logic/game_logic.dart';

void main() {
  group('Stock cycling behavior (Klondike rules)', () {
    test('recycling preserves card order in 1-card mode', () {
      final gameState = GameState(seedStr: 'stock-cycle-test-1', drawMode: DrawMode.one);
      
      // After dealing, one card is automatically drawn to waste (DrawMode.one)
      expect(gameState.stock.length, 23);
      expect(gameState.waste.length, 1);
      
      // First cycle: drain the stock completely
      final firstCycle = <Card>[];
      // Add the card already in waste
      firstCycle.addAll(gameState.waste);
      
      while (!gameState.stock.isEmpty) {
        final wasteBeforeCount = gameState.waste.length;
        GameLogic.drawCard(gameState, DrawMode.one);
        for (int i = wasteBeforeCount; i < gameState.waste.length; i++) {
          firstCycle.add(gameState.waste[i]);
        }
      }
      
      expect(firstCycle.length, 24);
      expect(gameState.stock.length, 0);
      expect(gameState.waste.length, 24);
      
      // Recycle the waste back to stock
      GameLogic.recycleWaste(gameState);
      expect(gameState.stock.length, 24);
      expect(gameState.waste.length, 0);
      
      // Second cycle: drain the stock again
      final secondCycle = <Card>[];
      while (!gameState.stock.isEmpty) {
        final wasteBeforeCount = gameState.waste.length;
        GameLogic.drawCard(gameState, DrawMode.one);
        for (int i = wasteBeforeCount; i < gameState.waste.length; i++) {
          secondCycle.add(gameState.waste[i]);
        }
      }
      
      expect(secondCycle.length, 24);
      
      // In Klondike, recycling preserves the order
      // So second cycle should be the same as the first cycle
      for (int i = 0; i < firstCycle.length; i++) {
        expect(
          secondCycle[i],
          equals(firstCycle[i]),
          reason: 'Card at position $i should match first cycle',
        );
      }
    });
    
    test('recycling preserves card order in 3-card mode', () {
      final gameState = GameState(seedStr: 'stock-cycle-test-3', drawMode: DrawMode.three);
      
      // After dealing, three cards are automatically drawn to waste (DrawMode.three)
      expect(gameState.stock.length, 21);
      expect(gameState.waste.length, 3);
      
      // First cycle: flatten all drawn cards into a single list
      final firstCycleFlat = <Card>[];
      // Add the card already in waste
      firstCycleFlat.addAll(gameState.waste);
      
      while (!gameState.stock.isEmpty) {
        final wasteBeforeCount = gameState.waste.length;
        GameLogic.drawCard(gameState, DrawMode.three);
        for (int i = wasteBeforeCount; i < gameState.waste.length; i++) {
          firstCycleFlat.add(gameState.waste[i]);
        }
      }
      
      expect(firstCycleFlat.length, 24);
      expect(gameState.stock.length, 0);
      expect(gameState.waste.length, 24);
      
      // Recycle the waste back to stock
      GameLogic.recycleWaste(gameState);
      expect(gameState.stock.length, 24);
      expect(gameState.waste.length, 0);
      
      // Second cycle: flatten all drawn cards
      final secondCycleFlat = <Card>[];
      while (!gameState.stock.isEmpty) {
        final wasteBeforeCount = gameState.waste.length;
        GameLogic.drawCard(gameState, DrawMode.three);
        for (int i = wasteBeforeCount; i < gameState.waste.length; i++) {
          secondCycleFlat.add(gameState.waste[i]);
        }
      }
      
      expect(secondCycleFlat.length, 24);
      
      // Cards should appear in the same order as the first cycle
      for (int i = 0; i < firstCycleFlat.length; i++) {
        expect(
          secondCycleFlat[i],
          equals(firstCycleFlat[i]),
          reason: 'Card at position $i should match first cycle',
        );
      }
    });
    
    test('multiple recycles maintain consistent order', () {
      final gameState = GameState(seedStr: 'stock-cycle-multi-test', drawMode: DrawMode.one);
      
      // Capture first cycle (including the initial card in waste)
      final firstCycle = <Card>[];
      firstCycle.addAll(gameState.waste);
      
      while (!gameState.stock.isEmpty) {
        final wasteBeforeCount = gameState.waste.length;
        GameLogic.drawCard(gameState, DrawMode.one);
        for (int i = wasteBeforeCount; i < gameState.waste.length; i++) {
          firstCycle.add(gameState.waste[i]);
        }
      }
      
      // Do 4 more cycles and verify they're all the same
      for (int cycle = 0; cycle < 4; cycle++) {
        GameLogic.recycleWaste(gameState);
        
        final currentCycle = <Card>[];
        while (!gameState.stock.isEmpty) {
          final wasteBeforeCount = gameState.waste.length;
          GameLogic.drawCard(gameState, DrawMode.one);
          for (int i = wasteBeforeCount; i < gameState.waste.length; i++) {
            currentCycle.add(gameState.waste[i]);
          }
        }
        
        // All cycles should match the original order
        expect(currentCycle, equals(firstCycle), 
          reason: 'Cycle ${cycle + 2} should match original');
      }
    });
  });
}
