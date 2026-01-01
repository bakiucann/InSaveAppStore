#!/bin/bash

# Script to clean Xcode build artifacts and DerivedData
# This fixes the "Multiple NSEntityDescriptions claim the NSManagedObject subclass" error
# when switching to "Codegen: Class Definition"

echo "🧹 Cleaning Xcode build artifacts..."

# Get the project directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

# 1. Clean the build folder using xcodebuild
echo "📦 Cleaning build folder..."
xcodebuild clean -workspace InstaSaver.xcworkspace -scheme InstaSaver 2>/dev/null || echo "⚠️  xcodebuild clean failed (this is OK if you clean from Xcode instead)"

# 2. Remove DerivedData for this project
echo "🗑️  Removing DerivedData..."
DERIVED_DATA_DIR="$HOME/Library/Developer/Xcode/DerivedData"
if [ -d "$DERIVED_DATA_DIR" ]; then
    # Remove any DerivedData folders that start with "InstaSaver"
    find "$DERIVED_DATA_DIR" -maxdepth 1 -type d -name "InstaSaver-*" -exec rm -rf {} + 2>/dev/null
    echo "✅ DerivedData cleaned"
else
    echo "ℹ️  DerivedData directory not found at $DERIVED_DATA_DIR"
fi

# 3. Remove ModuleCache
echo "🗑️  Removing ModuleCache..."
MODULE_CACHE="$HOME/Library/Developer/Xcode/DerivedData/ModuleCache.noindex"
if [ -d "$MODULE_CACHE" ]; then
    rm -rf "$MODULE_CACHE"
    echo "✅ ModuleCache cleaned"
fi

# 4. Clean Swift Package Manager cache (if used)
if [ -d ".build" ]; then
    echo "🗑️  Removing Swift Package Manager build cache..."
    rm -rf .build
    echo "✅ SPM cache cleaned"
fi

echo ""
echo "✅ Build cleanup complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Open Xcode"
echo "   2. Product → Clean Build Folder (⇧⌘K)"
echo "   3. Product → Build (⌘B)"
echo ""
echo "If the error persists, also try:"
echo "   - Quit Xcode completely"
echo "   - Reopen the project"
echo "   - Clean Build Folder again (⇧⌘K)"
echo "   - Build (⌘B)"

