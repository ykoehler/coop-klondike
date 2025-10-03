import 'package:flutter_test/flutter_test.dart';
import 'package:coop_klondike/models/card.dart';
import 'package:coop_klondike/models/game_state.dart';

void main() {
  group('GameState', () {
    test('initial dealing distributes cards correctly', () {
      final state = GameState();

      // Check tableau columns
      expect(state.tableau.length, 7);
      for (int i = 0; i < 7; i++) {
        expect(state.tableau[i].cards.length, i + 1);
        expect(state.tableau[i].topCard!.faceUp, true); // Top card face up
        // Check that cards below top are face down
        for (int j = 0; j < i; j++) {
          expect(state.tableau[i].cards[j].faceUp, false);
        }
      }

      // Check foundations are empty
      expect(state.foundations.length, 4);
      for (final pile in state.foundations) {
        expect(pile.isEmpty, true);
      }

      // Check stock has remaining cards: 52 - (1+2+3+4+5+6+7) - 3 (auto-drawn in DrawMode.three) = 52 - 28 - 3 = 21
      expect(state.stock.length, 21);
      // Three cards automatically drawn to waste in DrawMode.three
      expect(state.waste.length, 3);
    });

    test('newGame resets the game', () {
      final state = GameState();
      // Modify state by adding more waste cards
      state.waste.add(state.stock.drawCard()!);

      state.newGame();

      // Should be back to initial state with three cards in waste (DrawMode.three)
      expect(state.tableau.length, 7);
      expect(state.stock.length, 21);
      expect(state.waste.length, 3);
    });

    test('isWon returns false initially', () {
      final state = GameState();
      expect(state.isWon, false);
    });

    test('isWon returns true when all foundations complete', () {
      final state = GameState();

      // Fill each foundation with 13 cards
      final suits = Suit.values;
      for (int foundationIndex = 0; foundationIndex < state.foundations.length; foundationIndex++) {
        final pile = state.foundations[foundationIndex];
        final suit = suits[foundationIndex % suits.length];
        for (int rankIndex = 0; rankIndex < 13; rankIndex++) {
          final rank = Rank.values[rankIndex];
          final card = Card(suit: suit, rank: rank);
          pile.addCard(card);
        }
        expect(pile.isComplete, true);
        expect(pile.suit, suit);
      }

      expect(state.isWon, true);
    });

    test('deserialization pads missing foundations from list input', () {
      final ace = Card(suit: Suit.hearts, rank: Rank.ace, faceUp: true);
      final json = {
        'tableau': List.generate(7, (_) => {'cards': []}),
        'foundations': [
          {
            'suit': ace.suit.toString(),
            'cards': [ace.toJson()],
          },
        ],
        'stock': {'cards': []},
        'waste': [],
        'drawMode': 'DrawMode.three',
        'gameId': 'TEST-LIST',
        'seed': 'seed-list',
      };

      final state = GameState.fromJson(json);

      expect(state.foundations.length, 4);
      expect(state.foundations[0].topCard, isNotNull);
      expect(state.foundations[0].topCard!.rank, Rank.ace);
      expect(state.foundations[0].topCard!.suit, Suit.hearts);
      for (int i = 1; i < 4; i++) {
        expect(state.foundations[i].cards, isEmpty);
      }
    });

    test('deserialization pads missing foundations from sparse map input', () {
      final ace = Card(suit: Suit.spades, rank: Rank.ace, faceUp: true);
      final json = {
        'tableau': List.generate(7, (_) => {'cards': []}),
        'foundations': {
          '2': {
            'suit': ace.suit.toString(),
            'cards': [ace.toJson()],
          },
        },
        'stock': {'cards': []},
        'waste': [],
        'drawMode': 'DrawMode.three',
        'gameId': 'TEST-MAP',
        'seed': 'seed-map',
      };

      final state = GameState.fromJson(json);

      expect(state.foundations.length, 4);
      expect(state.foundations[2].topCard, isNotNull);
      expect(state.foundations[2].topCard!.rank, Rank.ace);
      expect(state.foundations[2].topCard!.suit, Suit.spades);
      expect(state.foundations[0].cards, isEmpty);
      expect(state.foundations[1].cards, isEmpty);
      expect(state.foundations[3].cards, isEmpty);
    });
  });

  group('DrawMode', () {
    test('DrawMode enum has correct values', () {
      expect(DrawMode.one.index, 0);
      expect(DrawMode.three.index, 1);
      expect(DrawMode.values.length, 2);
    });
  });

  group('gameId', () {
    test('gameId is generated when not provided', () {
      final state = GameState();
      expect(state.gameId, isNotNull);
      expect(state.gameId, isNotEmpty);
    });

    test('gameId uses provided value', () {
      const customId = 'TEST1-TEST2';
      final state = GameState(gameId: customId);
      expect(state.gameId, customId);
    });

    test('generated gameId has correct format', () {
      final state = GameState();
      final id = state.gameId;
      expect(id.length, 11); // 5-5 with dash
      expect(id.substring(5, 6), '-');
      final part1 = id.substring(0, 5);
      final part2 = id.substring(6, 11);
      expect(_isValidGameIdPart(part1), true);
      expect(_isValidGameIdPart(part2), true);
    });

    test('seeded game produces consistent layout', () {
      const seed = 'SEED1-SEED2';
      final state1 = GameState(gameId: seed);
      final state2 = GameState(gameId: seed);

      // Compare tableau layouts
      for (int i = 0; i < state1.tableau.length; i++) {
        expect(state1.tableau[i].cards.length, state2.tableau[i].cards.length);
        for (int j = 0; j < state1.tableau[i].cards.length; j++) {
          expect(state1.tableau[i].cards[j].suit, state2.tableau[i].cards[j].suit);
          expect(state1.tableau[i].cards[j].rank, state2.tableau[i].cards[j].rank);
        }
      }
    });

    test('different seeds produce different layouts', () {
      final state1 = GameState(gameId: 'SEED1-SEED2');
      final state2 = GameState(gameId: 'DIFF1-DIFF2');

      // At least one card should be different (highly likely)
      bool different = false;
      for (int i = 0; i < state1.tableau.length && !different; i++) {
        for (int j = 0; j < state1.tableau[i].cards.length && !different; j++) {
          if (state1.tableau[i].cards[j].suit != state2.tableau[i].cards[j].suit ||
              state1.tableau[i].cards[j].rank != state2.tableau[i].cards[j].rank) {
            different = true;
          }
        }
      }
      expect(different, true);
    });
  });

  group('DrawMode in GameState', () {
    test('default drawMode is three', () {
      final state = GameState();
      expect(state.drawMode, DrawMode.three);
    });

    test('drawMode can be set to one', () {
      final state = GameState(drawMode: DrawMode.one);
      expect(state.drawMode, DrawMode.one);
    });
  });

  group('GameState Seed Serialization', () {
    test('serialization preserves seed', () {
      final state = GameState(seedStr: 'test');
      expect(state.seed, 'test');

      final json = state.toJson();
      expect(json['seed'], 'test');

      final newState = GameState.fromJson(json);
      expect(newState.seed, 'test');
    });

    test('default seed is generated', () {
      final state = GameState();
      expect(state.seed.isNotEmpty, true);
    });

    test('empty seed uses default', () {
      final state = GameState(seedStr: '');
      expect(state.seed.isNotEmpty, true);
    });

    test('deserialization handles missing seed field', () {
      final json = {
        'tableau': [],
        'foundations': [],
        'stock': [],
        'waste': [],
        'drawMode': 'three'
      }; // no seed field

      final state = GameState.fromJson(json);
      expect(state.seed, isNotNull);
      expect(state.seed.isNotEmpty, true);
    });
  });
}

bool _isValidGameIdPart(String part) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  for (final char in part.split('')) {
    if (!chars.contains(char)) return false;
  }
  return true;
}