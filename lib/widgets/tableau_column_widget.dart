import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card.dart' as card_model;
import '../models/tableau_column.dart';
import '../providers/game_provider.dart';
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
    return DragTarget<card_model.Card>(
      onWillAcceptWithDetails: (details) => _canAcceptCard(details.data),
      onAcceptWithDetails: (details) => _onAcceptCard(context, details.data),
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 80,
          height: 400, // Fixed height for column
          decoration: BoxDecoration(
            border: candidateData.isNotEmpty
                ? Border.all(color: Colors.green, width: 2)
                : null,
          ),
          child: Stack(
            children: _buildCardStack(),
          ),
        );
      },
    );
  }

  List<Widget> _buildCardStack() {
    List<Widget> widgets = [];
    for (int i = 0; i < column.cards.length; i++) {
      final card = column.cards[i];
      widgets.add(
        Positioned(
          top: i * 20.0, // Offset each card
          child: CardWidget(
            card: card,
            draggable: card.faceUp,
            column: column,
            cardIndex: i,
          ),
        ),
      );
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