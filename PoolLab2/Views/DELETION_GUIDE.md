# Pool Log Deletion Guide

This guide explains all the ways users can delete pool log entries in your app.

## Deletion Methods

### 1. Swipe to Delete (Quick Delete)

**Location:** Log List View

**How it works:**
- Swipe left on any log entry in the list
- Tap the red "Delete" button
- Log is deleted immediately

**Implementation:**
```swift
.swipeActions(edge: .trailing, allowsFullSwipe: true) {
    Button(role: .destructive) {
        deleteLog(log)
    } label: {
        Label("Delete", systemImage: "trash")
    }
}
```

### 2. List Edit Mode (Bulk Delete)

**Location:** Log List View

**How it works:**
- Tap the "Edit" button in the top-left corner
- Select one or more logs by tapping the circles
- Tap "Delete" button at the bottom
- Confirm deletion

**Implementation:**
```swift
ToolbarItem(placement: .topBarLeading) {
    if !logs.isEmpty {
        EditButton()
    }
}
```

### 3. Context Menu (Long Press)

**Location:** Log List View

**How it works:**
- Long press on any log entry
- Select "Delete" from the menu
- Confirm in the alert dialog

**Implementation:**
```swift
.contextMenu {
    Button {
        logToDelete = log
        showingDeleteConfirmation = true
    } label: {
        Label("Delete", systemImage: "trash")
    }
}
```

### 4. Detail View Delete Button

**Location:** Log Detail View

**How it works:**
- Navigate into a log's detail view
- Scroll to the bottom
- Tap the red "Delete Log" button
- Confirm in the alert dialog

**Implementation:**
```swift
Section {
    Button(role: .destructive) {
        showingDeleteAlert = true
    } label: {
        HStack {
            Spacer()
            Label("Delete Log", systemImage: "trash")
            Spacer()
        }
    }
}
```

### 5. Delete Old Logs (Bulk Cleanup)

**Location:** Log List View → Menu (⋯)

**How it works:**
- Tap the menu button (⋯) in the top-right corner
- Select "Delete Old Logs"
- Choose time period:
  - Older than 90 days
  - Older than 180 days
  - Older than 1 year
- Confirm deletion

**Implementation:**
```swift
private func deleteOldLogs(days: Int) {
    let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
    
    var deletedCount = 0
    for log in logs {
        if let logDate = log.date, logDate < cutoffDate {
            viewContext.delete(log)
            deletedCount += 1
        }
    }
    
    try? viewContext.save()
}
```

### 6. Delete All Logs

**Location:** Log List View → Menu (⋯)

**How it works:**
- Tap the menu button (⋯) in the top-right corner
- Select "Delete All Logs"
- Confirm in the alert dialog (shows total count)

**⚠️ Warning:** This action cannot be undone!

**Implementation:**
```swift
private func deleteAllLogs() {
    for log in logs {
        viewContext.delete(log)
    }
    try? viewContext.save()
}
```

## Safety Features

### Confirmation Alerts

All deletion methods (except swipe-to-delete) show confirmation alerts:

```swift
.alert("Delete Log?", isPresented: $showingDeleteConfirmation, presenting: logToDelete) { log in
    Button("Cancel", role: .cancel) { }
    Button("Delete", role: .destructive) {
        deleteLog(log)
    }
} message: { log in
    Text("This will permanently delete the log from \(log.wrappedDate, format: .dateTime.month().day().year()).")
}
```

### Cascade Deletion

When a log is deleted, all associated chemical entries are automatically deleted due to Core Data cascade rules.

**Core Data Relationship:**
```
PoolLog (1) ──< cascade delete >──< (many) ChemicalEntry
```

## User Experience Considerations

### Visual Feedback

- Destructive actions use `.destructive` role for red coloring
- Swipe actions support full swipe for quick deletion
- Edit mode shows selection indicators
- Alerts show specific information (date, count)

### Accessibility

```swift
// All delete buttons have proper labels for VoiceOver
Label("Delete", systemImage: "trash")
Label("Delete Log", systemImage: "trash")
Label("Delete All Logs", systemImage: "trash")
```

### Animation

List deletions are animated smoothly:
```swift
@FetchRequest(
    sortDescriptors: [NSSortDescriptor(keyPath: \PoolLog.date, ascending: false)],
    animation: .default  // Smooth deletion animation
)
```

## Testing Deletion

### Create Test Data

```swift
// In preview or test
for i in 0..<100 {
    let log = PoolLog(context: context)
    log.id = UUID()
    log.date = Calendar.current.date(byAdding: .day, value: -i, to: Date())
    log.ph = NSNumber(value: 7.2 + Double.random(in: -0.3...0.3))
    // ... set other properties
}
try? context.save()
```

### Test Scenarios

1. ✅ Delete single log via swipe
2. ✅ Delete multiple logs in edit mode
3. ✅ Delete from detail view
4. ✅ Delete old logs (90/180/365 days)
5. ✅ Delete all logs
6. ✅ Cancel deletion in alerts
7. ✅ Verify cascade deletion of chemicals

## Error Handling

All deletion methods include error handling:

```swift
do {
    try viewContext.save()
} catch {
    print("Error deleting logs: \(error.localizedDescription)")
    // Consider showing an error alert to the user
}
```

### Future Enhancement Ideas

Consider adding:
- Undo functionality (using NSUndoManager)
- Trash/Archive feature (soft delete)
- Export before delete option
- Batch operations with progress indicator
- Search and filter before deletion

## Files Modified

- **LogListView.swift** - Main list with all deletion methods
- **LogDetailView.swift** - Detail view with delete button

## Example Usage Flow

```
User Flow 1: Quick Delete
1. User sees list of logs
2. Swipes left on unwanted log
3. Taps "Delete"
4. Log disappears immediately

User Flow 2: Bulk Cleanup
1. User has 200+ old logs
2. Taps menu (⋯)
3. Selects "Delete Old Logs"
4. Chooses "Older than 1 year"
5. Confirms in alert
6. Old logs are removed, keeping recent data

User Flow 3: Careful Review Before Delete
1. User taps on log entry
2. Reviews all details in detail view
3. Scrolls to bottom
4. Taps "Delete Log"
5. Confirms in alert
6. Returns to list (log is gone)
```

## Best Practices

✅ **Do:**
- Always confirm destructive actions
- Show what will be deleted (date, count)
- Provide multiple deletion methods for different use cases
- Handle errors gracefully
- Use system colors/roles for destructive actions

❌ **Don't:**
- Delete without confirmation (except swipe-to-delete)
- Forget to save context after deletion
- Leave orphaned chemical entries
- Block UI during bulk deletions
- Hide deletion options from users

## Accessibility Labels

```swift
// Good labels for screen readers
Label("Delete", systemImage: "trash")
  .accessibilityLabel("Delete this log entry")

Label("Delete All Logs", systemImage: "trash")
  .accessibilityLabel("Delete all \(logs.count) logs")

Button("Delete Old Logs")
  .accessibilityHint("Opens options to delete logs older than a specific time period")
```

## Summary

Your app now provides comprehensive deletion functionality:

| Method | Location | Speed | Safety | Use Case |
|--------|----------|-------|--------|----------|
| Swipe | List | Fast | Medium | Quick single delete |
| Edit Mode | List | Medium | High | Bulk select & delete |
| Context Menu | List | Medium | High | Alternative to swipe |
| Detail View | Detail | Slow | High | After review |
| Delete Old | Menu | Fast | High | Cleanup old data |
| Delete All | Menu | Fast | Very High | Complete reset |

All methods are safe, user-friendly, and follow Apple's Human Interface Guidelines.
