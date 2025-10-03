# SVG Flash Fix Documentation

## Problem
When starting a new game, cards would briefly show a red background with "SVG Loading..." text before the actual card images appeared. This created an unpleasant visual "flash" effect.

## Root Cause
The `SvgPicture.asset` widget in `CardWidget` was using a `placeholderBuilder` that displayed a red container with loading text while the SVG assets were being loaded from disk. This placeholder would appear for each card until its SVG was loaded.

## Solution
Implemented a three-part solution:

### 1. SVG Precaching (`lib/utils/svg_cache.dart`)
Created a utility class that precaches all 53 card SVG assets (52 cards + 1 face-down card) at app startup:

```dart
class SvgCache {
  static Future<void> precacheCardSvgs(BuildContext context) async {
    // Precaches all card SVGs into memory before the game loads
  }
}
```

### 2. App Initialization with Loading Screen (`lib/main.dart`)
Modified the `KlondikeApp` to:
- Show a loading screen while SVGs are being cached
- Only show the game once all SVGs are in memory
- Display "Loading Klondike Solitaire..." with a spinner during precaching

```dart
class _KlondikeAppState extends State<KlondikeApp> {
  bool _svgsCached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_svgsCached) {
      _precacheSvgs();
    }
  }
  
  // Shows loading screen until _svgsCached is true
}
```

### 3. Invisible Placeholder (`lib/widgets/card_widget.dart`)
Updated the `CardWidget` to use an invisible placeholder instead of the red container:

```dart
placeholderBuilder: (context) {
  // Return invisible placeholder - SVGs should be cached already
  return const SizedBox.shrink();
}
```

Since the SVGs are already cached, this placeholder should never actually be visible.

## Benefits
1. **No visual flash**: Cards appear instantly without loading placeholders
2. **Better UX**: Smooth, professional-looking game start
3. **One-time cost**: SVGs are cached once at app startup, not on each new game
4. **Clear feedback**: Users see a proper loading screen during initial load

## Testing
To verify the fix:
1. Run the app: `flutter run -d chrome`
2. Wait for "Loading Klondike Solitaire..." screen
3. Start a new game
4. Cards should appear instantly without red placeholders
5. Start another new game - cards still appear instantly (using cached SVGs)

## Files Modified
- `lib/main.dart` - Added loading screen and precaching logic
- `lib/utils/svg_cache.dart` - New file for SVG precaching utility
- `lib/widgets/card_widget.dart` - Changed placeholder from red container to invisible
