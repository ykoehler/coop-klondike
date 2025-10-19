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

        // Check if this location is the hint destination
        if (hint.destinationLocation == location &&
            hint.destinationIndex == locationIndex) {
          isDestinationLocation = true;
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
