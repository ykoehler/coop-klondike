import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/card.dart' as card_model;
import '../models/tableau_column.dart';
import '../utils/responsive_utils.dart';

class CardWidget extends StatelessWidget {
  final card_model.Card card;
  final bool draggable;
  final double? width;
  final double? height;
  final TableauColumn? column;
  final int? cardIndex;

  const CardWidget({
    super.key,
    required this.card,
    this.draggable = true,
    this.width,
    this.height,
    this.column,
    this.cardIndex,
  });

  @override
  Widget build(BuildContext context) {
    // Use responsive sizing if width/height not provided
    final cardWidth = width ?? context.cardWidth;
    final cardHeight = height ?? context.cardHeight;
    final tableauSpacing = ResponsiveUtils.getTableauCardSpacing(context);
    
    Widget cardContent = SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: card.faceUp ? _buildFaceUp(cardWidth, cardHeight) : _buildFaceDown(cardWidth, cardHeight),
    );

    if (draggable && card.faceUp) {
      Widget feedbackWidget = cardContent;
      if (column != null && cardIndex != null) {
        // Show the sub-stack
        final subStack = column!.cards.sublist(cardIndex!);
        feedbackWidget = SizedBox(
          width: cardWidth,
          height: cardHeight + (subStack.length - 1) * tableauSpacing,
          child: Stack(
            children: List.generate(subStack.length, (index) {
              return Positioned(
                top: index * tableauSpacing,
                child: CardWidget(
                  card: subStack[index],
                  draggable: false,
                  width: cardWidth,
                  height: cardHeight,
                ),
              );
            }),
          ),
        );
      }
      return Draggable<card_model.Card>(
        data: card,
        feedback: Transform.scale(
          scale: context.dragFeedbackScale,
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

  Widget _buildFaceDown(double cardWidth, double cardHeight) {
    return SvgPicture.asset(
      'assets/cards/svgs/card_face_down.svg',
      width: cardWidth,
      height: cardHeight,
      fit: BoxFit.contain,
    );
  }

  Widget _buildFaceUp(double cardWidth, double cardHeight) {
    final assetPath = _getCardAssetPath();
    return SvgPicture.asset(
      assetPath,
      width: cardWidth,
      height: cardHeight,
      fit: BoxFit.contain,
    );
  }

  String _getCardAssetPath() {
    final suitName = _getSuitName(card.suit);
    final rankText = _getRankText(card.rank).toLowerCase();
    return 'assets/cards/svgs/${suitName}_$rankText.svg';
  }

  String _getSuitName(card_model.Suit suit) {
    switch (suit) {
      case card_model.Suit.hearts:
        return 'hearts';
      case card_model.Suit.diamonds:
        return 'diamonds';
      case card_model.Suit.clubs:
        return 'clubs';
      case card_model.Suit.spades:
        return 'spades';
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