import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/hint.dart';
import '../models/card.dart' as card_model;
import '../providers/game_provider.dart';

/// Wraps a card widget with visual hint highlighting when applicable.
/// Shows a rounded rectangle around the source card and destination location.
class HintHighlightedCard extends StatelessWidget {
  final Widget child;
  final card_model.Card? card;
  final HintLocation? location;
  final int? locationIndex;
  final double borderWidth;
  final Color sourceColor;
  final Color destinationColor;
  final double borderRadius;

  const HintHighlightedCard({
    super.key,
    required this.child,
    this.card,
    this.location,
    this.locationIndex,
    this.borderWidth = 2.5,
    this.sourceColor = const Color(0xFF4CAF50),
    this.destinationColor = const Color(0xFFFFD700),
    this.borderRadius = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, _) {
        final hint = provider.currentVisualHint;
        
        if (hint == null || card == null || location == null) {
          return child;
        }

        bool isSourceCard = false;
        bool isDestinationLocation = false;

        // Check if this card is the hint source
        if (hint.card != null &&
            hint.card!.suit == card!.suit &&
            hint.card!.rank == card!.rank &&
            hint.sourceLocation == location &&
            hint.sourceIndex == locationIndex) {
          isSourceCard = true;
        }

        // Check if this is the hint destination
        // IMPORTANT: For tableau columns, only the TOP card should be highlighted as the destination.
        // This prevents highlighting all cards in the column including face-down cards.
        if (hint.destinationLocation == location &&
            hint.destinationIndex == locationIndex) {
          if (hint.destinationLocation == HintLocation.tableau) {
            // For tableau destinations, only highlight the top card of the destination column.
            // Get the game state to check if this card is the top card of the destination column.
            final gameState = provider.gameState;
            if (locationIndex != null && 
                locationIndex! >= 0 && 
                locationIndex! < gameState.tableau.length) {
              final destinationColumn = gameState.tableau[locationIndex!];
              if (destinationColumn.topCard != null &&
                  destinationColumn.topCard!.suit == card!.suit &&
                  destinationColumn.topCard!.rank == card!.rank) {
                isDestinationLocation = true;
              }
            }
            // If the tableau column is empty, highlight nothing (unless it's a King destination)
            // The UI will show the drop zone is valid anyway
          } else {
            // For non-tableau locations (waste, stock, foundation), 
            // highlight the single card in that location
            isDestinationLocation = true;
          }
        }

        if (!isSourceCard && !isDestinationLocation) {
          return child;
        }

        final color = isSourceCard ? sourceColor : destinationColor;

        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: color,
              width: borderWidth,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}
