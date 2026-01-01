# Fix: Multiple NSEntityDescriptions Claim NSManagedObject Subclass Error

## Problem
When switching Core Data entities from manual class definitions to **"Codegen: Class Definition"**, you may encounter this error:

```
CoreData: warning: Multiple NSEntityDescriptions claim the NSManagedObject subclass 'SavedVideo' so +entity is unable to disambiguate.
CoreData: error: +[SavedVideo entity] Failed to find a unique match for an NSEntityDescription to a managed object subclass
```

## Root Cause
This error occurs when:
1. **Multiple NSPersistentContainer instances**: If your app creates multiple `NSPersistentContainer` instances with the same model name, each container creates its own `NSManagedObjectModel` instance. With "Codegen: Class Definition", the auto-generated classes are shared globally, but multiple model instances try to claim them, causing the conflict.
2. **Stale build cache**: Xcode's build cache (DerivedData) contains old manually-generated class files that conflict with the new auto-generated classes from "Codegen: Class Definition".

**✅ FIXED**: The codebase has been updated so that `CoreDataManager` now uses `PersistenceController.shared.container` instead of creating its own container, ensuring only one model instance exists.

## Solution

### Method 1: Clean Build Folder in Xcode (Recommended)
1. **Open Xcode**
2. **Clean Build Folder**: Press `⇧⌘K` (Shift + Command + K)
   - Or go to: **Product → Clean Build Folder**
3. **Quit Xcode completely** (⌘Q)
4. **Reopen Xcode**
5. **Build the project**: Press `⌘B` (Command + B)

### Method 2: Delete DerivedData Manually
1. **Quit Xcode completely**
2. **Open Finder**
3. Press `⇧⌘G` (Shift + Command + G) to open "Go to Folder"
4. Navigate to: `~/Library/Developer/Xcode/DerivedData`
5. **Delete all folders** starting with `InstaSaver-`
6. **Reopen Xcode**
7. **Clean Build Folder** again: `⇧⌘K`
8. **Build the project**: `⌘B`

### Method 3: Use the Clean Script
Run the provided cleanup script:
```bash
./clean_build.sh
```

Then follow the steps in Xcode as mentioned in Method 1.

## Verification

After cleaning and rebuilding, verify that:
1. ✅ The build succeeds without errors
2. ✅ The app runs without the Core Data entity conflict error
3. ✅ Core Data operations (save, fetch) work correctly

## Prevention

When switching entity codegen settings:
1. Always clean the build folder before building
2. Consider cleaning DerivedData for a thorough cleanup
3. After changing codegen settings, rebuild from scratch

## Technical Details

- **Codegen Setting**: All entities in `InstaSaver.xcdatamodeld` are set to `codeGenerationType="class"`
- **Auto-generated classes**: Xcode automatically generates `SavedVideo`, `BookmarkedVideo`, `CollectionModel`, etc.
- **No manual classes**: Ensure no manual `.swift` files exist for these entities
- **Single model file**: Only one Core Data model file exists (no duplicates)

## Code Fix Applied

The codebase has been updated to fix the duplicate container issue:

**Before:**
```swift
class CoreDataManager {
    let persistentContainer: NSPersistentContainer
    
    private init() {
        persistentContainer = NSPersistentContainer(name: "InstaSaver")
        // ... loading stores
    }
}
```

**After:**
```swift
class CoreDataManager {
    var persistentContainer: NSPersistentContainer {
        return PersistenceController.shared.container
    }
    
    private init() {
        // Uses shared container instead of creating a new one
    }
}
```

This ensures only one `NSPersistentContainer` instance exists, preventing the duplicate entity description error.

## Additional Notes

If the error persists after the code fix and cleaning:
1. Check that no manual entity class files exist in your project
2. Verify all entities in the model have `codeGenerationType="class"`
3. Ensure the model file is properly saved and synced
4. Clean build folder and DerivedData again
5. Try restarting Xcode and your Mac if needed

