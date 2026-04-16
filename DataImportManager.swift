import Foundation
import CoreData

/// Manages import of pool data from various formats
@MainActor
class DataImportManager: ObservableObject {
    private let context: NSManagedObjectContext
    
    @Published var importProgress: Double = 0.0
    @Published var importStatus: String = ""
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - JSON Import
    
    /// Imports complete pool data from JSON
    func importFromJSON(data: Data, mergeStrategy: MergeStrategy = .skipDuplicates) throws -> ImportResult {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let exportData = try decoder.decode(PoolDataExport.self, from: data)
        
        var result = ImportResult()
        
        // Import pool logs
        importStatus = "Importing pool logs..."
        for (index, logData) in exportData.poolLogs.enumerated() {
            if try importPoolLog(logData, mergeStrategy: mergeStrategy) {
                result.poolLogsImported += 1
            } else {
                result.poolLogsSkipped += 1
            }
            importProgress = Double(index + 1) / Double(exportData.poolLogs.count) * 0.4
        }
        
        // Import chemical entries
        importStatus = "Importing chemical entries..."
        for (index, entryData) in exportData.chemicalEntries.enumerated() {
            if try importChemicalEntry(entryData, mergeStrategy: mergeStrategy) {
                result.chemicalEntriesImported += 1
            } else {
                result.chemicalEntriesSkipped += 1
            }
            importProgress = 0.4 + (Double(index + 1) / Double(exportData.chemicalEntries.count) * 0.3)
        }
        
        // Import maintenance tasks
        importStatus = "Importing maintenance tasks..."
        for (index, taskData) in exportData.maintenanceTasks.enumerated() {
            if try importMaintenanceTask(taskData, mergeStrategy: mergeStrategy) {
                result.maintenanceTasksImported += 1
            } else {
                result.maintenanceTasksSkipped += 1
            }
            importProgress = 0.7 + (Double(index + 1) / Double(exportData.maintenanceTasks.count) * 0.3)
        }
        
        // Save context
        importStatus = "Saving changes..."
        try context.save()
        
        importProgress = 1.0
        importStatus = "Import complete"
        
        return result
    }
    
    /// Imports pool logs only from JSON
    func importPoolLogsFromJSON(data: Data, mergeStrategy: MergeStrategy = .skipDuplicates) throws -> ImportResult {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let logs = try decoder.decode([PoolLogExportable].self, from: data)
        
        var result = ImportResult()
        
        for (index, logData) in logs.enumerated() {
            if try importPoolLog(logData, mergeStrategy: mergeStrategy) {
                result.poolLogsImported += 1
            } else {
                result.poolLogsSkipped += 1
            }
            importProgress = Double(index + 1) / Double(logs.count)
        }
        
        try context.save()
        
        return result
    }
    
    // MARK: - CSV Import
    
    /// Imports pool logs from CSV format
    func importPoolLogsFromCSV(data: Data) throws -> ImportResult {
        guard let csvString = String(data: data, encoding: .utf8) else {
            throw ImportError.invalidFormat
        }
        
        let lines = csvString.components(separatedBy: .newlines)
        guard lines.count > 1 else {
            throw ImportError.noData
        }
        
        // Skip header row
        let dataLines = Array(lines.dropFirst()).filter { !$0.isEmpty }
        
        var result = ImportResult()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        for (index, line) in dataLines.enumerated() {
            let components = parseCSVLine(line)
            
            guard components.count >= 7 else { continue }
            
            // Parse CSV components
            guard let date = dateFormatter.date(from: components[0]),
                  let ph = Double(components[1]),
                  let fc = Double(components[2]),
                  let ta = Double(components[3]),
                  let ch = Double(components[4]),
                  let cya = Double(components[5]),
                  let saltPpm = Double(components[6]) else {
                continue
            }
            
            let notes = components.count > 7 ? components[7].trimmingCharacters(in: CharacterSet(charactersIn: "\"")) : nil
            
            let logData = PoolLogExportable(
                id: UUID(),
                date: date,
                ph: ph,
                fc: fc,
                ta: ta,
                ch: ch,
                cya: cya,
                saltPpm: saltPpm,
                notes: notes
            )
            
            if try importPoolLog(logData, mergeStrategy: .skipDuplicates) {
                result.poolLogsImported += 1
            } else {
                result.poolLogsSkipped += 1
            }
            
            importProgress = Double(index + 1) / Double(dataLines.count)
        }
        
        try context.save()
        
        return result
    }
    
    // MARK: - Individual Import Methods
    
    private func importPoolLog(_ logData: PoolLogExportable, mergeStrategy: MergeStrategy) throws -> Bool {
        // Check for existing log with same ID
        let fetchRequest: NSFetchRequest<PoolLog> = PoolLog.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", logData.id as CVarArg)
        
        let existing = try context.fetch(fetchRequest).first
        
        if let existing = existing {
            switch mergeStrategy {
            case .skipDuplicates:
                return false
            case .overwrite:
                updatePoolLog(existing, with: logData)
                return true
            case .keepBoth:
                createPoolLog(from: logData, newID: UUID())
                return true
            }
        } else {
            createPoolLog(from: logData, newID: logData.id)
            return true
        }
    }
    
