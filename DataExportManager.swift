import Foundation
import CoreData
import UniformTypeIdentifiers

/// Manages export of pool data to various formats
@MainActor
class DataExportManager: ObservableObject {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - JSON Export
    
    /// Exports all app data to JSON format
    func exportToJSON() throws -> Data {
        let exportData = PoolDataExport(
            exportDate: Date(),
            version: "1.0",
            poolLogs: try fetchAllPoolLogs(),
            chemicalEntries: try fetchAllChemicalEntries(),
            maintenanceTasks: try fetchAllMaintenanceTasks()
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        return try encoder.encode(exportData)
    }
    
    /// Exports pool logs to JSON
    func exportPoolLogsToJSON() throws -> Data {
        let logs = try fetchAllPoolLogs()
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        return try encoder.encode(logs)
    }
    
    // MARK: - CSV Export
    
    /// Exports pool logs to CSV format
    func exportPoolLogsToCSV() throws -> Data {
        let logs = try fetchAllPoolLogs()
        
        var csv = "Date,pH,Free Chlorine (ppm),Total Alkalinity (ppm),Calcium Hardness (ppm),CYA (ppm),Salt (ppm),Notes\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        for log in logs.sorted(by: { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }) {
            let dateStr = log.date.map { dateFormatter.string(from: $0) } ?? ""
            let notesStr = log.notes?.replacingOccurrences(of: ",", with: ";") ?? ""
            
            csv += "\(dateStr),\(log.ph),\(log.fc),\(log.ta),\(log.ch),\(log.cya),\(log.saltPpm),\"\(notesStr)\"\n"
        }
        
        guard let data = csv.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }
        
        return data
    }
    
    /// Exports chemical usage to CSV format
    func exportChemicalEntriesToCSV() throws -> Data {
        let entries = try fetchAllChemicalEntries()
        
        var csv = "Date,Chemical Type,Amount,Unit\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        for entry in entries.sorted(by: { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }) {
            let dateStr = entry.date.map { dateFormatter.string(from: $0) } ?? ""
            let type = entry.type ?? "Unknown"
            let unit = entry.unit ?? "oz"
            
            csv += "\(dateStr),\(type),\(entry.amount),\(unit)\n"
        }
        
        guard let data = csv.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }
        
        return data
    }
    
    /// Exports maintenance tasks to CSV format
    func exportMaintenanceTasksToCSV() throws -> Data {
        let tasks = try fetchAllMaintenanceTasks()
        
        var csv = "Task Name,Interval (days),Last Completed,Next Due,Status,Notes\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        for task in tasks.sorted(by: { $0.name < $1.name }) {
            let lastCompleted = dateFormatter.string(from: task.lastCompletedDate)
            let nextDue = dateFormatter.string(from: task.nextDueDate)
            let status = task.status.description
            let notes = task.notes?.replacingOccurrences(of: ",", with: ";") ?? ""
            
            csv += "\(task.name),\(task.intervalDays),\(lastCompleted),\(nextDue),\(status),\"\(notes)\"\n"
        }
        
        guard let data = csv.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }
        
        return data
    }
    
    // MARK: - Fetch Helpers
    
    private func fetchAllPoolLogs() throws -> [PoolLogExportable] {
        let request: NSFetchRequest<PoolLog> = PoolLog.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PoolLog.date, ascending: false)]
        
        let logs = try context.fetch(request)
        
        return logs.map { log in
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
    }
    
    private func fetchAllChemicalEntries() throws -> [ChemicalEntryExportable] {
        let request: NSFetchRequest<ChemicalEntry> = ChemicalEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ChemicalEntry.date, ascending: false)]
        
        let entries = try context.fetch(request)
        
        return entries.map { entry in
            ChemicalEntryExportable(
                id: entry.id ?? UUID(),
                date: entry.date ?? Date(),
                type: entry.type ?? "Unknown",
                amount: entry.amount,
                unit: entry.unit ?? "oz"
            )
        }
    }
    
    private func fetchAllMaintenanceTasks() throws -> [MaintenanceTaskExportable] {
        let request: NSFetchRequest<MaintenanceTask> = MaintenanceTask.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MaintenanceTask.name, ascending: true)]
        
        let tasks = try context.fetch(request)
        
        return tasks.map { task in
            MaintenanceTaskExportable(
                id: task.id,
                name: task.name,
                intervalDays: Int(task.intervalDays),
                lastCompletedDate: task.lastCompletedDate,
                isEnabled: task.isEnabled,
                notes: task.notes
            )
        }
    }
}

// MARK: - Export Data Structures

struct PoolDataExport: Codable {
    let exportDate: Date
    let version: String
    let poolLogs: [PoolLogExportable]
    let chemicalEntries: [ChemicalEntryExportable]
    let maintenanceTasks: [MaintenanceTaskExportable]
}

struct PoolLogExportable: Codable, Identifiable {
    let id: UUID
    let date: Date
    let ph: Double
    let fc: Double
    let ta: Double
    let ch: Double
    let cya: Double
    let saltPpm: Double
    let notes: String?
}

struct ChemicalEntryExportable: Codable, Identifiable {
    let id: UUID
    let date: Date
    let type: String
    let amount: Double
    let unit: String
}

struct MaintenanceTaskExportable: Codable, Identifiable {
    let id: UUID
    let name: String
    let intervalDays: Int
    let lastCompletedDate: Date
    let isEnabled: Bool
    let notes: String?
}

// MARK: - Error Types

enum ExportError: LocalizedError {
    case encodingFailed
    case noData
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode data for export"
        case .noData:
            return "No data available to export"
        }
    }
}

// MARK: - Extension for Task Status

extension MaintenanceTask.TaskStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .overdue: return "Overdue"
        case .dueToday: return "Due Today"
        case .upcoming: return "Upcoming"
        }
    }
}
