import 'dart:math';

/// Utility class for generating and deriving seeds for deterministic deck shuffling.
/// Seeds are human-readable passphrases that ensure reproducible game deals across multiplayer sessions.
/// All players using the same seed will get identical shuffles, synced via Firebase GameState.
class SeedGenerator {
  // Static list of English words for generating readable, memorable seeds.
  static const List<String> _wordList = [
    'apple', 'blue', 'cat', 'dog', 'elephant', 'fox', 'grape', 'house', 'ice', 'jump',
    'kite', 'lion', 'moon', 'nest', 'orange', 'pear', 'queen', 'rose', 'sun', 'tree',
    'umbrella', 'violet', 'water', 'xray', 'yellow', 'zebra'
  ];

  /// Generates a random, readable seed string of 10-15 characters.
  /// Format: word + random(0-99) + word, ensuring 10-15 chars total.
  /// Example: "whale42jump" - ensures memorability for sharing specific game deals.
  /// Uses unseeded Random for true randomness.
  /// Multiplayer implication: Generated seeds should be set before GameState creation and synced via Firebase
  /// to ensure all players initialize with the same deck order.
  static String generateSeed() {
    final random = Random();
    String word1 = _wordList[random.nextInt(_wordList.length)];
    int number = random.nextInt(100); // 0-99
    String word2 = _wordList[random.nextInt(_wordList.length)];
    String seed = '$word1${number.toString().padLeft(2, '0')}$word2';
    // Ensure 10-15 chars total
    while (seed.length < 10 || seed.length > 15) {
      if (seed.length < 10) {
        seed = generateSeed(); // Regenerate
      } else {
        seed = seed.substring(0, 15); // Truncate if too long (unlikely)
      }
    }
    return seed;
  }

  /// Derives a default seed from gameId hash for backward compatibility.
  /// Ensures determinism: same gameId always produces the same seed across clients/sessions.
  /// Used as default when no custom seed provided during game creation.
  /// Multiplayer implication: Derived seeds require no additional Firebase sync since all players
  /// compute the same value from the shared gameId, ensuring consistent deck shuffles without overhead.
  static String deriveFromGameId(String gameId) {
    int hash = gameId.hashCode;
    final random = Random(hash); // Seed Random with hash
    String word1 = _wordList[random.nextInt(_wordList.length)];
    int number = random.nextInt(100);
    String word2 = _wordList[random.nextInt(_wordList.length)];
    String seed = '$word1${number.toString().padLeft(2, '0')}$word2';
    // Adjust length to 10-15 chars deterministically
    if (seed.length > 15) {
      seed = seed.substring(0, 15);
    } else if (seed.length < 10) {
      // Pad with deterministic characters using hash
      int needed = 10 - seed.length;
      String pad = '';
      for (int i = 0; i < needed; i++) {
        pad += ((hash.abs() + i) % 10).toString();
      }
      seed += pad;
    }
    return seed;
  }
}