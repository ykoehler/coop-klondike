import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../utils/responsive_utils.dart';
import 'card_widget.dart';

class StockPileWidget extends StatelessWidget {
  const StockPileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);
    final hasCards = !provider.gameState.stock.isEmpty;
    final cardWidth = context.cardWidth;
    final cardHeight = context.cardHeight;
    // Disable interactions if there's a pending action OR if the game is locked
    final interactionsDisabled = provider.hasPendingAction || provider.isLocked;

    VoidCallback? onTap;
    if (!interactionsDisabled) {
      if (hasCards) {
        onTap = () {
          debugPrint('🎴 STOCK TAP: Drawing card (stock=${provider.gameState.stock.length})');
          unawaited(provider.drawCard());
        };
      } else if (provider.gameState.waste.isNotEmpty) {
        onTap = () {
          debugPrint('♻️ STOCK TAP: Recycling waste (waste=${provider.gameState.waste.length})');
          unawaited(provider.recycleWaste());
        };
      }
    } else {
      debugPrint('🚫 STOCK TAP: Interactions disabled (pending=${provider.hasPendingAction}, locked=${provider.isLocked})');
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          color: interactionsDisabled 
              ? Colors.grey[400]  // Visual feedback when disabled
              : (hasCards ? Colors.blue : Colors.grey[300]),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: Center(
          child: Text(
            hasCards ? 'Draw' : 'Empty',
            style: TextStyle(
              color: interactionsDisabled
                  ? Colors.grey[600]
                  : (hasCards ? Colors.white : Colors.grey[600]),
              fontSize: context.cardFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class WastePileWidget extends StatelessWidget {
  const WastePileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);
    final waste = provider.gameState.waste;
    final cardWidth = context.cardWidth;
    final cardHeight = context.cardHeight;

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: waste.isNotEmpty
          ? CardWidget(
              card: waste.last,
              draggable: true,
              width: cardWidth,
              height: cardHeight,
            )
          : Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Waste',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: context.cardFontSize,
                  ),
                ),
              ),
            ),
    );
  }
}
