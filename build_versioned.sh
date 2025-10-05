#!/bin/bash

# Build script for Coop Klondike with versioned assets using base href approach
# This ensures browser cache busting by placing assets in versioned directories
# while keeping index.html at root with updated base href

set -e

# Generate timestamp-based version (vYYMMDDHHMMSS)
VERSION="v$(date +%y%m%d%H%M%S)"

echo "Building Coop Klondike with base href versioning: $VERSION"

# Generate version file
cat > lib/utils/app_version.dart << EOF
/// Auto-generated file containing version information for asset paths
/// This file is generated during build to ensure proper cache busting

class AppVersion {
  static const String version = '$VERSION';
}
EOF

echo "Generated version file with $VERSION"

# Clean previous build
flutter clean

# Build the web app with timestamp as build name
flutter pub get
flutter build web --release --build-name="$VERSION"

# Create versioned assets directory and move assets
VERSIONED_ASSETS_DIR="build/web/$VERSION"
echo "Creating versioned assets directory: $VERSIONED_ASSETS_DIR"

mkdir -p "$VERSIONED_ASSETS_DIR"

# Move all files except index.html and version.json to versioned directory
mv build/web/assets "$VERSIONED_ASSETS_DIR/"
mv build/web/canvaskit "$VERSIONED_ASSETS_DIR/"
mv build/web/favicon.png "$VERSIONED_ASSETS_DIR/"
mv build/web/flutter.js "$VERSIONED_ASSETS_DIR/"
mv build/web/flutter_bootstrap.js "$VERSIONED_ASSETS_DIR/"
mv build/web/flutter_service_worker.js "$VERSIONED_ASSETS_DIR/"
mv build/web/icons "$VERSIONED_ASSETS_DIR/"
mv build/web/main.dart.js "$VERSIONED_ASSETS_DIR/"
mv build/web/manifest.json "$VERSIONED_ASSETS_DIR/"
mv build/web/.last_build_id "$VERSIONED_ASSETS_DIR/"

# Update index.html base href to point to versioned directory
sed -i.bak "s|<base href=\"/\">|<base href=\"/$VERSION/\">|g" build/web/index.html

# Update firebase.json to serve from root (default)
cp firebase.json firebase.json.backup
# Reset to default if it was changed
sed -i.bak "s|\"public\":\"build/web/[^\"]*\"|\"public\":\"build/web\"|g" firebase.json

echo "Build complete!"
echo "index.html at root with base href: /$VERSION/"
echo "All assets in versioned directory: build/web/$VERSION/"
echo "Firebase hosting serves from: build/web (root)"
echo "Deploy with: firebase deploy --only hosting"