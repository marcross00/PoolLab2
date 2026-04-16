# Quick Start: Import/Export Feature

## 🚀 Getting Started in 5 Minutes

### Step 1: Add to Your Settings View

The easiest way to add import/export is in your Settings or More tab:

```swift
import SwiftUI

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var context
    
    var body: some View {
        NavigationStack {
            List {
                Section("Data Management") {
                    NavigationLink("Import & Export") {
                        ImportExportView(context: context)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
```

That's it! You now have a fully functional import/export feature.

### Step 2: Test It Out

1. **Export Data:**
   - Open Settings → Import & Export
   - Tap "Export Data"
   - Choose "Complete Backup (JSON)"
   - Share to Files or email yourself

2. **Import Data:**
   - Open Settings → Import & Export
   - Tap "Import Data"
   - Choose your exported file
   - Review the import results

## 📱 Alternative Integration Options

### Option A: Dashboard Widget

Add a card to your dashboard:

```swift
struct DashboardView: View {
    @Environment(\.managedObjectContext) private var context
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Your existing content...
                
                ImportExportCard(context: context)
                    .padding(.horizontal)
            }
        }
    }
}
```

### Option B: Toolbar Button

Add export to your logs list:

```swift
.toolbar {
    ToolbarItem(placement: .primaryAction) {
        Menu {
            Button {
                // Export action
            } label: {
                Label("Export Logs", systemImage: "square.and.arrow.up")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}
```

### Option C: Quick Actions Bar

Add inline buttons anywhere:

```swift
ImportExportQuickActions(context: context)
    .padding()
```

## 🎯 Common Use Cases

### Use Case 1: Weekly Backup

**User Goal:** Create a backup every week

**Solution:**
1. Navigate to Import & Export
2. Tap "Export Data"
3. Choose "Complete Backup (JSON)"
4. Save to iCloud Drive or email yourself
5. File is named with date automatically

### Use Case 2: Share with Pool Service

**User Goal:** Send pool logs to service company

**Solution:**
1. Navigate to Import & Export
2. Go to Advanced Export Options
3. Choose "Pool Logs (CSV)"
4. Share via email or Messages
5. They can open in Excel or Google Sheets

### Use Case 3: Switch to New Device

**User Goal:** Transfer all data to new iPhone/iPad

**Solution:**

On Old Device:
1. Export → Complete Backup (JSON)
2. Save to iCloud Drive

On New Device:
1. Install app
2. Import → Choose backup file
3. All data restored!

### Use Case 4: Merge Data from Multiple Seasons

**User Goal:** Combine data from different years

**Solution:**
1. Export data from Season 1
2. Export data from Season 2
3. Import Season 1 backup (Skip Duplicates)
4. Import Season 2 backup (Skip Duplicates)
5. All logs now combined!

## 📊 File Format Quick Reference

### JSON Format (Complete Backup)
- **Best for:** Full backups, device transfers
- **Contains:** All logs, chemicals, tasks
- **Size:** Small (usually < 1 MB)
- **Can open with:** Text editor, JSON viewer

### JSON Format (Pool Logs Only)
- **Best for:** Sharing readings only
- **Contains:** Just chemistry logs
- **Size:** Very small
- **Can open with:** Text editor, JSON viewer

### CSV Format
- **Best for:** Analysis in spreadsheets
- **Contains:** One data type per file
- **Size:** Small
- **Can open with:** Excel, Numbers, Google Sheets

## ⚙️ Import Settings Explained

### Skip Duplicates (Recommended)
- **What it does:** Ignores items that already exist
- **Best for:** Regular backups, sharing data
- **Safe:** Yes, won't modify existing data
- **Use when:** You want to preserve your current data

### Overwrite
- **What it does:** Replaces existing items with imported ones
- **Best for:** Restoring from backup
- **Safe:** Moderate, changes existing data
- **Use when:** You want imported data to be the "truth"

### Keep Both
- **What it does:** Creates duplicates with new IDs
- **Best for:** Merging from multiple sources
- **Safe:** Yes, keeps everything
- **Use when:** You want to keep all versions

## 🔧 Troubleshooting

### "Import Failed - Invalid Format"

**Cause:** File might be corrupted or wrong type

**Fix:**
1. Check file extension (.json or .csv)
2. Try re-exporting from source
3. Open file in text editor to verify it's not empty

### "Some Items Were Skipped"

**Cause:** Duplicate IDs with "Skip Duplicates" selected

**Fix:**
- This is normal and expected
- Check import summary for details
- Use "Keep Both" if you want all items

### "File Not Found"

**Cause:** File location permissions

**Fix:**
1. Make sure file is in accessible location
2. Try saving to Files app first
3. Grant file access when prompted

## 💡 Pro Tips

### Tip 1: Automated Backups
Export a backup before major app updates or when trying new features.

### Tip 2: Cloud Storage
Save backups to iCloud Drive or Dropbox for safekeeping.

### Tip 3: Version Control
Include dates in filenames: `pool_backup_2026-04-15.json`

### Tip 4: Test Imports
After importing, verify a few records to ensure accuracy.

### Tip 5: Regular Exports
Set a reminder to export weekly during pool season.

## 📱 Supported Platforms

- ✅ iOS 16+
- ✅ iPadOS 16+
- ✅ macOS (with Mac Catalyst)

## 🔐 Privacy & Security

### What's Included in Exports
- Pool chemistry readings
- Chemical usage records
- Maintenance task schedules
- Dates and notes

### What's NOT Included
- User account information
- App settings/preferences
- Purchase history
- Analytics data

### Security Notes
- Files are not encrypted
- Do not include sensitive personal information in notes
- Be careful when sharing exported files

## 📧 Need Help?

### Check the Full Documentation
See `IMPORT_EXPORT_GUIDE.md` for advanced features and API reference.

### Example Code
See `ImportExportIntegrationExamples.swift` for more integration patterns.

### Validation Tools
See `DataValidationUtilities.swift` for data quality tools.

## 🎉 You're Ready!

You now have a complete import/export system. Your users can:
- ✅ Backup their data
- ✅ Restore on new devices
- ✅ Share with others
- ✅ Export for analysis
- ✅ Migrate between seasons

Enjoy your new feature! 🏊‍♂️
