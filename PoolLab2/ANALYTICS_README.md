# Data Visualization Feature - Analytics

## Overview

Production-quality data visualization feature for pool maintenance app using **Swift Charts**, SwiftUI, and Core Data following MVVM architecture.

## Features

### ✨ Core Functionality

- **Chemistry Trend Charts**
  - Line charts for pH, Free Chlorine, Total Alkalinity, Calcium Hardness, CYA, Salt
  - Smooth curve interpolation (Catmull-Rom)
  - Point markers for individual readings
  - Average reference line with annotation

- **Chemical Usage Analytics**
  - Bar charts showing chemical usage over time
  - Grouped by day or week based on time range
  - Filter by chemical type (acid, chlorine, salt, or all)
  - Total amounts displayed on bars

- **Time Range Filtering**
  - Last 7 days
  - Last 30 days
  - Last 90 days
  - All time

- **Statistics**
  - Average, Min, Max values for each metric
  - Color-coded by metric type
  - Responsive to selected time range

### 🎨 UI/UX

- Clean, modern interface with sections
- Segmented controls for metric and time range selection
- Dropdown menu for chemical type filtering
- Empty state with helpful messaging
- Responsive charts with proper scaling
- Automatic axis formatting based on date range

## Architecture

```
AnalyticsView.swift
├── AnalyticsViewModel (@MainActor, ObservableObject)
├── ChartComponents.swift (Reusable chart views)
└── Supporting Types:
    ├── ChemistryMetric (enum)
    ├── TimeRange (enum)
    ├── ChemicalType (enum)
    ├── ChartDataPoint (struct)
    ├── ChemicalUsageData (struct)
    └── MetricStatistics (struct)
```

## Files Created

1. **AnalyticsView.swift** - Main SwiftUI view with chart UI
2. **AnalyticsViewModel.swift** - View model with data fetching and processing
3. **ChartComponents.swift** - Reusable chart components
4. **ANALYTICS_README.md** - This documentation

## Updated Files

1. **ContentView.swift** - Added Analytics tab

## Usage

### Basic Implementation

The Analytics view is automatically added to your TabView:

```swift
AnalyticsView(context: viewContext)
    .tabItem {
        Label("Analytics", systemImage: "chart.xyaxis.line")
    }
```

### Accessing Analytics

1. Launch the app
2. Tap the **"Analytics"** tab (chart icon)
3. Select a chemistry metric (pH, FC, TA, etc.)
4. Choose a time range (7d, 30d, 90d, All)
5. View trends and statistics
6. Scroll down to see chemical usage
7. Filter chemical usage by type

### Chart Features

#### Chemistry Trends
- **X-axis**: Date (formatted based on time range)
- **Y-axis**: Metric value (auto-scaled with padding)
- **Line**: Smooth curve connecting data points
- **Points**: Individual readings
- **Average Line**: Dashed gray line with annotation

#### Chemical Usage
- **X-axis**: Time period (day or week)
- **Y-axis**: Total amount added
- **Bars**: Color-coded by chemical type
- **Annotations**: Values displayed on top of bars

## Data Processing

### Filtering Logic

```swift
// Time range filtering
let startDate = calendar.date(byAdding: .day, value: -30, to: Date())
let predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate, endDate)

// Chemical type filtering
if selectedChemicalType != .all {
    predicate = NSPredicate(format: "type == %@", selectedChemicalType.rawValue)
}
```

### Grouping Logic

```swift
// Group chemicals by period (day or week)
let groupingComponent: Calendar.Component = selectedTimeRange == .last7Days ? .day : .weekOfYear

var grouped: [String: Double] = [:]
for chemical in chemicals {
    let periodKey = formatDate(chemical.date)
    grouped[periodKey, default: 0] += chemical.amount
}
```

### Statistics Calculation

```swift
let values = chartData.map { $0.value }
let average = values.reduce(0, +) / Double(values.count)
let min = values.min()
let max = values.max()
```

## Chart Types Supported

### 1. Line Chart (Primary)
- `LineMark` for trends
- `PointMark` for individual readings
- `RuleMark` for average line
- Catmull-Rom interpolation for smooth curves

### 2. Bar Chart (Chemical Usage)
- `BarMark` for totals
- Gradient fills
- Top annotations

### 3. Comparison Chart (Bonus)
- Multiple metrics on same chart
- Normalized values (0-100 scale)
- Color-coded series

## Empty State

When no data exists:
- Shows chart icon
- Displays "No data available yet"
- Provides helpful message: "Start logging your pool maintenance to see analytics and trends."

## Color Coding

| Metric | Color |
|--------|-------|
| pH | Blue |
| Free Chlorine | Green |
| Total Alkalinity | Orange |
| Calcium Hardness | Purple |
| CYA | Pink |
| Salt | Cyan |

| Chemical | Color |
|----------|-------|
| Acid | Red |
| Chlorine | Green |
| Salt | Blue |
| All | Gray |

## Performance

- **Reactive Updates**: Uses Combine to debounce rapid changes
- **Efficient Fetching**: Core Data fetch requests with predicates
- **Lazy Loading**: Charts render only visible data
- **Memory Safe**: Weak self references in closures

## Extension Possibilities

### Already Implemented
- ✅ Multiple metrics (pH, FC, TA, CH, CYA, Salt)
- ✅ Time range filtering
- ✅ Average line with annotation
- ✅ Min/Max statistics
- ✅ Chemical usage analytics
- ✅ Empty state handling

### Future Enhancements
- 📊 Export data as CSV
- 🎯 Goal ranges (ideal pH: 7.2-7.6)
- 📱 Haptic feedback on data point tap
- 🔔 Alerts when metrics go out of range
- 📈 Trend predictions (linear regression)
- 🏊 Multiple pool support
- 🌡️ Temperature correlation

## Testing

Preview data included in AnalyticsView:
- 30 days of sample pool logs
- Random chemistry readings
- Sample chemical entries
- Tests all chart scenarios

```swift
#Preview {
    let controller = PersistenceController.preview
    let context = controller.container.viewContext
    
    // Sample data creation...
    
    return AnalyticsView(context: context)
}
```

## Requirements

- iOS 16.0+ (Swift Charts requirement)
- SwiftUI
- Core Data
- Swift Charts framework

## Integration Checklist

- ✅ AnalyticsView.swift added
- ✅ AnalyticsViewModel.swift added
- ✅ ChartComponents.swift added
- ✅ ContentView.swift updated with Analytics tab
- ✅ Uses existing PoolLog and ChemicalEntry entities
- ✅ Preview data included
- ✅ MVVM architecture followed
- ✅ Production-ready code

## Code Quality

- ✅ MVVM architecture
- ✅ Combine for reactive updates
- ✅ Swift Concurrency (@MainActor)
- ✅ Type-safe enums and structs
- ✅ Computed properties for derived data
- ✅ Error handling
- ✅ Clean separation of concerns
- ✅ SwiftUI best practices
- ✅ Preview support

---

**Ready to run.** All files created and integrated. Just add the files to your Xcode target and build!

