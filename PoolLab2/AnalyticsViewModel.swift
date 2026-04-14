import Foundation
import SwiftUI
import CoreData
import Combine

@MainActor
class AnalyticsViewModel: ObservableObject {
    @Published var selectedMetric: ChemistryMetric = .ph
    @Published var selectedTimeRange: TimeRange = .last30Days
    @Published var selectedChemicalType: ChemicalType = .all
    
    @Published private(set) var poolLogs: [PoolLog] = []
    @Published private(set) var chartData: [ChartDataPoint] = []
    @Published private(set) var chemicalUsageData: [ChemicalUsageData] = []
    @Published private(set) var metricStatistics: MetricStatistics?
    
    private let context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()
    
    var hasData: Bool {
        !poolLogs.isEmpty
    }
    
    var yAxisDomain: ClosedRange<Double> {
        guard !chartData.isEmpty else { return 0...10 }
        
        let values = chartData.map { $0.value }
        let min = values.min() ?? 0
        let max = values.max() ?? 10
        let padding = (max - min) * 0.1
        
        return (min - padding)...(max + padding)
    }
    
    var xAxisStride: Calendar.Component {
        switch selectedTimeRange {
        case .last7Days:
            return .day
        case .last30Days:
            return .day
        case .last90Days:
            return .weekOfYear
        case .allTime:
            return .month
        }
    }
    
    init(context: NSManagedObjectContext) {
        self.context = context
        setupObservers()
        fetchData()
    }
    
    private func setupObservers() {
        Publishers.CombineLatest3(
            $selectedMetric,
            $selectedTimeRange,
            $selectedChemicalType
        )
        .debounce(for: 0.1, scheduler: RunLoop.main)
        .sink { [weak self] _, _, _ in
            self?.fetchData()
        }
        .store(in: &cancellables)
    }
    
    private func fetchData() {
        fetchPoolLogs()
        updateChartData()
        updateChemicalUsageData()
        calculateStatistics()
    }
    
