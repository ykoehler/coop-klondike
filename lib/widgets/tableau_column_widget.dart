import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card.dart' as card_model;
import '../models/tableau_column.dart';
import '../providers/game_provider.dart';
import '../utils/responsive_utils.dart';
import 'card_widget.dart';

class TableauColumnWidget extends StatelessWidget {
  final TableauColumn column;
  final int columnIndex;

  const TableauColumnWidget({
    super.key,
    required this.column,
    required this.columnIndex,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = context.cardWidth;
    final cardHeight = context.cardHeight;
    final cardSpacing = context.tableauCardSpacing;

    // Fixed height for all columns to ensure top alignment
    // Maximum cards per column (7 initial + reasonable buffer for gameplay)
    const maxCardsPerColumn = 20;
    final fixedHeight = cardHeight + (maxCardsPerColumn - 1) * cardSpacing;

    return DragTarget<card_model.Card>(
      onWillAcceptWithDetails: (details) => _canAcceptCard(details.data),
      onAcceptWithDetails: (details) => _onAcceptCard(context, details.data),
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: cardWidth,
          height: fixedHeight,
          decoration: BoxDecoration(
            border: candidateData.isNotEmpty
                ? Border.all(color: Colors.green, width: 2)
                : null,
          ),
          child: Stack(
            children: _buildCardStack(context, cardWidth, cardHeight, cardSpacing),
          ),
        );
      },
    );
  }

  List<Widget> _buildCardStack(BuildContext context, double cardWidth, double cardHeight, double cardSpacing) {
    print('DEBUG: TableauColumnWidget _buildCardStack - column has ${column.cards.length} cards, dimensions: ${cardWidth}x${cardHeight}, spacing: $cardSpacing');
    List<Widget> widgets = [];
    double currentTop = 0.0;

    for (int i = 0; i < column.cards.length; i++) {
      final card = column.cards[i];

      // Use half spacing for face-down cards, normal spacing for face-up cards
      final effectiveSpacing = card.faceUp ? cardSpacing : cardSpacing * 0.5;

      print('DEBUG: TableauColumnWidget card $i - ${card}, faceUp: ${card.faceUp}, position: $currentTop, effectiveSpacing: $effectiveSpacing');

      widgets.add(
        Positioned(
          top: currentTop,
          child: CardWidget(
            card: card,
            draggable: card.faceUp,
            width: cardWidth,
            height: cardHeight,
            column: column,
            cardIndex: i,
          ),
        ),
      );

      // Accumulate the effective spacing for the next card position
      currentTop += effectiveSpacing;
    }
    return widgets;
  }

  bool _canAcceptCard(card_model.Card? card) {
    if (card == null) return false;
    return column.canAcceptCard(card);
  }

  void _onAcceptCard(BuildContext context, card_model.Card card) {
    final provider = Provider.of<GameProvider>(context, listen: false);

    // Determine where the card came from
    final gameState = provider.gameState;

    // Check waste
    if (gameState.waste.isNotEmpty && gameState.waste.last == card) {
      provider.moveWasteToTableau(columnIndex);
      return;
    }

    // Check foundations
    for (int i = 0; i < gameState.foundations.length; i++) {
      if (gameState.foundations[i].topCard == card) {
        provider.moveFoundationToTableau(i, columnIndex);
        return;
      }
    }

    // Check other tableau columns
    for (int i = 0; i < gameState.tableau.length; i++) {
      if (i != columnIndex) {
        final fromColumn = gameState.tableau[i];
        final cardIndex = fromColumn.cards.indexOf(card);
        if (cardIndex != -1 && card.faceUp) {
          final cardCount = fromColumn.cards.length - cardIndex;
          provider.moveTableauToTableau(i, columnIndex, cardCount);
          return;
        }
      }
    }
  }
}