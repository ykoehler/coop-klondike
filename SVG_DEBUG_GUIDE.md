# SVG Debug Testing

## Created Debug Tools

I've created two test pages to diagnose the SVG loading issue:

### 1. HTML Test Page
**URL**: `http://localhost:8080/test_svg.html` (or wherever you're serving from)
**Location**: `/test_svg.html` and `/build/web/test_svg.html`

This page tests:
- ✅ Direct SVG file reference (img tag)
- ✅ Inline SVG loaded via fetch
- ✅ SVG via object tag
- ✅ SVG via DOMParser (simulates how Flutter might load it)
- ✅ Sample face-up cards (hearts_a.svg, spades_k.svg)

The page includes a console log showing exactly what succeeded or failed.

### 2. Flutter Debug Screen
**URL**: `http://localhost:8080/#/debug-svg`
**Route**: `/debug-svg`

This Flutter screen tests:
- Card face down SVG (`card_face_down.svg`)
- Multiple face-up cards (hearts_a.svg, spades_k.svg, diamonds_10.svg)
- Invalid path (to verify error handling works)
- Real-time console logging
- Manual reload buttons

## Changes Made

### 1. Fixed `card_face_down.svg`
**Problem**: The SVG was using a `<text>` element with Unicode character `♠` and a font reference, which can fail to load on web.

**Solution**: Replaced with pure geometric SVG shapes (lines and circles) - no font dependencies.

**Before**:
```xml
<text x="40" y="56" text-anchor="middle" font-family="Arial, sans-serif" font-size="20">♠</text>
```

**After**:
```xml
<line x1="10" y1="10" x2="70" y2="70" stroke="#ffffff" stroke-width="2"/>
<circle cx="40" cy="56" r="15" fill="none" stroke="#ffffff" stroke-width="3"/>
<!-- More geometric shapes -->
```

### 2. Enhanced Error Handling in `card_widget.dart`
Added `errorBuilder` to the face-down card widget with:
- Debug logging to console
- Visual error indicator (red box with error icon)
- Stack trace printing

## How to Test

### Test the HTML Page:
```bash
# If not already running, start a web server:
cd build/web
python3 -m http.server 8080

# Then open in browser:
# http://localhost:8080/test_svg.html
```

### Test the Flutter Debug Screen:
```bash
# Navigate to:
# http://localhost:8080/#/debug-svg
```

### Check Browser Console:
1. Open browser DevTools (F12)
2. Go to Console tab
3. Look for any errors related to SVG loading
4. Check Network tab to see if SVG files are being requested and what status codes they return

## What to Look For

If you're still seeing errors:

1. **Check the error message** - The enhanced error builder will now show specific error details
2. **Check the Network tab** - Are the SVG files returning 404 or other HTTP errors?
3. **Check the Console** - Any JavaScript errors or Flutter framework errors?
4. **Compare face-down vs face-up** - Do face-up cards load fine but face-down fails?

## Expected Behavior

- All SVGs should load without errors
- No "SVG Loading..." placeholder should remain visible
- No red error boxes should appear
- Console should show successful load messages (✓) not errors (❌)
