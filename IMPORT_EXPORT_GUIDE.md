# Import/Export Feature Documentation

## Overview

The Import/Export feature allows users to backup, restore, and share their pool tracking data. This feature supports multiple formats and provides flexible options for managing data.

## Features

### Export Capabilities

1. **Complete Backup (JSON)**
   - Exports all app data including pool logs, chemical entries, and maintenance tasks
   - Preserves all relationships and metadata
   - Best for complete backups

2. **Pool Logs Only (JSON)**
   - Exports only chemistry readings
   - Smaller file size
   - Good for sharing data with others

3. **CSV Export Options**
   - Pool Logs CSV: Chemistry readings in spreadsheet format
   - Chemical Entries CSV: Chemical usage tracking
   - Maintenance Tasks CSV: Task schedule and history
   - Compatible with Excel, Numbers, Google Sheets, etc.

### Import Capabilities

1. **JSON Import**
   - Supports both complete backups and pool logs only
   - Three merge strategies available:
     - **Skip Duplicates**: Ignores items with existing IDs
     - **Overwrite**: Updates existing items with imported data
     - **Keep Both**: Imports duplicates with new IDs

2. **CSV Import**
   - Imports pool logs from CSV files
   - Automatically parses dates and numeric values
   - Handles quoted fields and special characters

## Usage

### Adding to Your App

#### Option 1: Full View (Recommended for Settings)

```swift
import SwiftUI

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var showingImportExport = false
    
    var body: some View {
        List {
            // Other settings...
            
            Section {
                Button {
                    showingImportExport = true
                } label: {
                    Label("Import & Export", systemImage: "arrow.up.arrow.down.circle")
                }
            }
        }
        .sheet(isPresented: $showingImportExport) {
            ImportExportView(context: context)
        }
    }
}
```

#### Option 2: Quick Actions (For Dashboard)

```swift
import SwiftUI

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var context
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Your dashboard content...
                
                ImportExportCard(context: context)
                    .padding()
            }
        }
    }
}
```

#### Option 3: Inline Quick Actions

```swift
import SwiftUI

struct MyView: View {
    @Environment(\.managedObjectContext) private var context
    
    var body: some View {
        VStack {
            // Your content...
            
            ImportExportQuickActions(context: context)
                .padding()
        }
    }
}
```

### Programmatic Usage

#### Export Data Programmatically

```swift
import CoreData

func exportDataExample(context: NSManagedObjectContext) async {
    let exportManager = DataExportManager(context: context)
    
    do {
        // Export complete backup
        let jsonData = try await exportManager.exportToJSON()
        
        // Save to file
        let fileURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("backup.json")
        
        try jsonData.write(to: fileURL)
        
        print("Backup saved to: \(fileURL)")
        
    } catch {
        print("Export failed: \(error)")
    }
}
```

#### Import Data Programmatically

```swift
import CoreData

func importDataExample(context: NSManagedObjectContext, fileURL: URL) async {
    let importManager = DataImportManager(context: context)
    
    do {
        let data = try Data(contentsOf: fileURL)
        
        let result = try await importManager.importFromJSON(
            data: data,
            mergeStrategy: .skipDuplicates
        )
        
        print(result.summary)
        
    } catch {
        print("Import failed: \(error)")
    }
}
```

## File Formats

### JSON Structure

#### Complete Backup

```json
{
  "exportDate": "2026-04-15T10:30:00Z",
  "version": "1.0",
  "poolLogs": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "date": "2026-04-15T09:00:00Z",
      "ph": 7.4,
      "fc": 3.0,
      "ta": 90.0,
      "ch": 250.0,
      "cya": 35.0,
      "saltPpm": 3200.0,
      "notes": "Water balanced"
    }
  ],
  "chemicalEntries": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "date": "2026-04-15T09:15:00Z",
      "type": "Chlorine",
      "amount": 2.0,
      "unit": "oz"
    }
  ],
  "maintenanceTasks": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440002",
      "name": "Clean Filter",
      "intervalDays": 30,
      "lastCompletedDate": "2026-04-01T00:00:00Z",
      "isEnabled": true,
      "notes": "Backwash until clear"
    }
  ]
}
```

### CSV Structure

#### Pool Logs CSV

```csv
Date,pH,Free Chlorine (ppm),Total Alkalinity (ppm),Calcium Hardness (ppm),CYA (ppm),Salt (ppm),Notes
Apr 15, 2026 at 9:00 AM,7.4,3.0,90.0,250.0,35.0,3200.0,"Water balanced"
Apr 14, 2026 at 9:00 AM,7.3,2.8,92.0,250.0,35.0,3200.0,""
```

#### Chemical Entries CSV

```csv
Date,Chemical Type,Amount,Unit
Apr 15, 2026 at 9:15 AM,Chlorine,2.0,oz
Apr 14, 2026 at 10:00 AM,pH Increaser,4.0,oz
```

#### Maintenance Tasks CSV

```csv
Task Name,Interval (days),Last Completed,Next Due,Status,Notes
Clean Filter,30,Apr 1, 2026,May 1, 2026,Upcoming,"Backwash until clear"
Test Water,7,Apr 14, 2026,Apr 21, 2026,Upcoming,""
```