    private func fetchPoolLogs() {
        let fetchRequest: NSFetchRequest<PoolLog> = PoolLog.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \PoolLog.date, ascending: true)]
        
        if let predicate = timeRangePredicate() {
            fetchRequest.predicate = predicate
        }
        
        do {
            poolLogs = try context.fetch(fetchRequest)
        } catch {
            print("Error fetching pool logs: \(error)")
            poolLogs = []
        }
    }
    
    private func timeRangePredicate() -> NSPredicate? {
        guard selectedTimeRange != .allTime else { return nil }
        
        let calendar = Calendar.current
        let endDate = Date()
        
        let startDate: Date
        switch selectedTimeRange {
        case .last7Days:
            startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        case .last30Days:
            startDate = calendar.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        case .last90Days:
            startDate = calendar.date(byAdding: .day, value: -90, to: endDate) ?? endDate
        case .allTime:
            return nil
        }
        
        return NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
    }
    
    private func updateChartData() {
        chartData = poolLogs.compactMap { log in
            guard let date = log.date else { return nil }
            
            let value: Double
            switch selectedMetric {
            case .ph:
                value = log.ph
            case .freeChlorine:
                value = log.fc
            case .totalAlkalinity:
                value = log.ta
            case .calciumHardness:
                value = log.ch
            case .cya:
                value = log.cya
            case .salt:
                value = log.saltPpm
            }
            
            return ChartDataPoint(date: date, value: value)
        }
    }
    
    private func updateChemicalUsageData() {
        let fetchRequest: NSFetchRequest<ChemicalEntry> = ChemicalEntry.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ChemicalEntry.date, ascending: true)]
        
        var predicates: [NSPredicate] = []
        
        // Time range filter
        if let timePredicate = timeRangePredicate() {
            predicates.append(timePredicate)
        }
        
        // Chemical type filter
        if selectedChemicalType != .all {
            predicates.append(NSPredicate(format: "type == %@", selectedChemicalType.rawValue))
        }
        
        if !predicates.isEmpty {
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        do {
            let chemicals = try context.fetch(fetchRequest)
            chemicalUsageData = groupChemicalsByPeriod(chemicals)
        } catch {
            print("Error fetching chemical entries: \(error)")
            chemicalUsageData = []
        }
    }
    
    private func groupChemicalsByPeriod(_ chemicals: [ChemicalEntry]) -> [ChemicalUsageData] {
        let calendar = Calendar.current
        let groupingComponent: Calendar.Component = selectedTimeRange == .last7Days ? .day : .weekOfYear
        
        var grouped: [String: Double] = [:]
        
        for chemical in chemicals {
            guard let date = chemical.date else { continue }
            
            let periodKey: String
            if groupingComponent == .day {
                periodKey = formatDate(date, format: "MMM d")
            } else {
                let weekOfYear = calendar.component(.weekOfYear, from: date)
                let year = calendar.component(.year, from: date)
                periodKey = "Week \(weekOfYear)"
            }
            
            grouped[periodKey, default: 0] += chemical.amount
        }
        
        return grouped.map { ChemicalUsageData(period: $0.key, totalAmount: $0.value) }
            .sorted { $0.period < $1.period }
    }
    
    private func calculateStatistics() {
        guard !chartData.isEmpty else {
            metricStatistics = nil
            return
        }
        
        let values = chartData.map { $0.value }
        let sum = values.reduce(0, +)
        let average = sum / Double(values.count)
        let min = values.min() ?? 0
        let max = values.max() ?? 0
        
        metricStatistics = MetricStatistics(average: average, min: min, max: max)
    }
    
    private func formatDate(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types

enum ChemistryMetric: String, CaseIterable {
    case ph = "pH"
    case freeChlorine = "fc"
    case totalAlkalinity = "ta"
    case calciumHardness = "ch"
    case cya = "cya"
    case salt = "salt"
    
    var displayName: String {
        switch self {
        case .ph: return "pH"
        case .freeChlorine: return "Free Chlorine"
        case .totalAlkalinity: return "Total Alkalinity"
        case .calciumHardness: return "Calcium Hardness"
        case .cya: return "CYA"
        case .salt: return "Salt"
        }
    }
    
    var unit: String {
        switch self {
        case .ph: return ""
        case .freeChlorine: return "ppm"
        case .totalAlkalinity: return "ppm"
        case .calciumHardness: return "ppm"
        case .cya: return "ppm"
        case .salt: return "ppm"
        }
    }
    
    var color: Color {
        switch self {
        case .ph: return .blue
        case .freeChlorine: return .green
        case .totalAlkalinity: return .orange
        case .calciumHardness: return .purple
        case .cya: return .pink
        case .salt: return .cyan
        }
    }
}

enum TimeRange: String, CaseIterable {
    case last7Days = "7d"
    case last30Days = "30d"
    case last90Days = "90d"
    case allTime = "all"
    
    var displayName: String {
        switch self {
        case .last7Days: return "7 Days"
        case .last30Days: return "30 Days"
        case .last90Days: return "90 Days"
        case .allTime: return "All Time"
        }
    }
}

enum ChemicalType: String, CaseIterable {
    case all = "all"
    case acid = "acid"
    case chlorine = "chlorine"
    case salt = "salt"
    
    var displayName: String {
        switch self {
        case .all: return "All Chemicals"
        case .acid: return "Acid"
        case .chlorine: return "Chlorine"
        case .salt: return "Salt"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .gray
        case .acid: return .red
        case .chlorine: return .green
        case .salt: return .blue
        }
    }
}

struct ChartDataPoint {
    let date: Date
    let value: Double
}

struct ChemicalUsageData: Identifiable {
    let id = UUID()
    let period: String
    let totalAmount: Double
}

struct MetricStatistics {
    let average: Double
    let min: Double
    let max: Double
}

// MARK: - Core Data Extensions

extension PoolLog {
    static func fetchRequest() -> NSFetchRequest<PoolLog> {
        NSFetchRequest<PoolLog>(entityName: "PoolLog")
    }
}

extension ChemicalEntry {
    static func fetchRequest() -> NSFetchRequest<ChemicalEntry> {
        NSFetchRequest<ChemicalEntry>(entityName: "ChemicalEntry")
    }
}

