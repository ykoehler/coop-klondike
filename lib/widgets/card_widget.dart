import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../models/card.dart' as card_model;
import '../models/tableau_column.dart';
import '../utils/responsive_utils.dart';
import '../providers/game_provider.dart';

class CardWidget extends StatefulWidget {
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
  State<CardWidget> createState() => _CardWidgetState();
}

class _CardWidgetState extends State<CardWidget> {

  @override
  Widget build(BuildContext context) {
    late final GameProvider provider;
    try {
      provider = Provider.of<GameProvider>(context);
    } catch (e) {
      // If provider is not available, return basic card widget
      return _buildCardContent(context, context.cardWidth, context.cardHeight, ResponsiveUtils.getTableauCardSpacing(context));
    }

    final dragState = provider.currentDrag;
    final cardId = '${widget.card.suit}_${widget.card.rank}';
    
    // Use responsive sizing if width/height not provided
    final cardWidth = widget.width ?? context.cardWidth;
    final cardHeight = widget.height ?? context.cardHeight;
    final tableauSpacing = ResponsiveUtils.getTableauCardSpacing(context);

    // Check if this card is being dragged by another player - use visual indicator instead of Positioned
    bool isBeingDraggedByOther = dragState != null &&
        dragState.cardId == cardId &&
        dragState.playerId != provider.playerId;
    
    Widget cardContent = _buildCardContent(context, cardWidth, cardHeight, tableauSpacing);

    // Add visual indication if being dragged by another player
    if (isBeingDraggedByOther) {
      cardContent = Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue, width: 3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Opacity(
          opacity: 0.7,
          child: cardContent,
        ),
      );
    }

    // Add debug info
    print('Card ${widget.card}: draggable=${widget.draggable}, faceUp=${widget.card.faceUp}, isLocked=${provider.isLocked}');
    
    if (widget.draggable && widget.card.faceUp && !provider.isLocked) {
      Widget feedbackWidget = cardContent;
      if (widget.column != null && widget.cardIndex != null) {
        // Show the sub-stack
        final subStack = widget.column!.cards.sublist(widget.cardIndex!);
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
        data: widget.card,
        feedback: Transform.scale(
          scale: context.dragFeedbackScale,
          child: feedbackWidget,
        ),
        childWhenDragging: Opacity(
          opacity: 0.5,
          child: cardContent,
        ),
        child: cardContent,
        onDragStarted: () async {
          // Capture RenderBox before async operation to avoid context issues
          final RenderBox? box = context.findRenderObject() as RenderBox?;
          if (box == null) {
            print('Warning: RenderBox not available for drag start');
            return;
          }

          if (await provider.acquireLock('drag')) {
            // Start broadcasting drag position
            final position = box.localToGlobal(Offset.zero);
            provider.updateDragPosition(cardId, position.dx, position.dy);
          }
        },
        onDragEnd: (_) async {
          // Stop broadcasting drag position
          await provider.releaseLock();
          provider.updateDragPosition(cardId, 0, 0); // Reset position
        },
        onDragUpdate: (details) {
          // Update drag position
          provider.updateDragPosition(cardId, details.globalPosition.dx, details.globalPosition.dy);
        },
      );
    }

    return cardContent;
  }

  Widget _buildCardContent(BuildContext context, double cardWidth, double cardHeight, double tableauSpacing) {
    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: widget.card.faceUp ? _buildFaceUp(cardWidth, cardHeight) : _buildFaceDown(cardWidth, cardHeight),
    );
  }

  Widget _buildFaceDown(double cardWidth, double cardHeight) {
    final assetPath = 'assets/cards/svgs/card_face_down.svg';
    print('DEBUG: Loading face down card from: $assetPath');
    return SvgPicture.asset(
      assetPath,
      width: cardWidth,
      height: cardHeight,
      fit: BoxFit.contain,
      placeholderBuilder: (context) {
        print('DEBUG: Face down card placeholder triggered');
        return Container(
          width: cardWidth,
          height: cardHeight,
          color: Colors.blue,
          child: const Text('SVG Loading...', style: TextStyle(color: Colors.white)),
        );
      },
    );
  }

  Widget _buildFaceUp(double cardWidth, double cardHeight) {
    final assetPath = _getCardAssetPath();
    print('DEBUG: Loading face up card from: $assetPath');
    return SvgPicture.asset(
      assetPath,
      width: cardWidth,
      height: cardHeight,
      fit: BoxFit.contain,
      placeholderBuilder: (context) {
        print('DEBUG: Face up card placeholder triggered for: $assetPath');
        return Container(
          width: cardWidth,
          height: cardHeight,
          color: Colors.red,
          child: Text('SVG Loading...\n$assetPath', style: TextStyle(color: Colors.white, fontSize: 10)),
        );
      },
    );
  }

  String _getCardAssetPath() {
    final suitName = _getSuitName(widget.card.suit);
    final rankText = _getRankText(widget.card.rank).toLowerCase();
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