## Data Management

### Merge Strategies

1. **Skip Duplicates** (Default)
   - Safest option
   - Preserves existing data
   - Only imports new items
   - Best for: Regular backups, sharing data

2. **Overwrite**
   - Updates existing items
   - Uses imported data as source of truth
   - Best for: Restoring from backup, syncing data

3. **Keep Both**
   - Creates duplicates with new IDs
   - Preserves both versions
   - Best for: Merging data from multiple sources

### Best Practices

#### Regular Backups

1. Export complete backup weekly
2. Store backups in multiple locations:
   - iCloud Drive
   - Email to yourself
   - Share to Mac/PC
3. Use descriptive filenames with dates

#### Sharing Data

1. Export only necessary data (Pool Logs JSON)
2. CSV format for spreadsheet analysis
3. Remove sensitive notes before sharing

#### Data Recovery

1. Import with "Skip Duplicates" first
2. Review import results
3. Use "Overwrite" only if necessary
4. Keep original backup file safe

## Troubleshooting

### Common Issues

#### Import Fails with "Invalid Format"

- Ensure file is not corrupted
- Verify JSON syntax is valid
- Check that dates are in ISO8601 format

#### Some Items Not Imported

- Check merge strategy setting
- Review import results summary
- Verify IDs don't conflict

#### CSV Import Skips Rows

- Check date format matches export format
- Ensure numeric values are valid
- Verify CSV has proper headers

### Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| "Invalid Format" | File corrupted or wrong type | Re-export or check file |
| "No Data" | Empty file | Ensure file contains data |
| "Encoding Failed" | System error | Try again or restart app |

## Advanced Features

### Custom Export Filters

You can extend the export managers to filter data:

```swift
extension DataExportManager {
    func exportRecentLogs(days: Int) throws -> Data {
        let cutoffDate = Calendar.current.date(
            byAdding: .day,
            value: -days,
            to: Date()
        )!
        
        let request: NSFetchRequest<PoolLog> = PoolLog.fetchRequest()
        request.predicate = NSPredicate(
            format: "date >= %@",
            cutoffDate as NSDate
        )
        
        let logs = try context.fetch(request)
        
        let exportableLogs = logs.map { log in
            PoolLogExportable(
                id: log.id ?? UUID(),
                date: log.date ?? Date(),
                ph: log.ph,
                fc: log.fc,
                ta: log.ta,
                ch: log.ch,
                cya: log.cya,
                saltPpm: log.saltPpm,
                notes: log.notes
            )
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted]
        
        return try encoder.encode(exportableLogs)
    }
}
```

### Automated Backups

You can set up automated backups using background tasks:

```swift
import BackgroundTasks

class BackupScheduler {
    static func scheduleWeeklyBackup(context: NSManagedObjectContext) {
        let request = BGProcessingTaskRequest(
            identifier: "com.yourapp.weeklybackup"
        )
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule backup: \(error)")
        }
    }
    
    static func handleBackupTask(
        task: BGProcessingTask,
        context: NSManagedObjectContext
    ) {
        Task {
            let exportManager = DataExportManager(context: context)
            
            do {
                let data = try await exportManager.exportToJSON()
                
                // Save to iCloud or local storage
                let fileURL = FileManager.default
                    .url(forUbiquityContainerIdentifier: nil)?
                    .appendingPathComponent("Backups")
                    .appendingPathComponent("backup_\(Date()).json")
                
                if let fileURL = fileURL {
                    try data.write(to: fileURL)
                }
                
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }
    }
}
```

## API Reference

### DataExportManager

```swift
@MainActor
class DataExportManager: ObservableObject {
    func exportToJSON() throws -> Data
    func exportPoolLogsToJSON() throws -> Data
    func exportPoolLogsToCSV() throws -> Data
    func exportChemicalEntriesToCSV() throws -> Data
    func exportMaintenanceTasksToCSV() throws -> Data
}
```

### DataImportManager

```swift
@MainActor
class DataImportManager: ObservableObject {
    func importFromJSON(data: Data, mergeStrategy: MergeStrategy) throws -> ImportResult
    func importPoolLogsFromJSON(data: Data, mergeStrategy: MergeStrategy) throws -> ImportResult
    func importPoolLogsFromCSV(data: Data) throws -> ImportResult
    
    @Published var importProgress: Double
    @Published var importStatus: String
}
```

### ImportResult

```swift
struct ImportResult {
    var poolLogsImported: Int
    var poolLogsSkipped: Int
    var chemicalEntriesImported: Int
    var chemicalEntriesSkipped: Int
    var maintenanceTasksImported: Int
    var maintenanceTasksSkipped: Int
    
    var totalImported: Int { get }
    var totalSkipped: Int { get }
    var summary: String { get }
}
```

## Version History

### Version 1.0
- Initial release
- JSON and CSV export
- JSON and CSV import
- Three merge strategies
- Progress tracking
- Error handling

## Future Enhancements

Potential future additions:
- iCloud sync
- Automatic scheduled backups
- Email export
- PDF reports
- Data encryption
- Selective import (choose which items to import)
- Import preview
- Conflict resolution UI
