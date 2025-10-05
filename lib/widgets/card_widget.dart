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
  bool _hasDragLock = false;

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
    
    if (widget.draggable && widget.card.faceUp && !provider.isLocked && !provider.hasPendingAction) {
      Widget feedbackWidget = cardContent;
      // Capture column and cardIndex early to avoid null issues during drag
      final column = widget.column;
      final cardIndex = widget.cardIndex;
      
      if (column != null && cardIndex != null && cardIndex < column.cards.length) {
        // Show the sub-stack
        // Create a defensive copy of the substack to avoid issues if column changes during drag
        final subStack = List<card_model.Card>.from(column.cards.sublist(cardIndex));
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
            return;
          }

          if (provider.hasPendingAction) {
            return;
          }

          if (await provider.acquireLock('drag')) {
            // Mark as dragging to prevent state updates during drag
            _hasDragLock = true;
            provider.setDragging(true);
            // Start broadcasting drag position
            final position = box.localToGlobal(Offset.zero);
            provider.updateDragPosition(cardId, position.dx, position.dy);
          }
        },
        onDragEnd: (details) async {
          // Stop broadcasting drag position
          if (_hasDragLock) {
            provider.updateDragPosition(cardId, 0, 0); // Reset position
            await provider.releaseLock();
            _hasDragLock = false;
          }
          // Mark drag as complete - this will apply any pending updates
          provider.setDragging(false);
        },
        onDragUpdate: (details) {
          // Update drag position
          if (_hasDragLock) {
            provider.updateDragPosition(cardId, details.globalPosition.dx, details.globalPosition.dy);
          }
        },
      );
    }

    return cardContent;
  }

  Widget _buildCardContent(BuildContext context, double cardWidth, double cardHeight, double tableauSpacing) {
    print('DEBUG: CardWidget _buildCardContent - card: ${widget.card}, faceUp: ${widget.card.faceUp}, dimensions: ${cardWidth}x${cardHeight}');
    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.3),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: widget.card.faceUp ? _buildFaceUp(cardWidth, cardHeight) : _buildFaceDown(cardWidth, cardHeight),
    );
  }

  Widget _buildFaceDown(double cardWidth, double cardHeight) {
    final assetPath = 'assets/cards/svgs/card_face_down.svg';
    debugPrint('🎴 Rendering face-down card: ${widget.card}');
    return SvgPicture.asset(
      assetPath,
      width: cardWidth,
      height: cardHeight,
      fit: BoxFit.contain,
      // No placeholder needed since SVGs are precached
      placeholderBuilder: (context) {
        // Return invisible placeholder - SVGs should be cached already
        return const SizedBox.shrink();
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ ERROR loading card_face_down.svg for ${widget.card}: $error');
        debugPrint('Stack trace: $stackTrace');
        return Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.7),
            border: Border.all(color: Colors.red, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.white, size: 24),
              const SizedBox(height: 4),
              Text(
                'Face Down\nSVG Error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 8),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFaceUp(double cardWidth, double cardHeight) {
    final assetPath = _getCardAssetPath();
    
    return Container(
      width: cardWidth,
      height: cardHeight,
      alignment: Alignment.center,
      child: SvgPicture.asset(
        assetPath,
        width: cardWidth,
        height: cardHeight,
        fit: BoxFit.fill,
        // No placeholder needed since SVGs are precached
        placeholderBuilder: (context) {
          // Return invisible placeholder - SVGs should be cached already
          return const SizedBox.shrink();
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: cardWidth,
            height: cardHeight,
            color: Colors.orange,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('SVG Error', style: TextStyle(color: Colors.white, fontSize: 12)),
                Text(widget.card.toString(), style: TextStyle(color: Colors.white, fontSize: 10)),
              ],
            ),
          );
        },
      ),
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