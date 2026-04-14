import SwiftUI
import Charts

/// Standalone analytics components that can be used independently
/// or integrated into other views

// MARK: - Metric Card Component

struct MetricCard: View {
    let metric: ChemistryMetric
    let currentValue: Double
    let average: Double
    let trend: TrendIndicator
    
    enum TrendIndicator {
        case up, down, stable
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "minus"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .stable: return .gray
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: iconForMetric)
                    .font(.title3)
                    .foregroundStyle(metric.color)
                
                Spacer()
                
                Image(systemName: trend.icon)
                    .font(.caption)
                    .foregroundStyle(trend.color)
            }
            
            Text(metric.displayName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(currentValue, specifier: "%.1f")")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(metric.unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 4) {
                Text("Avg:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(average, specifier: "%.1f")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var iconForMetric: String {
        switch metric {
        case .ph: return "drop.fill"
        case .freeChlorine: return "waveform.circle.fill"
        case .totalAlkalinity: return "chart.bar.fill"
        case .calciumHardness: return "cube.fill"
        case .cya: return "sun.max.fill"
        case .salt: return "sparkles"
        }
    }
}

// MARK: - Compact Analytics View

struct CompactAnalyticsView: View {
    let logs: [PoolLog]
    @State private var selectedMetric: ChemistryMetric = .ph
    
