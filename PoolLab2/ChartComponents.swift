import SwiftUI
import Charts

struct TrendChartView: View {
    let data: [ChartDataPoint]
    let metric: ChemistryMetric
    let showAverage: Bool
    
    init(data: [ChartDataPoint], metric: ChemistryMetric, showAverage: Bool = true) {
        self.data = data
        self.metric = metric
        self.showAverage = showAverage
    }
    
    var body: some View {
        Chart {
            ForEach(data, id: \.date) { dataPoint in
                LineMark(
                    x: .value("Date", dataPoint.date, unit: .day),
                    y: .value(metric.displayName, dataPoint.value)
                )
                .foregroundStyle(metric.color.gradient)
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("Date", dataPoint.date, unit: .day),
                    y: .value(metric.displayName, dataPoint.value)
                )
                .foregroundStyle(metric.color)
                .symbolSize(50)
            }
            
            if showAverage, let average = averageValue {
                RuleMark(y: .value("Average", average))
                    .foregroundStyle(.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            }
        }
        .chartYScale(domain: yAxisDomain)
    }
    
    private var averageValue: Double? {
        guard !data.isEmpty else { return nil }
        return data.map { $0.value }.reduce(0, +) / Double(data.count)
    }
    
    private var yAxisDomain: ClosedRange<Double> {
        guard !data.isEmpty else { return 0...10 }
        
        let values = data.map { $0.value }
        let min = values.min() ?? 0
        let max = values.max() ?? 10
        let padding = (max - min) * 0.1
        
        return (min - padding)...(max + padding)
    }
}

struct ChemicalBarChartView: View {
    let data: [ChemicalUsageData]
    let chemicalType: ChemicalType
    
    var body: some View {
        Chart {
            ForEach(data) { item in
                BarMark(
                    x: .value("Period", item.period),
                    y: .value("Amount", item.totalAmount)
                )
                .foregroundStyle(chemicalType.color.gradient)
                .annotation(position: .top) {
                    Text("\(item.totalAmount, specifier: "%.1f")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct ComparisonChartView: View {
    let logs: [PoolLog]
    let metrics: [ChemistryMetric]
    
    var body: some View {
        Chart {
            ForEach(metrics, id: \.self) { metric in
                ForEach(chartData(for: metric), id: \.date) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Value", normalizedValue(dataPoint.value, for: metric)),
                        series: .value("Metric", metric.displayName)
                    )
                    .foregroundStyle(by: .value("Metric", metric.displayName))
                    .interpolationMethod(.catmullRom)
                }
            }
        }
        .chartForegroundStyleScale([
            metrics[0].displayName: metrics[0].color,
            metrics.count > 1 ? metrics[1].displayName : "": metrics.count > 1 ? metrics[1].color : .clear
        ])
    }
    
    private func chartData(for metric: ChemistryMetric) -> [ChartDataPoint] {
        logs.compactMap { log in
            guard let date = log.date else { return nil }
            
            let value: Double?
            switch metric {
            case .ph: value = log.phValue
            case .freeChlorine: value = log.fcValue
            case .totalAlkalinity: value = log.taValue
            case .calciumHardness: value = log.chValue
            case .cya: value = log.cyaValue
            case .salt: value = log.saltPpmValue
            }
            
            guard let unwrappedValue = value else { return nil }
            return ChartDataPoint(date: date, value: unwrappedValue)
        }
    }
    
    private func normalizedValue(_ value: Double, for metric: ChemistryMetric) -> Double {
        // Normalize to 0-100 scale for comparison
        switch metric {
        case .ph:
            return (value - 6.0) / 2.0 * 100
        case .freeChlorine:
            return value / 10.0 * 100
        case .totalAlkalinity:
            return value / 200.0 * 100
        case .calciumHardness:
            return value / 500.0 * 100
        case .cya:
            return value / 100.0 * 100
        case .salt:
            return value / 5000.0 * 100
        }
    }
}

#Preview {
    VStack {
        TrendChartView(
            data: [
                ChartDataPoint(date: Date().addingTimeInterval(-86400 * 6), value: 7.2),
                ChartDataPoint(date: Date().addingTimeInterval(-86400 * 5), value: 7.4),
                ChartDataPoint(date: Date().addingTimeInterval(-86400 * 4), value: 7.1),
                ChartDataPoint(date: Date().addingTimeInterval(-86400 * 3), value: 7.3),
                ChartDataPoint(date: Date().addingTimeInterval(-86400 * 2), value: 7.5),
                ChartDataPoint(date: Date().addingTimeInterval(-86400 * 1), value: 7.2),
                ChartDataPoint(date: Date(), value: 7.4)
            ],
            metric: .ph
        )
        .frame(height: 200)
        .padding()
    }
}

