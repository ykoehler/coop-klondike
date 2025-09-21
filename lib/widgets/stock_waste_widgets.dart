import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card.dart' as card_model;
import '../providers/game_provider.dart';
import 'card_widget.dart';

class StockPileWidget extends StatelessWidget {
  const StockPileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);
    final hasCards = !provider.gameState.stock.isEmpty;

    return GestureDetector(
      onTap: hasCards ? () => provider.drawCard() : (provider.gameState.waste.isNotEmpty ? () => provider.recycleWaste() : null),
      child: Container(
        width: 80,
        height: 112,
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

    return Container(
      width: 80,
      height: 112,
      child: waste.isNotEmpty
          ? CardWidget(card: waste.last, draggable: true)
          : Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Waste',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
    );
  }
}