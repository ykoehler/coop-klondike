import 'card.dart';

/// Represents a suggested move hint with visual location information.
class CardHint {
  final String description;
  final HintType type;
  final Card? card;
  
  // Source location
  final HintLocation sourceLocation;
  final int sourceIndex;
  
  // Destination location
  final HintLocation destinationLocation;
  final int destinationIndex;

  CardHint({
    required this.description,
    required this.type,
    required this.sourceLocation,
    required this.sourceIndex,
    required this.destinationLocation,
    required this.destinationIndex,
    this.card,
  });

  @override
  String toString() => 'CardHint($description, $sourceLocation[$sourceIndex] → $destinationLocation[$destinationIndex])';
}

/// Location of a card on the board
enum HintLocation {
  stock,           // Stock pile
  waste,           // Waste pile
  tableau,         // Tableau column
  foundation,      // Foundation pile
}

/// Types of hints that can be suggested.
enum HintType {
  drawFromStock,      // Click stock to draw cards
  recycleWaste,       // Stock is empty, recycle waste
  moveWasteToTableau, // Move card from waste to tableau
  moveWasteToFoundation, // Move card from waste to foundation
  moveTableauToFoundation, // Move card from tableau to foundation
  moveTableauToTableau, // Move card from tableau to another tableau
  moveFoundationToTableau, // Undo a card from foundation
}
