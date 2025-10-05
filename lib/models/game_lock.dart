class GameLock {
  final bool isLocked;
  final String? playerId;
  final int timestamp;
  final String? action;

  GameLock({
    required this.isLocked,
    this.playerId,
    required this.timestamp,
    this.action,
  });

  Map<String, dynamic> toJson() => {
    'isLocked': isLocked,
    'locked': isLocked, // legacy compatibility for existing data
    'playerId': playerId,
    'timestamp': timestamp,
    'action': action,
  };

  static GameLock fromJson(Map<String, dynamic> json) => GameLock(
    isLocked: (json.containsKey('isLocked')
            ? json['isLocked']
            : json['locked']) as bool? ?? false,
    playerId: json['playerId'] as String?,
    timestamp: (json['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    action: json['action'] as String?,
  );

  bool get isLockExpired => DateTime.now().millisecondsSinceEpoch - timestamp > 30000; // Lock expires after 30 seconds

  @override
  String toString() => 'GameLock(isLocked: $isLocked, playerId: $playerId, action: $action)';
}