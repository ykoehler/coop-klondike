class DragState {
  final String cardId;
  final double x;
  final double y;
  final int timestamp;
  final String playerId;

  DragState({
    required this.cardId,
    required this.x,
    required this.y,
    required this.timestamp,
    required this.playerId,
  });

  Map<String, dynamic> toJson() => {
    'cardId': cardId,
    'x': x,
    'y': y,
    'timestamp': timestamp,
    'playerId': playerId,
  };

  static DragState? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    
    final cardId = json['cardId'];
    final x = json['x'];
    final y = json['y'];
    final timestamp = json['timestamp'];
    final playerId = json['playerId'];

    // Return null if any required field is missing
    if (cardId == null || x == null || y == null || timestamp == null || playerId == null) {
      return null;
    }

    return DragState(
      cardId: cardId.toString(),
      x: (x as num).toDouble(),
      y: (y as num).toDouble(),
      timestamp: timestamp as int,
      playerId: playerId.toString(),
    );
  }

  @override
  String toString() => 'DragState(cardId: $cardId, x: $x, y: $y, playerId: $playerId)';
}