    private func importChemicalEntry(_ entryData: ChemicalEntryExportable, mergeStrategy: MergeStrategy) throws -> Bool {
        let fetchRequest: NSFetchRequest<ChemicalEntry> = ChemicalEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", entryData.id as CVarArg)
        
        let existing = try context.fetch(fetchRequest).first
        
        if let existing = existing {
            switch mergeStrategy {
            case .skipDuplicates:
                return false
            case .overwrite:
                updateChemicalEntry(existing, with: entryData)
                return true
            case .keepBoth:
                createChemicalEntry(from: entryData, newID: UUID())
                return true
            }
        } else {
            createChemicalEntry(from: entryData, newID: entryData.id)
            return true
        }
    }
    
    private func importMaintenanceTask(_ taskData: MaintenanceTaskExportable, mergeStrategy: MergeStrategy) throws -> Bool {
        let fetchRequest: NSFetchRequest<MaintenanceTask> = MaintenanceTask.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", taskData.id as CVarArg)
        
        let existing = try context.fetch(fetchRequest).first
        
        if let existing = existing {
            switch mergeStrategy {
            case .skipDuplicates:
                return false
            case .overwrite:
                updateMaintenanceTask(existing, with: taskData)
                return true
            case .keepBoth:
                createMaintenanceTask(from: taskData, newID: UUID())
                return true
            }
        } else {
            createMaintenanceTask(from: taskData, newID: taskData.id)
            return true
        }
    }
    
    // MARK: - Create Methods
    
    private func createPoolLog(from data: PoolLogExportable, newID: UUID) {
        let log = PoolLog(context: context)
        log.id = newID
        log.date = data.date
        log.ph = data.ph
        log.fc = data.fc
        log.ta = data.ta
        log.ch = data.ch
        log.cya = data.cya
        log.saltPpm = data.saltPpm
        log.notes = data.notes
    }
    
    private func createChemicalEntry(from data: ChemicalEntryExportable, newID: UUID) {
        let entry = ChemicalEntry(context: context)
        entry.id = newID
        entry.date = data.date
        entry.type = data.type
        entry.amount = data.amount
        entry.unit = data.unit
    }
    
    private func createMaintenanceTask(from data: MaintenanceTaskExportable, newID: UUID) {
        let task = MaintenanceTask(context: context)
        task.id = newID
        task.name = data.name
        task.intervalDays = Int16(data.intervalDays)
        task.lastCompletedDate = data.lastCompletedDate
        task.isEnabled = data.isEnabled
        task.notes = data.notes
    }
    
    // MARK: - Update Methods
    
    private func updatePoolLog(_ log: PoolLog, with data: PoolLogExportable) {
        log.date = data.date
        log.ph = data.ph
        log.fc = data.fc
        log.ta = data.ta
        log.ch = data.ch
        log.cya = data.cya
        log.saltPpm = data.saltPpm
        log.notes = data.notes
    }
    
    private func updateChemicalEntry(_ entry: ChemicalEntry, with data: ChemicalEntryExportable) {
        entry.date = data.date
        entry.type = data.type
        entry.amount = data.amount
        entry.unit = data.unit
    }
    
    private func updateMaintenanceTask(_ task: MaintenanceTask, with data: MaintenanceTaskExportable) {
        task.name = data.name
        task.intervalDays = Int16(data.intervalDays)
        task.lastCompletedDate = data.lastCompletedDate
        task.isEnabled = data.isEnabled
        task.notes = data.notes
    }
    
    // MARK: - Helpers
    
    private func parseCSVLine(_ line: String) -> [String] {
        var components: [String] = []
        var current = ""
        var inQuotes = false
        
        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                components.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        
        components.append(current)
        return components
    }
}

// MARK: - Supporting Types

enum MergeStrategy {
    case skipDuplicates
    case overwrite
    case keepBoth
}

struct ImportResult {
    var poolLogsImported: Int = 0
    var poolLogsSkipped: Int = 0
    var chemicalEntriesImported: Int = 0
    var chemicalEntriesSkipped: Int = 0
    var maintenanceTasksImported: Int = 0
    var maintenanceTasksSkipped: Int = 0
    
    var totalImported: Int {
        poolLogsImported + chemicalEntriesImported + maintenanceTasksImported
    }
    
    var totalSkipped: Int {
        poolLogsSkipped + chemicalEntriesSkipped + maintenanceTasksSkipped
    }
    
    var summary: String {
        """
        Import Complete
        
        Pool Logs: \(poolLogsImported) imported, \(poolLogsSkipped) skipped
        Chemical Entries: \(chemicalEntriesImported) imported, \(chemicalEntriesSkipped) skipped
        Maintenance Tasks: \(maintenanceTasksImported) imported, \(maintenanceTasksSkipped) skipped
        
        Total: \(totalImported) items imported
        """
    }
}

enum ImportError: LocalizedError {
    case invalidFormat
    case noData
    case corruptedData
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "The file format is invalid or corrupted"
        case .noData:
            return "No data found in the file"
        case .corruptedData:
            return "The data in the file is corrupted"
        }
    }
}
