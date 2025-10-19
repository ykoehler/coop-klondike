# Firebase Database Deserialization Debugging Guide

## Quick Start

When you encounter the Firebase deserialization error while playing:

1. **Run with verbose logging:**
   ```bash
   flutter run -v
   ```

2. **Play the game normally** - try to reproduce the error

3. **Search console output for:**
   - `❌ FIREBASE` - Critical errors
   - `❌ Card.fromJson ERROR` - Card parsing failed
   - `📥 FIREBASE RAW DATA` - **This is the key!** It shows what Firebase sent

## What Was Changed

### Debug Enhancements Summary

We added detailed logging to 6 files to capture exactly what Firebase sends when deserialization fails:

| File | Change | What it logs |
|------|--------|-------------|
| `lib/services/firebase_service.dart` | `_debugLogFirebaseData()` helper + enhanced `listenToGame()` | Raw Firebase data structure, types at each level |
| `lib/models/card.dart` | Enhanced error handling in `Card.fromJson()` | Missing/invalid fields, available keys, valid values |
| `lib/models/deck.dart` | Enhanced error handling in `Deck.fromJson()` | Cards field type, normalized count, parse errors |
| `lib/models/tableau_column.dart` | Enhanced error handling in `TableauColumn.fromJson()` | Column index, cards field type, card count |
| `lib/models/foundation_pile.dart` | Enhanced error handling in `FoundationPile.fromJson()` | Suit info, cards field type, card count |
| `lib/providers/game_provider.dart` | Better error handlers in game state stream | Error type, full stack traces |

## Understanding the Error Logs

### Example: When Firebase Data is Corrupted

**Console output would look like:**

```
📥 FIREBASE RAW DATA: Map<dynamic, dynamic> {
  tableau: List<dynamic> [
    [0]: Map<dynamic, dynamic> {
      columnIndex: int: 0
      cards: List<dynamic> [
        [0]: Map<dynamic, dynamic> {
          suit: String: Suit.hearts        ← Problem! Should be just "hearts"
          rank: String: Rank.jack          ← Problem! Should be just "jack"
          faceUp: bool: true
        }
      ]
    }
  ]
  stock: Map<dynamic, dynamic> {
    cards: List<dynamic> []
  }
}
❌ FIREBASE IN [listenToGame]: Failed to deserialize game state: Invalid suit "Suit.hearts"
❌ Card.fromJson ERROR: Invalid suit "Suit.hearts"
   Available keys: [suit, rank, faceUp]
   Expected suits: Suit.hearts, Suit.diamonds, Suit.clubs, Suit.spades
```

**What this tells us:**
- Enums are being saved with the full enum path (`Suit.hearts`) instead of just the name (`hearts`)
- This likely happened in `GameState.toJson()` or somewhere data was corrupted before saving

### Example: Missing Field

```
❌ Card.fromJson ERROR: Missing "rank" field
   Available keys: [suit, faceUp]
   Input JSON: {suit: 'Suit.hearts', faceUp: true}
```

**What this tells us:**
- The `rank` field is completely missing from Firebase
- This suggests incomplete data was saved

### Example: Type Mismatch

```
❌ Card.fromJson ERROR: Invalid rank "2"
   Expected: Rank.ace, Rank.two, Rank.three, ...
   Input type: String
```

**What this tells us:**
- The rank was saved as a number "2" instead of the enum string "Rank.two"
- Type conversion issue somewhere in `toJson()`

## How to Reproduce and Debug

### Step 1: Start a Fresh Game

```bash
cd /Users/ykoehler/Projects/CoopKlondike
flutter run -v 2>&1 | tee debug.log
```

This captures all output to both console and `debug.log` file.

### Step 2: Play Until Error Occurs

- Try different actions (draw cards, drag cards, etc.)
- Check if error occurs consistently or randomly

### Step 3: Analyze the Log

When error occurs, search `debug.log` for:

```bash
# Find all Firebase errors
grep "❌ FIREBASE" debug.log

# Find card parsing errors
grep "❌ Card.fromJson" debug.log

# Find raw data dumps (most important!)
grep -A 50 "📥 FIREBASE RAW DATA" debug.log

# Find the stack trace around the error
grep -B 5 -A 10 "FIREBASE IN \[listenToGame\]: Failed" debug.log
```

