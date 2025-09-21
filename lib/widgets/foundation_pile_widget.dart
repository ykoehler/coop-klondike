import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card.dart' as card_model;
import '../models/foundation_pile.dart';
import '../providers/game_provider.dart';
import 'card_widget.dart';

class FoundationPileWidget extends StatelessWidget {
  final FoundationPile pile;
  final int pileIndex;

  const FoundationPileWidget({
    super.key,
    required this.pile,
    required this.pileIndex,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<card_model.Card>(
      onWillAccept: (card) => _canAcceptCard(card),
      onAccept: (card) => _onAcceptCard(context, card),
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 80,
          height: 112,
          decoration: BoxDecoration(
            border: candidateData.isNotEmpty
                ? Border.all(color: Colors.green, width: 2)
                : Border.all(color: Colors.grey, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: pile.isEmpty
              ? _buildEmptyPlaceholder()
              : CardWidget(card: pile.topCard!, draggable: false),
        );
      },
    );
  }

  Widget _buildEmptyPlaceholder() {
    return Center(
      child: Container(
        width: 60,
        height: 90,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            pile.suit.name[0].toUpperCase(),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  bool _canAcceptCard(card_model.Card? card) {
    if (card == null) return false;
    return pile.canAcceptCard(card);
  }

  void _onAcceptCard(BuildContext context, card_model.Card card) {
    final provider = Provider.of<GameProvider>(context, listen: false);

    // Determine where the card came from
    final gameState = provider.gameState;

    // Check waste
    if (gameState.waste.isNotEmpty && gameState.waste.last == card) {
      provider.moveWasteToFoundation(pileIndex);
      return;
    }

    // Check tableau
    for (int i = 0; i < gameState.tableau.length; i++) {
      if (gameState.tableau[i].topCard == card) {
        provider.moveTableauToFoundation(i, pileIndex);
        return;
      }
    }
  }
}