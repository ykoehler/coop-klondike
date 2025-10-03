import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card.dart' as card_model;
import '../models/foundation_pile.dart';
import '../providers/game_provider.dart';
import '../utils/responsive_utils.dart';
import 'card_widget.dart';

class FoundationPileWidget extends StatefulWidget {
  final FoundationPile pile;
  final int pileIndex;

  const FoundationPileWidget({
    super.key,
    required this.pile,
    required this.pileIndex,
  });

  @override
  State<FoundationPileWidget> createState() => _FoundationPileWidgetState();
}

class _FoundationPileWidgetState extends State<FoundationPileWidget> {
  @override
  Widget build(BuildContext context) {
    final cardWidth = context.cardWidth;
    final cardHeight = context.cardHeight;

    return DragTarget<card_model.Card>(
      onWillAcceptWithDetails: (details) => _canAcceptCard(details.data),
      onAcceptWithDetails: (details) => _onAcceptCard(context, details.data),
      builder: (context, candidateData, rejectedData) {
        return Container(
          key: Key('foundation-${widget.pileIndex}'),
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            border: candidateData.isNotEmpty
                ? Border.all(color: Colors.green, width: 2)
                : Border.all(color: Colors.grey, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: widget.pile.isEmpty
              ? _buildEmptyPlaceholder(context, cardWidth, cardHeight)
              : CardWidget(
                  card: widget.pile.topCard!,
                  draggable: false,
                  width: cardWidth,
                  height: cardHeight,
                ),
        );
      },
    );
  }

  Widget _buildEmptyPlaceholder(
    BuildContext context,
    double cardWidth,
    double cardHeight,
  ) {
    return Center(
      child: Container(
        width: cardWidth * 0.75,
        height: cardHeight * 0.80,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            widget.pile.suit != null
                ? widget.pile.suit!.name[0].toUpperCase()
                : 'A',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: context.cardFontSize * 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  bool _canAcceptCard(card_model.Card? card) {
    if (card == null) return false;
    return widget.pile.canAcceptCard(card);
  }

  void _onAcceptCard(BuildContext context, card_model.Card card) {
    final provider = Provider.of<GameProvider>(context, listen: false);

    // Determine where the card came from
    final gameState = provider.gameState;

    // Check waste
    if (gameState.waste.isNotEmpty && gameState.waste.last == card) {
      unawaited(provider.moveWasteToFoundation(widget.pileIndex));
      return;
    }

    // Check tableau
    for (int i = 0; i < gameState.tableau.length; i++) {
      if (gameState.tableau[i].cards.isNotEmpty &&
          gameState.tableau[i].topCard == card) {
        unawaited(provider.moveTableauToFoundation(i, widget.pileIndex));
        return;
      }
    }
  }
}
