import Foundation
import SwiftUI
internal import CoreData
import Charts

// MARK: - Example 1: Basic Analytics View Usage

/*
 
 The AnalyticsView is automatically included in your TabView.
 Just navigate to the Analytics tab to view charts.
 
 */

// MARK: - Example 2: Programmatic Access to Analytics Data

func getAnalyticsSnapshot(context: NSManagedObjectContext) {
    let viewModel = AnalyticsViewModel(context: context)
    
    // Access current data
    print("Pool logs count: \(viewModel.poolLogs.count)")
    print("Chart data points: \(viewModel.chartData.count)")
    
    // Get statistics
    if let stats = viewModel.metricStatistics {
        print("Average: \(stats.average)")
        print("Min: \(stats.min)")
        print("Max: \(stats.max)")
    }
}

// MARK: - Example 3: Custom Chart Component Usage

struct CustomAnalyticsView: View {
    let logs: [PoolLog]
    
    var body: some View {
        VStack {
            // Use reusable trend chart
            TrendChartView(
                data: convertToChartData(logs),
                metric: .ph,
                showAverage: true
            )
            .frame(height: 200)
            
            // Use comparison chart
            ComparisonChartView(
                logs: logs,
                metrics: [.ph, .freeChlorine]
            )
            .frame(height: 200)
        }
    }
    
    private func convertToChartData(_ logs: [PoolLog]) -> [ChartDataPoint] {
        logs.compactMap { log -> ChartDataPoint? in
            guard let date = log.date,
                  let phValue = log.phValue else { return nil }
            
            // Check if acid was added during this log entry
            let acidAdded = log.chemicalsArray.contains { chemical in
                chemical.type?.lowercased() == "acid"
            }
            
            return ChartDataPoint(date: date, value: phValue, acidAdded: acidAdded)
        }
    }
}

// MARK: - Example 4: Filtering Data by Date Range

func fetchLogsInRange(
    timeRange: TimeRange,
    context: NSManagedObjectContext
) -> [PoolLog] {
    let fetchRequest: NSFetchRequest<PoolLog> = PoolLog.fetchRequest()
    fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \PoolLog.date, ascending: true)]
    
    if timeRange != .allTime {
        let calendar = Calendar.current
        let endDate = Date()
        
        let startDate: Date
        switch timeRange {
        case .last7Days:
            startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!
        case .last30Days:
            startDate = calendar.date(byAdding: .day, value: -30, to: endDate)!
        case .last90Days:
            startDate = calendar.date(byAdding: .day, value: -90, to: endDate)!
        case .allTime:
            return []
        }
        
        fetchRequest.predicate = NSPredicate(
            format: "date >= %@ AND date <= %@",
            startDate as NSDate,
            endDate as NSDate
        )
    }
    
    return (try? context.fetch(fetchRequest)) ?? []
}

// MARK: - Example 5: Calculating Trends

struct TrendAnalysis {
    let metric: ChemistryMetric
    let direction: TrendDirection
    let changePercentage: Double
    
    enum TrendDirection {
        case increasing
        case decreasing
        case stable
    }
}

func analyzeTrend(for logs: [PoolLog], metric: ChemistryMetric) -> TrendAnalysis? {
    guard logs.count >= 2 else { return nil }
    
    let values = logs.compactMap { log -> Double? in
        switch metric {
        case .ph: return log.ph as? Double
        case .freeChlorine: return log.fc as? Double
        case .totalAlkalinity: return log.ta as? Double
        case .calciumHardness: return log.ch as? Double
        case .cya: return log.cya as? Double
        case .salt: return log.saltPpm as? Double
        }
    }
    
    guard let first = values.first, let last = values.last, first > 0 else {
        return nil
    }
    
    let change = ((last - first) / first) * 100
    
    let direction: TrendAnalysis.TrendDirection
    if abs(change) < 5 {
        direction = .stable
    } else if change > 0 {
        direction = .increasing
    } else {
        direction = .decreasing
    }
    
    return TrendAnalysis(
        metric: metric,
        direction: direction,
        changePercentage: change
    )
}

// MARK: - Example 6: Export Chart Data

func exportChartData(
    logs: [PoolLog],
    metric: ChemistryMetric
) -> String {
    var csv = "Date,\(metric.displayName)\n"
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    
    for log in logs {
        guard let date = log.date else { continue }
        
        let value: Double
        switch metric {
        case .ph: 
            guard let v = log.ph as? Double else { continue }
            value = v
        case .freeChlorine: 
            guard let v = log.fc as? Double else { continue }
            value = v
        case .totalAlkalinity: 
            guard let v = log.ta as? Double else { continue }
            value = v
        case .calciumHardness: 
            guard let v = log.ch as? Double else { continue }
            value = v
        case .cya: 
            guard let v = log.cya as? Double else { continue }
            value = v
        case .salt: 
            guard let v = log.saltPpm as? Double else { continue }
            value = v
        }
        
        let dateString = dateFormatter.string(from: date)
        csv += "\(dateString),\(value)\n"
    }
    
    return csv
}

