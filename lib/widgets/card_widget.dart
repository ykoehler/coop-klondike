import 'package:flutter/material.dart';
import '../models/card.dart' as card_model;
import '../models/tableau_column.dart';

class CardWidget extends StatelessWidget {
  final card_model.Card card;
  final bool draggable;
  final double width;
  final double height;
  final TableauColumn? column;
  final int? cardIndex;

  const CardWidget({
    super.key,
    required this.card,
    this.draggable = true,
    this.width = 80,
    this.height = 112,
    this.column,
    this.cardIndex,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: card.faceUp ? _buildFaceUp() : _buildFaceDown(),
    );

    if (draggable && card.faceUp) {
      Widget feedbackWidget = cardContent;
      if (column != null && cardIndex != null) {
        // Show the sub-stack
        final subStack = column!.cards.sublist(cardIndex!);
        feedbackWidget = SizedBox(
          width: width,
          height: height + (subStack.length - 1) * 20.0,
          child: Stack(
            children: List.generate(subStack.length, (index) {
              return Positioned(
                top: index * 20.0,
                child: CardWidget(
                  card: subStack[index],
                  draggable: false,
                  width: width,
                  height: height,
                ),
              );
            }),
          ),
        );
      }
      return Draggable<card_model.Card>(
        data: card,
        feedback: Transform.scale(
          scale: 1.1,
          child: feedbackWidget,
        ),
        childWhenDragging: Opacity(
          opacity: 0.5,
          child: cardContent,
        ),
        child: cardContent,
      );
    }

    return cardContent;
  }

  Widget _buildFaceDown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '♠',
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildFaceUp() {
    final suitColor = card.isRed ? Colors.red : Colors.black;
    final suitSymbol = _getSuitSymbol(card.suit);
    final rankText = _getRankText(card.rank);

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                rankText,
                style: TextStyle(
                  color: suitColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                suitSymbol,
                style: TextStyle(
                  color: suitColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Center(
            child: Text(
              suitSymbol,
              style: TextStyle(
                color: suitColor,
                fontSize: 32,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                suitSymbol,
                style: TextStyle(
                  color: suitColor,
                  fontSize: 16,
                ),
              ),
              Text(
                rankText,
                style: TextStyle(
                  color: suitColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getSuitSymbol(card_model.Suit suit) {
    switch (suit) {
      case card_model.Suit.hearts:
        return '♥';
      case card_model.Suit.diamonds:
        return '♦';
      case card_model.Suit.clubs:
        return '♣';
      case card_model.Suit.spades:
        return '♠';
    }
  }

  String _getRankText(card_model.Rank rank) {
    switch (rank) {
      case card_model.Rank.ace:
        return 'A';
      case card_model.Rank.jack:
        return 'J';
      case card_model.Rank.queen:
        return 'Q';
      case card_model.Rank.king:
        return 'K';
      default:
        return (rank.index + 1).toString();
    }
  }
}