## Common Root Causes

### 1. Enum Serialization Issue

**Problem:** Enums saved with full path instead of name

**Check:**
```dart
// ❌ WRONG in toJson()
'suit': suit.toString()  // Produces "Suit.hearts"

// ✅ CORRECT
'suit': suit.name  // Produces "hearts"
// OR
'suit': suit.toString().split('.').last  // Produces "hearts"
```

**Look at:** `lib/models/game_state.dart` `toJson()` method for Card fields

### 2. Firebase Data Validation

**Problem:** Invalid data stored in Firebase

**Solutions:**
1. Check Firebase security rules enforce schema
2. Add client-side validation before saving
3. Implement retry with validation

### 3. Race Conditions

**Problem:** Data partially updated during concurrent writes

**Indicators:**
- Fields missing randomly
- Different errors on subsequent plays
- Stock/waste/tableau counts don't add up to 52

**Check:**
- Firebase transaction handling
- Concurrent update handling in game_provider.dart

### 4. Browser Local Storage Issues (Web)

**Problem:** Stale cached data interfering with Firebase

**Solution:**
- Clear browser cache and localStorage
- Check DevTools → Application → Storage

## Advanced Debugging

### 1. Check a Specific Game's Firebase Data

If you capture a game ID, you can inspect it directly:

```bash
# Use Firebase CLI (if installed)
firebase database:get /games/YOUR_GAME_ID --pretty
```

### 2. Add Temporary Validation Code

In `firebase_service.dart`, before deserialization:

```dart
// Add this to validate incoming data
debugPrint('Raw data keys: ${rawData.keys}');
if (rawData is Map) {
  rawData.forEach((key, value) {
    debugPrint('  $key: ${value.runtimeType} = $value');
  });
}
```

### 3. Unit Test with Sample Firebase Data

Create a test file to replay problematic Firebase data:

```dart
test('deserialize corrupted Firebase data', () {
  final corruptedData = {
    'suit': 'Suit.hearts',  // Wrong format
    'rank': '2',            // Wrong type
    'faceUp': true,
  };
  
  expect(
    () => Card.fromJson(corruptedData),
    throwsFormatException,
  );
});
```

## Prevention Going Forward

### 1. Add Data Validation in Firebase Rules

```javascript
{
  "rules": {
    "games": {
      "$gameId": {
        "tableau": {
          "$column": {
            "cards": {
              "$index": {
                "suit": {
                  ".validate": "root.child('validSuits').child($value).exists()"
                },
                "rank": {
                  ".validate": "root.child('validRanks').child($value).exists()"
                }
              }
            }
          }
        }
      }
    },
    "validSuits": {
      "Suit.hearts": true,
      "Suit.diamonds": true,
      "Suit.clubs": true,
      "Suit.spades": true
    },
    "validRanks": {
      "Rank.ace": true,
      "Rank.two": true,
      // ... etc
    }
  }
}
```

### 2. Add Client-Side Validation Before Save

```dart
bool _validateGameState(GameState state) {
  for (var column in state.tableau) {
    for (var card in column.cards) {
      if (card.suit.toString() != 'Suit.${card.suit.name}') {
        debugPrint('Invalid suit in validation');
        return false;
      }
    }
  }
  return true;
}
```

### 3. Implement Schema Versioning

```dart
class GameState {
  static const int SCHEMA_VERSION = 1;
  
  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': SCHEMA_VERSION,
      // ... other fields
    };
  }
  
  static GameState fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'] ?? 0;
    if (version != SCHEMA_VERSION) {
      throw Exception('Incompatible schema version: $version');
    }
    // ... rest of deserialization
  }
}
```

## Next Steps

1. **Run** `flutter run -v` and reproduce the error
2. **Capture** the output showing `❌ FIREBASE RAW DATA`
3. **Post** the raw data structure in the issue
4. **Analyze** what's different from the expected format
5. **Fix** the root cause based on findings

## Support

If you get stuck:
1. Check the `FIREBASE_DEBUG_SUMMARY.md` for quick reference
2. Look at the test files in `test/` for deserialization examples
3. Check `lib/models/` for how `toJson()` methods work