    var body: some View {
        VStack(spacing: 16) {
            // Metric cards
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach([ChemistryMetric.ph, .freeChlorine, .totalAlkalinity, .salt], id: \.self) { metric in
                    MetricCard(
                        metric: metric,
                        currentValue: currentValue(for: metric),
                        average: averageValue(for: metric),
                        trend: trendFor(metric)
                    )
                    .onTapGesture {
                        selectedMetric = metric
                    }
                }
            }
            
            // Mini chart
            VStack(alignment: .leading, spacing: 8) {
                Text(selectedMetric.displayName)
                    .font(.headline)
                
                Chart {
                    ForEach(chartData(for: selectedMetric), id: \.date) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(selectedMetric.color.gradient)
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 150)
                .chartXAxis(.hidden)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
    
    private func currentValue(for metric: ChemistryMetric) -> Double {
        guard let latest = logs.first else { return 0 }
        
        switch metric {
        case .ph: return latest.ph
        case .freeChlorine: return latest.fc
        case .totalAlkalinity: return latest.ta
        case .calciumHardness: return latest.ch
        case .cya: return latest.cya
        case .salt: return latest.saltPpm
        }
    }
    
    private func averageValue(for metric: ChemistryMetric) -> Double {
        let values = logs.map { log in
            switch metric {
            case .ph: return log.ph
            case .freeChlorine: return log.fc
            case .totalAlkalinity: return log.ta
            case .calciumHardness: return log.ch
            case .cya: return log.cya
            case .salt: return log.saltPpm
            }
        }
        
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
    
    private func trendFor(_ metric: ChemistryMetric) -> MetricCard.TrendIndicator {
        guard logs.count >= 2 else { return .stable }
        
        let current = currentValue(for: metric)
        let previous = previousValue(for: metric)
        
        let change = ((current - previous) / previous) * 100
        
        if abs(change) < 3 {
            return .stable
        } else if change > 0 {
            return .up
        } else {
            return .down
        }
    }
    
    private func previousValue(for metric: ChemistryMetric) -> Double {
        guard logs.count >= 2 else { return 0 }
        let previous = logs[1]
        
        switch metric {
        case .ph: return previous.ph
        case .freeChlorine: return previous.fc
        case .totalAlkalinity: return previous.ta
        case .calciumHardness: return previous.ch
        case .cya: return previous.cya
        case .salt: return previous.saltPpm
        }
    }
    
    private func chartData(for metric: ChemistryMetric) -> [ChartDataPoint] {
        logs.compactMap { log in
            guard let date = log.date else { return nil }
            
            let value: Double
            switch metric {
            case .ph: value = log.ph
            case .freeChlorine: value = log.fc
            case .totalAlkalinity: value = log.ta
            case .calciumHardness: value = log.ch
            case .cya: value = log.cya
            case .salt: value = log.saltPpm
            }
            
            return ChartDataPoint(date: date, value: value)
        }
    }
}

// MARK: - Dashboard Summary View

struct DashboardAnalyticsView: View {
    let logs: [PoolLog]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pool Overview")
                .font(.title2)
                .fontWeight(.bold)
            
            // Status indicator
            StatusBanner(status: poolStatus)
            
            // Quick metrics
            HStack(spacing: 12) {
                QuickMetric(title: "pH", value: latestPH, target: "7.2-7.6", isInRange: phInRange)
                QuickMetric(title: "FC", value: latestFC, target: "2-4", isInRange: fcInRange)
            }
            
            // Mini trend
            VStack(alignment: .leading, spacing: 8) {
                Text("7-Day Trend")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Chart {
                    ForEach(recentLogs, id: \.id) { log in
                        LineMark(
                            x: .value("Date", log.date ?? Date()),
                            y: .value("pH", log.ph)
                        )
                        .foregroundStyle(.blue.gradient)
                    }
                }
                .frame(height: 80)
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
    
    private var recentLogs: [PoolLog] {
        Array(logs.prefix(7))
    }
    
    private var latestPH: String {
        guard let latest = logs.first else { return "--" }
        return String(format: "%.1f", latest.ph)
    }
    
    private var latestFC: String {
        guard let latest = logs.first else { return "--" }
        return String(format: "%.1f", latest.fc)
    }
    
    private var phInRange: Bool {
        guard let latest = logs.first else { return false }
        return (7.2...7.6).contains(latest.ph)
    }
    
    private var fcInRange: Bool {
        guard let latest = logs.first else { return false }
        return (2.0...4.0).contains(latest.fc)
    }
    
    private var poolStatus: PoolStatus {
        if phInRange && fcInRange {
            return .good
        } else if !phInRange || !fcInRange {
            return .needsAttention
        } else {
            return .unknown
        }
    }
}

struct StatusBanner: View {
    let status: PoolStatus
    
    var body: some View {
        HStack {
            Image(systemName: status.icon)
                .foregroundStyle(status.color)
            
            Text(status.title)
                .fontWeight(.medium)
            
            Spacer()
        }
        .padding()
        .background(status.color.opacity(0.1))
        .cornerRadius(8)
    }
}

enum PoolStatus {
    case good, needsAttention, unknown
    
    var icon: String {
        switch self {
        case .good: return "checkmark.circle.fill"
        case .needsAttention: return "exclamationmark.triangle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .good: return .green
        case .needsAttention: return .orange
        case .unknown: return .gray
        }
    }
    
    var title: String {
        switch self {
        case .good: return "Pool chemistry looks good"
        case .needsAttention: return "Pool needs attention"
        case .unknown: return "No recent data"
        }
    }
}

struct QuickMetric: View {
    let title: String
    let value: String
    let target: String
    let isInRange: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Image(systemName: isInRange ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(isInRange ? .green : .orange)
            }
            
            Text(target)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Previews

#Preview("Metric Card") {
    MetricCard(
        metric: .ph,
        currentValue: 7.4,
        average: 7.3,
        trend: .up
    )
    .padding()
}

#Preview("Compact Analytics") {
    let controller = PersistenceController.preview
    let context = controller.container.viewContext
    
    let logs = (0..<7).map { i in
        let log = PoolLog(context: context)
        log.id = UUID()
        log.date = Calendar.current.date(byAdding: .day, value: -i, to: Date())
        log.ph = 7.2 + Double.random(in: -0.2...0.2)
        log.fc = 3.0 + Double.random(in: -1.0...1.0)
        log.ta = 90 + Double.random(in: -10...10)
        log.ch = 250
        log.cya = 35
        log.saltPpm = 3200
        return log
    }
    
    return CompactAnalyticsView(logs: logs)
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Dashboard") {
    let controller = PersistenceController.preview
    let context = controller.container.viewContext
    
    let logs = (0..<7).map { i in
        let log = PoolLog(context: context)
        log.id = UUID()
        log.date = Calendar.current.date(byAdding: .day, value: -i, to: Date())
        log.ph = 7.3 + Double.random(in: -0.1...0.1)
        log.fc = 3.0 + Double.random(in: -0.5...0.5)
        log.ta = 90
        log.ch = 250
        log.cya = 35
        log.saltPpm = 3200
        return log
    }
    
    return DashboardAnalyticsView(logs: logs)
        .padding()
        .background(Color(.systemGroupedBackground))
}

