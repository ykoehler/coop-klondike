import 'dart:async';
import 'dart:js_util' as js_util;

import '../models/card.dart' as model;
import '../providers/game_provider.dart';
import '../models/game_state.dart';

void registerTestHooksImpl(GameProvider provider) {
  final hooks = js_util.newObject();

  Future<void> waitForIdle() async {
    final startTime = DateTime.now();
    final timeout = Duration(seconds: 10);
    
    while (provider.isInitializing || provider.hasPendingAction) {
      if (DateTime.now().difference(startTime) > timeout) {
        final msg = 'waitForIdle timed out after ${timeout.inSeconds}s. '
          'isInitializing=${provider.isInitializing}, '
          'hasPendingAction=${provider.hasPendingAction}';
        print('TIMEOUT ERROR: $msg');
        throw TimeoutException(msg);
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    print('waitForIdle: completed! isInit=${provider.isInitializing}, hasPending=${provider.hasPendingAction}');
  }

  Object futureToPromise<T>(Future<T> future) {
    final promiseConstructor = js_util.getProperty(js_util.globalThis, 'Promise');
    return js_util.callConstructor(promiseConstructor, [
      js_util.allowInterop((resolve, reject) {
        future.then(
          (value) => resolve(value),
          onError: (Object error, StackTrace stackTrace) => reject(error.toString()),
        );
      }),
    ]);
  }

  String cardSignature(model.Card card) => '${card.rank.name}-${card.suit.name}';

  List<String> stockSnapshot() => provider.gameState.stock.cards
      .map(cardSignature)
      .toList(growable: false);

  List<String> wasteSnapshot() => provider.gameState.waste
      .map(cardSignature)
      .toList(growable: false);

  js_util.setProperty(hooks, 'waitForIdle', js_util.allowInterop(() => futureToPromise(waitForIdle())));

  Future<void> configureGame(String seed, String drawMode) async {
    try {
      // First wait for initial setup to complete  
      print('TEST HOOKS: Starting configureGame, isInit=${provider.isInitializing}');
      
      // Wait for the provider to finish initializing
      print('TEST HOOKS: Waiting for initialization...');
      await waitForIdle();
      print('TEST HOOKS: After first waitForIdle, isInit=${provider.isInitializing}');
      
      final targetMode = drawMode == 'one' ? DrawMode.one : DrawMode.three;
      
      // Change the draw mode first (this updates _currentDrawMode)
      await provider.changeDrawMode(targetMode);
      await waitForIdle();
      
      // Now redeal with the new mode already set
      if (seed.isNotEmpty) {
        await provider.redealWithSeed(seed);
        await waitForIdle();
      }
      
      // Mark setup as complete to prevent the dialog from showing
      provider.markSetupComplete();
      print('TEST HOOKS: After markSetupComplete, isSetup=${provider.isInitialSetup}');
      
      // Wait for any pending actions to complete
      print('TEST HOOKS: Waiting for idle after config...');
      await waitForIdle();
      print('TEST HOOKS: Done! isInit=${provider.isInitializing}, isSetup=${provider.isInitialSetup}, mode=${provider.gameState.drawMode}');
    } catch (e) {
      print('TEST HOOKS ERROR: $e');
      rethrow;
    }
  }

  js_util.setProperty(hooks, 'configureGame', js_util.allowInterop((String seed, String drawMode) => futureToPromise(configureGame(seed, drawMode))));

  js_util.setProperty(hooks, 'getStockSnapshot', js_util.allowInterop(() => js_util.jsify(stockSnapshot())));

  js_util.setProperty(hooks, 'getWasteSnapshot', js_util.allowInterop(() => js_util.jsify(wasteSnapshot())));

  js_util.setProperty(hooks, 'getStockCount', js_util.allowInterop(() => provider.gameState.stock.length));

  js_util.setProperty(hooks, 'getWasteCount', js_util.allowInterop(() => provider.gameState.waste.length));

  // Get Firebase and provider state for race condition testing
  js_util.setProperty(hooks, 'getPendingActionCount', js_util.allowInterop(() => provider.hasPendingAction ? 1 : 0));
  
  js_util.setProperty(hooks, 'getDebugState', js_util.allowInterop(() {
    return js_util.jsify({
      'isInitializing': provider.isInitializing,
      'hasPendingAction': provider.hasPendingAction,
      'isInitialSetup': provider.isInitialSetup,
      'isLocked': provider.isLocked,
      'isLockedByMe': provider.isLockedByMe,
    });
  }));
  
  js_util.setProperty(hooks, 'getTotalCardCount', js_util.allowInterop(() {
    int total = 0;
    for (final column in provider.gameState.tableau) {
      total += column.cards.length;
    }
    total += provider.gameState.stock.length;
    total += provider.gameState.waste.length;
    for (final foundation in provider.gameState.foundations) {
      total += foundation.cards.length;
    }
    return total;
  }));
  
  js_util.setProperty(hooks, 'validateCardIntegrity', js_util.allowInterop(() {
    final allCards = <model.Card>[];
    for (final column in provider.gameState.tableau) {
      allCards.addAll(column.cards);
    }
    allCards.addAll(provider.gameState.stock.cards);
    allCards.addAll(provider.gameState.waste);
    for (final foundation in provider.gameState.foundations) {
      allCards.addAll(foundation.cards);
    }
    
    final total = allCards.length;
    final unique = allCards.toSet().length;
    
    return js_util.jsify({
      'total': total,
      'unique': unique,
      'valid': total == 52 && unique == 52,
      'duplicates': total != unique,
      'missing': total < 52,
      'extra': total > 52,
    });
  }));

  Future<String> tapStock() async {
    try {
      // Wait for any pending actions to complete first
      await waitForIdle();
      
      final beforeStock = stockSnapshot();
      final beforeWasteCount = provider.gameState.waste.length;

      String result;
      if (beforeStock.isEmpty) {
        if (beforeWasteCount > 0) {
          await provider.recycleWaste();
          await waitForIdle();
          result = 'recycle';
        } else {
          result = 'noop';
        }
      } else {
        await provider.drawCard();
        await waitForIdle();
        result = 'draw';
      }
      
      return result;
    } catch (e) {
      print('TAP STOCK ERROR: $e');
      rethrow;
    }
  }

  js_util.setProperty(hooks, 'tapStock', js_util.allowInterop(() => futureToPromise(tapStock())));

  // Get tableau column information for testing
  js_util.setProperty(hooks, 'getTableauColumn', js_util.allowInterop((int columnIndex) {
    if (columnIndex < 0 || columnIndex >= provider.gameState.tableau.length) {
      return null;
    }
    final column = provider.gameState.tableau[columnIndex];
    return js_util.jsify(
      column.cards.map((card) {
        return <String, dynamic>{
          'suit': card.suit.name,
          'rank': card.rank.name,
          'faceUp': card.faceUp,
        };
      }).toList(),
    );
  }));

  // Move tableau to tableau for testing
  Future<String> moveTableauToTableau(int fromIndex, int toIndex, int cardCount) async {
    try {
      await waitForIdle();
      
      if (fromIndex < 0 || fromIndex >= 7 || toIndex < 0 || toIndex >= 7) {
        return 'invalid-indices';
      }
      
      await provider.moveTableauToTableau(fromIndex, toIndex, cardCount);
      await waitForIdle();
      
      return 'success';
    } catch (e) {
      print('MOVE TABLEAU ERROR: $e');
      return 'error: $e';
    }
  }

  js_util.setProperty(hooks, 'moveTableauToTableau', 
    js_util.allowInterop((int from, int to, int count) => 
      futureToPromise(moveTableauToTableau(from, to, count))));

  // Get all tableau state for debugging
  js_util.setProperty(hooks, 'getTableauState', js_util.allowInterop(() {
    return js_util.jsify(
      List.generate(7, (i) {
        final column = provider.gameState.tableau[i];
        final topCardMap = column.topCard != null ? <String, dynamic>{
          'suit': column.topCard!.suit.name,
          'rank': column.topCard!.rank.name,
          'faceUp': column.topCard!.faceUp,
        } : null;
        
        return <String, dynamic>{
          'index': i,
          'cardCount': column.cards.length,
          'isEmpty': column.isEmpty,
          'topCard': topCardMap,
          'cards': column.cards.map((card) {
            return <String, dynamic>{
              'suit': card.suit.name,
              'rank': card.rank.name,
              'faceUp': card.faceUp,
            };
          }).toList(),
        };
      }),
    );
  }));

  js_util.setProperty(js_util.globalThis, 'testHooks', hooks);
  js_util.setProperty(js_util.globalThis, 'testHooksReady', true);
}
