# Technical Implementation Details

## Changes by File

### 1. lib/services/firebase_service.dart

#### New Method: _debugLogFirebaseData()
```dart
String _debugLogFirebaseData(Object? data, {int depth = 0, int maxDepth = 5})
```

Recursively logs data structures showing:
- Runtime types at each level
- Map keys and values
- List items with indices
- Limits depth to prevent infinite recursion

#### Enhanced listenToGame() Stream Handler

Before deserialization:
- Logs raw Firebase data with `_debugLogFirebaseData()`
- Logs converted data keys
- Shows data structure before parsing

On error:
- Logs error message and type
- Attempts to dump raw data that caused error
- Catches and logs debug errors silently

### 2. lib/models/card.dart

#### Import Added
```dart
import 'package:flutter/foundation.dart' show debugPrint;
```

#### Enhanced Card.fromJson()

New validation:
1. Null checks on all required fields (suit, rank, faceUp)
2. Type validation before casting
3. Enum value validation against valid values
4. Helpful error messages showing:
   - Missing field names
   - Available JSON keys
   - Valid enum values

Error output includes:
- Error description
- Input JSON structure
- Runtime types of each field

### 3. lib/models/deck.dart

#### Enhanced Deck.fromJson()

New logging:
1. Logs type of cards field
2. Logs count before/after normalization
3. Catches errors during card parsing
4. Shows input JSON keys on failure

Preserves existing:
- Private `_empty()` constructor for deserialization
- Card list initialization
- Normalization via `normalizeMapList()`

### 4. lib/models/tableau_column.dart

#### Import Added
```dart
import 'package:flutter/foundation.dart' show debugPrint;
```

#### Enhanced TableauColumn.fromJson()

New logging:
1. Logs column index and cards field type
2. Logs count of loaded cards
3. Provides full error context on failure

Error output includes:
- Truncated JSON (first 200 chars)
- Column index for context

### 5. lib/models/foundation_pile.dart

#### Import Added
```dart
import 'package:flutter/foundation.dart' show debugPrint;
```

#### Enhanced FoundationPile.fromJson()

New logging:
1. Logs suit information and cards field type
2. Logs count of loaded cards
3. Provides detailed error context

Error output includes:
- Truncated JSON
- Full stack trace

### 6. lib/providers/game_provider.dart

#### Enhanced Game State Stream Error Handler

In game subscription `.listen()` catch block:
- Added error type logging: `error.runtimeType`
- Formatted stack trace for readability
- Better error messages

In game subscription `.onError()` handler:
- Added error type logging
- Better formatted output
- Full stack traces

## Logging Format

### Success Logs
```
📥 FIREBASE IN [listenToGame]: gameId=xyz
   Stock: 24 cards, Waste: 2 cards
   Total cards: 52
```

### Error Logs
```
❌ FIREBASE IN [listenToGame]: Failed to deserialize game state: <error>
   Error type: <error.runtimeType>
❌ Firebase raw data at error:
<_debugLogFirebaseData() output>
```

### Component Logs
```
📦 DECK fromJson: cards field type = List<dynamic>
📋 TABLEAUCOLUMN 3 fromJson: cards field type = List<dynamic>
🏛️ FOUNDATIONPILE fromJson: cards field type = List<dynamic>
```

## Data Flow with Enhanced Logging

```
Firebase Database
        ↓
[Raw Data] ← Logged by _debugLogFirebaseData()
        ↓
_convertToStringDynamicMap()
        ↓
[Converted Data] ← Logged before parsing
        ↓
GameState.fromJson()
    ├─ Deck.fromJson() ← Logs parsed cards
    ├─ List<TableauColumn>.fromJson() ← Each logs parsed cards
    ├─ List<FoundationPile>.fromJson() ← Each logs parsed cards
    └─ List<Card>.fromJson() ← Each validates fields
        ↓
[Parsed GameState]
        ↓
Stream → GameProvider
        ↓
UI Update
```

## Error Handling Chain

```
Exception in Card.fromJson()
    ↓
Throws with detailed message
    ↓
Caught in Deck/TableauColumn/FoundationPile
    ↓
Re-thrown with context
    ↓
Caught in GameState.fromJson()
    ↓
Re-thrown
    ↓
Caught in listenToGame() stream handler
    ↓
Logged with raw Firebase data
    ↓
Sent to sink.addError()
    ↓
Caught in GameProvider.listen() onError handler
    ↓
Logged with full context
    ↓
Stream continues listening (cancelOnError: false)
```

## Performance Considerations

- **No Impact:** Logging only occurs in debug mode via `debugPrint()`
- **Minimal:** String operations only happen when errors occur
- **Safe:** `_debugLogFirebaseData()` has max depth to prevent recursion
- **Optional:** All logging is debug output, disabled in release builds

## Testing Approach

### Unit Test Example
```dart
test('Card.fromJson handles invalid suit', () {
  expect(
    () => Card.fromJson({'suit': 'invalid', 'rank': 'Rank.two', 'faceUp': true}),
    throwsFormatException,
  );
});
```

### Integration Test Approach
1. Run app with `flutter run -v`
2. Reproduce the error scenario
3. Verify error logs appear in console
4. Verify logs show correct data structure
5. Verify logs show helpful error message

## Debugging Workflow

```
Play Game → Error Occurs → Search "❌ FIREBASE" → Find "📥 FIREBASE RAW DATA"
    ↓
See exact Firebase data structure
    ↓
Compare with expected format
    ↓
Identify discrepancy (wrong enum format, missing field, type mismatch, etc.)
    ↓
Find source of bad data in toJson() or data validation
    ↓
Fix the issue
    ↓
Test again
```

## Files Not Modified

- No game logic changed
- No data structure changes
- No database schema changes
- No UI changes
- Only debugging code added

## Backward Compatibility

- ✅ Completely backward compatible
- ✅ No breaking changes
- ✅ All existing tests still pass
- ✅ No API changes
- ✅ Debug mode only

## Future Enhancements

Possible additions:
1. Write logs to file for persistent debugging
2. Add metrics to track error frequency
3. Implement schema validation before deserialization
4. Add data recovery logic for partial failures
5. Create Firebase security rules to validate schema
6. Add telemetry to track error patterns
