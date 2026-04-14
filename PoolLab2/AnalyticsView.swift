import SwiftUI
import Charts
import CoreData

struct AnalyticsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: AnalyticsViewModel
    
    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: AnalyticsViewModel(context: context))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Metric Selector
                    metricSection
                    
                    // Time Range Filter
                    timeRangeSection
                    
                    // Main Chart
                    if viewModel.hasData {
                        chemistryChartSection
                        
                        // Chemical Usage Chart
                        chemicalUsageSection
                    } else {
                        emptyStateView
                    }
                }
                .padding()
            }
            .navigationTitle("Analytics")
            .background(Color(.systemGroupedBackground))
        }
    }
    
    private var metricSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Chemistry Metric")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Picker("Metric", selection: $viewModel.selectedMetric) {
                ForEach(ChemistryMetric.allCases, id: \.self) { metric in
                    Text(metric.displayName).tag(metric)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var timeRangeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time Range")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Picker("Range", selection: $viewModel.selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.displayName).tag(range)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var chemistryChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.selectedMetric.displayName)
                        .font(.headline)
                    
                    if let stats = viewModel.metricStatistics {
                        HStack(spacing: 16) {
                            StatLabel(title: "Avg", value: stats.average, unit: viewModel.selectedMetric.unit)
                            StatLabel(title: "Min", value: stats.min, unit: viewModel.selectedMetric.unit)
                            StatLabel(title: "Max", value: stats.max, unit: viewModel.selectedMetric.unit)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            
            Chart {
                ForEach(viewModel.chartData, id: \.date) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date, unit: .day),
                        y: .value(viewModel.selectedMetric.displayName, dataPoint.value)
                    )
                    .foregroundStyle(viewModel.selectedMetric.color.gradient)
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Date", dataPoint.date, unit: .day),
                        y: .value(viewModel.selectedMetric.displayName, dataPoint.value)
                    )
                    .foregroundStyle(viewModel.selectedMetric.color)
                    .symbolSize(50)
                }
                
                // Average line
                if let stats = viewModel.metricStatistics {
                    RuleMark(y: .value("Average", stats.average))
                        .foregroundStyle(.gray.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("Avg: \(stats.average, specifier: "%.1f")")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(4)
                                .background(.background)
                        }
                }
            }
            .frame(height: 250)
            .chartYScale(domain: viewModel.yAxisDomain)
            .chartXAxis {
                AxisMarks(values: .stride(by: viewModel.xAxisStride)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var chemicalUsageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Chemical Usage")
                        .font(.headline)
                    
                    Text("Total amount added")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Picker("Chemical", selection: $viewModel.selectedChemicalType) {
                    ForEach(ChemicalType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.menu)
            }
            
            if !viewModel.chemicalUsageData.isEmpty {
                Chart {
                    ForEach(viewModel.chemicalUsageData, id: \.period) { data in
                        BarMark(
                            x: .value("Period", data.period),
                            y: .value("Amount", data.totalAmount)
                        )
                        .foregroundStyle(viewModel.selectedChemicalType.color.gradient)
                        .annotation(position: .top) {
                            Text("\(data.totalAmount, specifier: "%.1f")")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
            } else {
                Text("No chemical usage data for \(viewModel.selectedChemicalType.displayName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No data available yet")
                .font(.headline)
            
            Text("Start logging your pool maintenance to see analytics and trends.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

private struct StatLabel: View {
    let title: String
    let value: Double
    let unit: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text("\(title):")
                .fontWeight(.medium)
            Text("\(value, specifier: "%.1f")")
            Text(unit)
        }
    }
}

#Preview {
    let controller = PersistenceController.preview
    let context = controller.container.viewContext
    
    // Add sample data
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    
    for i in 0..<30 {
        let log = PoolLog(context: context)
        log.id = UUID()
        log.date = Calendar.current.date(byAdding: .day, value: -i, to: Date())
        log.ph = 7.2 + Double.random(in: -0.3...0.3)
        log.fc = 3.0 + Double.random(in: -1.0...1.0)
        log.ta = 80 + Double.random(in: -10...10)
        log.ch = 250 + Double.random(in: -20...20)
        log.cya = 30 + Double.random(in: -5...5)
        log.saltPpm = 3200 + Double.random(in: -200...200)
        
        if i % 3 == 0 {
            let chemical = ChemicalEntry(context: context)
            chemical.id = UUID()
            chemical.date = log.date!
            chemical.type = ["acid", "chlorine", "salt"].randomElement()!
            chemical.amount = Double.random(in: 1...10)
            chemical.unit = "oz"
            chemical.poolLog = log
        }
    }
    
    try? context.save()
    
    return AnalyticsView(context: context)
}

