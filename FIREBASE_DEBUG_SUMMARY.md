# Firebase Deserialization Debug Summary

## Changes Made

Added comprehensive debug logging to help diagnose Firebase data deserialization errors.

### Modified Files

1. **lib/services/firebase_service.dart**
   - Added `_debugLogFirebaseData()` helper to recursively log data structures
   - Enhanced `listenToGame()` to log raw Firebase data when deserialization fails
   - Shows exact data types and structure that caused the error

2. **lib/models/card.dart**
   - Enhanced `Card.fromJson()` with detailed error messages
   - Validates all required fields before processing
   - Shows invalid values and expected values

3. **lib/models/deck.dart**
   - Enhanced `Deck.fromJson()` with field type logging
   - Logs card count before/after normalization
   - Better error context on failure

4. **lib/models/tableau_column.dart**
   - Enhanced `TableauColumn.fromJson()` with logging
   - Shows cards field type and count per column
   - Includes debugPrint import

5. **lib/models/foundation_pile.dart**
   - Enhanced `FoundationPile.fromJson()` with logging
   - Logs suit and card information
   - Better error reporting

6. **lib/providers/game_provider.dart**
   - Enhanced error handlers in game state stream
   - Added error type logging
   - Better formatted stack traces

## How to Debug

When an error occurs, look for these patterns in the debug console:

- `❌ FIREBASE` - Critical Firebase errors
- `❌ Card.fromJson ERROR` - Card parsing failed
- `📥 FIREBASE RAW DATA` - Exact data from Firebase causing the error
- `📦 DECK fromJson` - Deck deserialization logs
- `📋 TABLEAUCOLUMN` - Tableau column logs
- `🏛️ FOUNDATIONPILE` - Foundation pile logs

The `📥 FIREBASE RAW DATA` section will show the exact structure that couldn't be parsed.

## Running with Debug Logs

```bash
flutter run -v
```

Look for lines starting with emojis like ❌, 📥, 📤, 📦, 📋, 🏛️

## Common Issues to Check

1. **Enum toString() vs name**
   - Check if enums are saved as "Suit.hearts" instead of just "hearts"

2. **Null fields**
   - Look for required fields that are null

3. **Type mismatches**
   - Card fields should be strings matching enum names
   - Collections should be arrays/lists

4. **Firebase data validation**
   - Consider adding stricter Firebase security rules

## Example Error Log

```
📥 FIREBASE RAW DATA: Map<dynamic, dynamic> {
  suit: String: invalid_suit
}
❌ Card.fromJson ERROR: Invalid suit "invalid_suit"
   Available keys: [suit, rank, faceUp]
   Expected suits: Suit.hearts, Suit.diamonds, Suit.clubs, Suit.spades
```

This shows that Firebase sent an invalid suit value that couldn't be parsed.
