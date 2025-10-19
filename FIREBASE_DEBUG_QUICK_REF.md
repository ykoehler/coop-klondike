# Quick Reference: Firebase Debug Logs

## Run Command
```bash
flutter run -v 2>&1 | tee debug.log
```

## Log Symbols
- `📥` = Firebase data received
- `📤` = Firebase data sent
- `❌` = Error occurred
- `✅` = Success
- `📦` = Deck data
- `📋` = Tableau column
- `🏛️` = Foundation pile
- `⚠️` = Warning

## Most Important Logs

### When Everything Works
```
📤 FIREBASE OUT [updateGame]: gameId=abc123
📥 FIREBASE IN [listenToGame]: gameId=abc123
   Stock: 24 cards, Waste: 2 cards
```

### When Error Occurs
```
❌ FIREBASE IN [listenToGame]: Failed to deserialize game state: Invalid suit "XYZ"
❌ Firebase raw data at error:
[Shows exact data Firebase sent that caused the problem]
```

## Search Commands

```bash
# Find all Firebase errors
grep "❌ FIREBASE" debug.log

# Find card parsing errors  
grep "Card.fromJson ERROR" debug.log

# Find raw data dumps (most useful!)
grep -A 30 "FIREBASE RAW DATA" debug.log

# Find where error occurred
grep -B 5 "Failed to deserialize" debug.log
```

## What Each File Logs

| Component | Prefix | Example |
|-----------|--------|---------|
| Card | `❌ Card.fromJson` | Invalid suit "diamonds" |
| Deck | `📦 DECK` | Loaded 24 cards from JSON |
| Tableau | `📋 TABLEAUCOLUMN` | Column 3 fromJson: cards field type |
| Foundation | `🏛️ FOUNDATIONPILE` | Loaded 5 cards |
| Firebase | `📥/📤 FIREBASE` | Update received/sent |
| Game | `❌ GameProvider` | Error processing game state |

## Debugging Checklist

- [ ] Run with `flutter run -v`
- [ ] Reproduce the error
- [ ] Capture the `📥 FIREBASE RAW DATA` section
- [ ] Compare data format with expected
- [ ] Check if enums have wrong format (e.g., "Suit.hearts" vs "hearts")
- [ ] Check if fields are missing or null
- [ ] Check if types are wrong (string vs number)
- [ ] Look at corresponding `toJson()` method
- [ ] Fix the data serialization
- [ ] Test again

## Data Format Expected

### Card
```json
{
  "suit": "Suit.hearts",
  "rank": "Rank.jack",
  "faceUp": true
}
```

### Deck
```json
{
  "cards": [...]
}
```

### TableauColumn
```json
{
  "columnIndex": 0,
  "cards": [...]
}
```

### FoundationPile
```json
{
  "suit": "Suit.hearts",
  "cards": [...]
}
```

## Common Issues

| Issue | Log Shows | Fix |
|-------|-----------|-----|
| Wrong enum format | `"Suit.hearts"` instead of `"hearts"` | Use `suit.name` not `toString()` |
| Missing field | `Missing "rank" field` | Check toJson() saves all fields |
| Type mismatch | `Int: 2` instead of `String: "Rank.two"` | Fix type casting in toJson() |
| Null value | `rank: null` | Add null checks or defaults |
| Corrupted list | `List contains Map instead of Card` | Check normalizeMapList() |

## Next Action

Once you have the debug logs:

1. **Paste the `📥 FIREBASE RAW DATA` section** in an issue
2. **Compare with expected format above**
3. **Identify the mismatch**
4. **Fix the `toJson()` method** causing the issue
5. **Test to confirm** error is gone

The enhanced logging should make the problem obvious!
