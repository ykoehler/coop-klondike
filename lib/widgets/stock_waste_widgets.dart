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

    return GestureDetector(
      onTap: hasCards ? () => provider.drawCard() : (provider.gameState.waste.isNotEmpty ? () => provider.recycleWaste() : null),
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

    print('DEBUG: WastePileWidget build - waste has ${waste.length} cards, dimensions: ${cardWidth}x${cardHeight}');

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