import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../utils/responsive_utils.dart';
import 'card_widget.dart';
import '../models/card.dart' as card_model;

class StockPileWidget extends StatelessWidget {
  const StockPileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Selector to only rebuild when stock length or waste length changes
    // We don't disable the stock pile visually during pending actions because:
    // 1. The internal hasPendingAction check prevents double-clicks anyway
    // 2. Showing the disabled state after a drag creates an unwanted visual flash
    // 3. Users can see their move is being processed through card animations
    return Selector<GameProvider, ({bool hasCards, int wasteLength})>(
      selector: (_, provider) => (
        hasCards: !provider.gameState.stock.isEmpty,
        wasteLength: provider.gameState.waste.length,
      ),
      builder: (context, data, __) {
        final cardWidth = context.cardWidth;
        final cardHeight = context.cardHeight;
        final hasCards = data.hasCards;

        final provider = Provider.of<GameProvider>(context, listen: false);

        VoidCallback? onTap;
        if (hasCards) {
          onTap = () {
            debugPrint('🎴 STOCK TAP: Drawing card (stock=${provider.gameState.stock.length})');
            unawaited(provider.drawCard());
          };
        } else if (data.wasteLength > 0) {
          onTap = () {
            debugPrint('♻️ STOCK TAP: Recycling waste (waste=${data.wasteLength})');
            unawaited(provider.recycleWaste());
          };
        }

        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: cardWidth,
            height: cardHeight,
            decoration: BoxDecoration(
              color: hasCards ? Colors.blue : Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: Center(
              child: Text(
                hasCards ? 'Draw' : 'Empty',
                style: TextStyle(
                  color: hasCards ? Colors.white : Colors.grey[600],
                  fontSize: context.cardFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class WastePileWidget extends StatelessWidget {
  const WastePileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Selector to only rebuild when waste cards change
    // This prevents unnecessary rebuilds from other provider state changes (like drag state)
    return Selector<GameProvider, List<card_model.Card>>(
      selector: (_, provider) => provider.gameState.waste,
      builder: (context, waste, __) {
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
      },
    );
  }
}