// MARK: - Example 7: Create Summary Report

struct PoolSummaryReport {
    let timeRange: String
    let metrics: [MetricSummary]
    let chemicalUsage: [ChemicalSummary]
    
    struct MetricSummary {
        let name: String
        let average: Double
        let min: Double
        let max: Double
        let unit: String
    }
    
    struct ChemicalSummary {
        let type: String
        let totalAmount: Double
        let unit: String
    }
}

func generateSummaryReport(
    context: NSManagedObjectContext,
    timeRange: TimeRange
) -> PoolSummaryReport {
    let logs = fetchLogsInRange(timeRange: timeRange, context: context)
    
    let metrics: [PoolSummaryReport.MetricSummary] = ChemistryMetric.allCases.map { metric in
        let values = logs.compactMap { log -> Double? in
            switch metric {
            case .ph: return log.ph as? Double
            case .freeChlorine: return log.fc as? Double
            case .totalAlkalinity: return log.ta as? Double
            case .calciumHardness: return log.ch as? Double
            case .cya: return log.cya as? Double
            case .salt: return log.saltPpm as? Double
            }
        }
        
        let avg = values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
        let min = values.min() ?? 0
        let max = values.max() ?? 0
        
        return PoolSummaryReport.MetricSummary(
            name: metric.displayName,
            average: avg,
            min: min,
            max: max,
            unit: metric.unit
        )
    }
    
    // Chemical usage summary
    let chemicalFetch: NSFetchRequest<ChemicalEntry> = ChemicalEntry.fetchRequest()
    let chemicals = (try? context.fetch(chemicalFetch)) ?? []
    
    var chemicalTotals: [String: Double] = [:]
    for chemical in chemicals {
        chemicalTotals[chemical.type ?? "unknown", default: 0] += chemical.amount
    }
    
    let chemicalSummaries = chemicalTotals.map { type, amount in
        PoolSummaryReport.ChemicalSummary(type: type, totalAmount: amount, unit: "oz")
    }
    
    return PoolSummaryReport(
        timeRange: timeRange.displayName,
        metrics: metrics,
        chemicalUsage: chemicalSummaries
    )
}

// MARK: - Example 8: Custom Chart with Goals

struct GoalLineChart: View {
    let data: [ChartDataPoint]
    let metric: ChemistryMetric
    let goalRange: ClosedRange<Double>
    
    var body: some View {
        Chart {
            // Goal range area
            RectangleMark(
                yStart: .value("Min Goal", goalRange.lowerBound),
                yEnd: .value("Max Goal", goalRange.upperBound)
            )
            .foregroundStyle(.green.opacity(0.1))
            
            // Data line
            ForEach(data, id: \.date) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(colorForValue(point.value))
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(colorForValue(point.value))
                .symbolSize(50)
            }
            
            // Goal lines
            RuleMark(y: .value("Min", goalRange.lowerBound))
                .foregroundStyle(.green)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            
            RuleMark(y: .value("Max", goalRange.upperBound))
                .foregroundStyle(.green)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
        }
        .frame(height: 250)
    }
    
    private func colorForValue(_ value: Double) -> Color {
        if goalRange.contains(value) {
            return .green
        } else {
            return .red
        }
    }
}

// MARK: - Example 9: Typical Goal Ranges

extension ChemistryMetric {
    var idealRange: ClosedRange<Double> {
        switch self {
        case .ph:
            return 7.2...7.6
        case .freeChlorine:
            return 2.0...4.0
        case .totalAlkalinity:
            return 80...120
        case .calciumHardness:
            return 200...400
        case .cya:
            return 30...50
        case .salt:
            return 2700...3400
        }
    }
}

// MARK: - Example 10: Alerts for Out of Range Values

func checkForAlerts(logs: [PoolLog]) -> [PoolAlert] {
    var alerts: [PoolAlert] = []
    
    guard let latestLog = logs.first else { return alerts }
    
    // Check pH
    if let phValue = latestLog.ph as? Double {
        if phValue < 7.0 || phValue > 7.8 {
            alerts.append(PoolAlert(
                metric: .ph,
                value: phValue,
                message: "pH is out of ideal range (7.2-7.6)"
            ))
        }
    }
    
    // Check Free Chlorine
    if let fcValue = latestLog.fc as? Double {
        if fcValue < 1.0 || fcValue > 5.0 {
            alerts.append(PoolAlert(
                metric: .freeChlorine,
                value: fcValue,
                message: "Free Chlorine is out of ideal range (2.0-4.0 ppm)"
            ))
        }
    }
    
    return alerts
}

struct PoolAlert {
    let metric: ChemistryMetric
    let value: Double
    let message: String
}

