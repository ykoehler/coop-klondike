import 'package:flutter_test/flutter_test.dart';

import 'package:coop_klondike/utils/seed_generator.dart';

void main() {
  group('SeedGenerator', () {
    test('generateSeed returns string of 10-15 characters', () {
      final seed = SeedGenerator.generateSeed();
      expect(seed.length, greaterThanOrEqualTo(10));
      expect(seed.length, lessThanOrEqualTo(15));
    });

    test('generateSeed uses word list and numbers', () {
      final seed = SeedGenerator.generateSeed();
      // Check if it contains words from list and numbers
      expect(seed, matches(RegExp(r'^[a-z]+[0-9]{2}[a-z]+$')));
    });

    test('deriveFromGameId returns consistent seed for same gameId', () {
      const gameId = 'test-game-id';
      final seed1 = SeedGenerator.deriveFromGameId(gameId);
      final seed2 = SeedGenerator.deriveFromGameId(gameId);
      expect(seed1, equals(seed2));
      expect(seed1.length, greaterThanOrEqualTo(10));
      expect(seed1.length, lessThanOrEqualTo(15));
    });

    test('deriveFromGameId returns different seed for different gameId', () {
      const gameId1 = 'test-game-id-1';
      const gameId2 = 'test-game-id-2';
      final seed1 = SeedGenerator.deriveFromGameId(gameId1);
      final seed2 = SeedGenerator.deriveFromGameId(gameId2);
      expect(seed1, isNot(equals(seed2)));
    });
  });
}