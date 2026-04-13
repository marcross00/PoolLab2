# Build Errors - Troubleshooting Guide

## Error: "Property 'content' is not available due to missing import"

This error indicates files aren't properly added to your Xcode target.

## Fixes Applied:

1. ✅ **Added UIKit import to TaskListView.swift** - needed for `UIApplication.openSettingsURLString`
2. ✅ **Fixed NotificationDelegate retention in PoolLab2App.swift** - stored as property to prevent deallocation

## Steps to Fix Build Errors:

### 1. Add Files to Xcode Target

All new files need to be added to your Xcode project:

**Files to add:**
- MaintenanceTask+CoreDataClass.swift
- ReminderManager.swift  
- TaskListView.swift
- AddEditTaskView.swift
- AddEditTaskViewModel.swift
- NotificationDelegate.swift
- MaintenanceTaskExamples.swift (optional)

**How to add:**
1. In Xcode, right-click your project folder
2. Select "Add Files to [ProjectName]..."
3. Navigate to where the files are located
4. Select all the new .swift files
5. Check "Copy items if needed"
6. Make sure your app target is selected
7. Click "Add"

### 2. Verify Target Membership

For each file:
1. Select the file in Project Navigator
2. Open File Inspector (right sidebar, first tab)
3. Under "Target Membership", ensure your app target is checked ✓

### 3. Clean Build Folder

After adding files:
1. Product → Clean Build Folder (Cmd+Shift+K)
2. Build again (Cmd+B)

### 4. If You're Using Swift Package

If your project is structured as a Swift package, you may need to add the files to your `Package.swift` manifest.

## Common Import Issues Fixed:

```swift
// TaskListView.swift - Added UIKit
import SwiftUI
import CoreData
import UIKit  // ← Added for UIApplication

// PoolLab2App.swift - Fixed delegate retention
private let notificationDelegate: NotificationDelegate  // ← Stored as property
```

## Verify All Imports:

Each file should have correct imports:

- **ReminderManager.swift**: `Foundation`, `UserNotifications`, `CoreData`
- **NotificationDelegate.swift**: `Foundation`, `UserNotifications`, `CoreData`
- **TaskListView.swift**: `SwiftUI`, `CoreData`, `UIKit`
- **AddEditTaskView.swift**: `SwiftUI`, `CoreData`
- **AddEditTaskViewModel.swift**: `Foundation`, `CoreData`
- **MaintenanceTask+CoreDataClass.swift**: `Foundation`, `CoreData`

## Still Having Issues?

If errors persist after adding files to target:

1. **Check Info.plist** - Ensure you have notification permissions declared (Xcode usually adds this automatically when using UserNotifications)

2. **Check for duplicate symbols** - Make sure you don't have multiple copies of the same file

3. **Restart Xcode** - Sometimes Xcode's indexer needs a restart

4. **Delete Derived Data**:
   - Window → Organizer → Projects tab
   - Select your project → Delete Derived Data
   - Clean and rebuild

## Expected Build Result:

After properly adding all files, the app should build successfully with:
- ✅ No import errors
- ✅ All types resolved
- ✅ Notifications working
- ✅ TabView showing Logs and Tasks tabs

---

If you're still seeing errors after following these steps, please share:
1. The exact error message
2. Which file is showing the error
3. Screenshot of your Project Navigator showing the files
