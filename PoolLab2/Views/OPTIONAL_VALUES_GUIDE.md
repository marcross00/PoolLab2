# Guide: Handling Unmeasured Chemistry Values

## Overview

As of the latest update, all pool chemistry values in `PoolLog` are now optional (`NSNumber?`). This allows the app to distinguish between:
- **Unmeasured values**: `nil` (not recorded)
- **Measured as zero**: `0.0` (actually recorded as zero)

When displaying these values in the UI, unmeasured values should appear as `"--"` instead of `0.0`.

## Core Data Properties

### PoolLog Properties

All chemistry properties are now optional `NSNumber?`:

```swift
@NSManaged public var ph: NSNumber?
@NSManaged public var fc: NSNumber?
@NSManaged public var ta: NSNumber?
@NSManaged public var ch: NSNumber?
@NSManaged public var cya: NSNumber?
@NSManaged public var saltPpm: NSNumber?
```

### Convenience Properties

Use these computed properties to get optional `Double` values:

```swift
log.phValue       // Double?
log.fcValue       // Double?
log.taValue       // Double?
log.chValue       // Double?
log.cyaValue      // Double?
log.saltPpmValue  // Double?
```

## Displaying Values in UI

### ❌ Wrong Way (Shows 0.0 for unmeasured)

```swift
// DON'T do this - shows 0.0 for nil values
Text("pH: \(log.ph?.doubleValue ?? 0.0, specifier: "%.1f")")
Text("pH: \(log.phValue ?? 0.0, specifier: "%.1f")")
```

### ✅ Correct Ways

#### Option 1: Using the Helper Extension (Recommended)

```swift
// Simple formatting
Text("pH: \(log.phValue.formatted())")  // "pH: 7.4" or "pH: --"

// Custom format
Text("pH: \(log.phValue.formatted(with: "%.2f"))")  // 2 decimal places

// With unit
Text("FC: \(log.fcValue.formatted(with: "%.1f", unit: "ppm"))")  // "FC: 3.0 ppm" or "FC: --"
```

#### Option 2: If-Let Pattern

```swift
if let ph = log.phValue {
    Text("pH: \(ph, specifier: "%.1f")")
} else {
    Text("pH: --")
        .foregroundStyle(.tertiary)
}
```

#### Option 3: Using Optional Map

```swift
Text("pH: \(log.phValue.map { String(format: "%.1f", $0) } ?? "--")")
```

## Saving Values

When creating or updating logs, save values as optional:

### ✅ Correct Way

```swift
// From text field (empty string = nil)
log.ph = Double(phTextField).map { NSNumber(value: $0) }

// Direct value
log.ph = NSNumber(value: 7.4)

// Clear/unmeasure a value
log.ph = nil
```

### ❌ Wrong Way

```swift
// DON'T do this - forces 0.0 instead of nil
log.ph = NSNumber(value: Double(phTextField) ?? 0.0)
```

## Charts and Analytics

When working with charts, use `compactMap` to filter out nil values:

### ✅ Correct Way

```swift
let chartData = logs.compactMap { log -> ChartDataPoint? in
    guard let date = log.date, let ph = log.phValue else { return nil }
    return ChartDataPoint(date: date, value: ph)
}
```

### Calculating Averages

```swift
let phValues = logs.compactMap { $0.phValue }
guard !phValues.isEmpty else { return nil }
let average = phValues.reduce(0, +) / Double(phValues.count)
```

## Common UI Patterns

### Metric Cards

```swift
struct MetricCard: View {
    let title: String
    let value: Double?
    let unit: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
            
            if let value = value {
                Text("\(value, specifier: "%.1f") \(unit)")
                    .font(.title2)
            } else {
                Text("--")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// Usage
MetricCard(title: "pH", value: log.phValue, unit: "")
MetricCard(title: "FC", value: log.fcValue, unit: "ppm")
```

### List Rows

```swift
struct PoolLogRow: View {
    let log: PoolLog
    
    var body: some View {
        HStack {
            Text("pH: \(log.phValue.formatted())")
            Spacer()
            Text("FC: \(log.fcValue.formatted(with: "%.1f", unit: "ppm"))")
        }
    }
}
```

### Detail Views

```swift
struct LogDetailView: View {
    let log: PoolLog
    
    var body: some View {
        Form {
            Section("Water Chemistry") {
                LabeledContent("pH", value: log.phValue.formatted())
                LabeledContent("Free Chlorine", value: log.fcValue.formatted(with: "%.1f", unit: "ppm"))
                LabeledContent("Total Alkalinity", value: log.taValue.formatted(with: "%.0f", unit: "ppm"))
                LabeledContent("Calcium Hardness", value: log.chValue.formatted(with: "%.0f", unit: "ppm"))
                LabeledContent("CYA", value: log.cyaValue.formatted(with: "%.0f", unit: "ppm"))
                LabeledContent("Salt", value: log.saltPpmValue.formatted(with: "%.0f", unit: "ppm"))
            }
        }
    }
}
```

## Export/Import

When exporting, handle nil values appropriately:

```swift
// For JSON export - use 0.0 as fallback for compatibility
let exportable = PoolLogExportable(
    id: log.id ?? UUID(),
    date: log.date ?? Date(),
    ph: log.phValue ?? 0.0,
    fc: log.fcValue ?? 0.0,
    // ...
)

// Or better, make the export model have optional properties too
struct PoolLogExportable: Codable {
    let id: UUID
    let date: Date
    let ph: Double?
    let fc: Double?
    // ...
}
```

## Testing

When creating test data with unmeasured values:

```swift
// In previews or tests
let log = PoolLog(context: context)
log.id = UUID()
log.date = Date()
log.ph = NSNumber(value: 7.4)  // Measured
log.fc = NSNumber(value: 3.0)  // Measured
log.ta = nil                    // Not measured
log.ch = nil                    // Not measured
log.cya = NSNumber(value: 35)  // Measured
log.saltPpm = nil               // Not measured
```

## Summary

✅ **Do:**
- Use `.phValue`, `.fcValue`, etc. computed properties
- Use the `.formatted()` extension method
- Handle nil explicitly when needed
- Use `compactMap` for calculations
- Set values to `nil` when unmeasured

❌ **Don't:**
- Use `?? 0.0` for display purposes
- Force unwrap chemistry values
- Treat `0.0` as "unmeasured"

## Files Updated

The following files have been updated to properly handle optional values:

- `PoolLog+CoreDataClass.swift` - Core Data model with helper extensions
- `AnalyticsComponents.swift` - All analytics components
- `AnalyticsViewModel.swift` - Chart data generation
- `AnalyticsView.swift` - Main analytics view
- `ChartComponents.swift` - Chart rendering
- `LogListView.swift` - Log list display
- `ImportExportIntegrationExamples.swift` - Example implementations
- `DataValidationUtilities.swift` - Validation and statistics
- `AddEditLogViewModel.swift` - Creating/editing logs

When adding new views or features, follow the patterns established in these files.
