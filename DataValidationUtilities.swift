import Foundation
import CoreData

/// Utilities for data validation and integrity checks
struct DataValidator {
    
    // MARK: - Validation Methods
    
    /// Validates pool log data before import
    static func validatePoolLog(_ log: PoolLogExportable) -> ValidationResult {
        var issues: [String] = []
        
        // Check pH range
        if log.ph < 0 || log.ph > 14 {
            issues.append("pH value \(log.ph) is out of valid range (0-14)")
        }
        
        // Check Free Chlorine
        if log.fc < 0 || log.fc > 20 {
            issues.append("Free Chlorine \(log.fc) is out of reasonable range (0-20 ppm)")
        }
        
        // Check Total Alkalinity
        if log.ta < 0 || log.ta > 500 {
            issues.append("Total Alkalinity \(log.ta) is out of reasonable range (0-500 ppm)")
        }
        
        // Check Calcium Hardness
        if log.ch < 0 || log.ch > 1000 {
            issues.append("Calcium Hardness \(log.ch) is out of reasonable range (0-1000 ppm)")
        }
        
        // Check CYA
        if log.cya < 0 || log.cya > 200 {
            issues.append("CYA \(log.cya) is out of reasonable range (0-200 ppm)")
        }
        
        // Check Salt
        if log.saltPpm < 0 || log.saltPpm > 10000 {
            issues.append("Salt \(log.saltPpm) is out of reasonable range (0-10000 ppm)")
        }
        
        // Check date is not in future
        if log.date > Date() {
            issues.append("Date is in the future")
        }
        
        return ValidationResult(isValid: issues.isEmpty, issues: issues)
    }
    
    /// Validates chemical entry data
    static func validateChemicalEntry(_ entry: ChemicalEntryExportable) -> ValidationResult {
        var issues: [String] = []
        
        // Check amount is positive
        if entry.amount < 0 {
            issues.append("Chemical amount cannot be negative")
        }
        
        // Check amount is reasonable
        if entry.amount > 1000 {
            issues.append("Chemical amount \(entry.amount) seems unusually high")
        }
        
        // Check date
        if entry.date > Date() {
            issues.append("Date is in the future")
        }
        
        // Check type is not empty
        if entry.type.isEmpty {
            issues.append("Chemical type cannot be empty")
        }
        
        return ValidationResult(isValid: issues.isEmpty, issues: issues)
    }
    
    /// Validates maintenance task data
    static func validateMaintenanceTask(_ task: MaintenanceTaskExportable) -> ValidationResult {
        var issues: [String] = []
        
        // Check interval is positive
        if task.intervalDays < 1 {
            issues.append("Interval must be at least 1 day")
        }
        
        // Check interval is reasonable (max 2 years)
        if task.intervalDays > 730 {
            issues.append("Interval \(task.intervalDays) days seems unusually long")
        }
        
        // Check name is not empty
        if task.name.isEmpty {
            issues.append("Task name cannot be empty")
        }
        
        return ValidationResult(isValid: issues.isEmpty, issues: issues)
    }
    
    /// Validates entire export data structure
    static func validateExportData(_ exportData: PoolDataExport) -> ValidationReport {
        var logIssues: [(PoolLogExportable, ValidationResult)] = []
        var chemicalIssues: [(ChemicalEntryExportable, ValidationResult)] = []
        var taskIssues: [(MaintenanceTaskExportable, ValidationResult)] = []
        
        // Validate pool logs
        for log in exportData.poolLogs {
            let result = validatePoolLog(log)
            if !result.isValid {
                logIssues.append((log, result))
            }
        }
        
        // Validate chemical entries
        for entry in exportData.chemicalEntries {
            let result = validateChemicalEntry(entry)
            if !result.isValid {
                chemicalIssues.append((entry, result))
            }
        }
        
        // Validate maintenance tasks
        for task in exportData.maintenanceTasks {
            let result = validateMaintenanceTask(task)
            if !result.isValid {
                taskIssues.append((task, result))
            }
        }
        
        return ValidationReport(
            logsWithIssues: logIssues.count,
            chemicalsWithIssues: chemicalIssues.count,
            tasksWithIssues: taskIssues.count,
            totalLogs: exportData.poolLogs.count,
            totalChemicals: exportData.chemicalEntries.count,
            totalTasks: exportData.maintenanceTasks.count,
            logDetails: logIssues,
            chemicalDetails: chemicalIssues,
            taskDetails: taskIssues
        )
    }
}

// MARK: - Data Cleanup Utilities

struct DataCleanup {
    
    /// Removes duplicate pool logs based on date and values
    static func removeDuplicateLogs(context: NSManagedObjectContext) async throws -> Int {
        let fetchRequest: NSFetchRequest<PoolLog> = PoolLog.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \PoolLog.date, ascending: true)]
        
        let logs = try context.fetch(fetchRequest)
        var removed = 0
        var seen: Set<String> = []
        
        for log in logs {
            let key = makeLogKey(log)
            
            if seen.contains(key) {
                context.delete(log)
                removed += 1
            } else {
                seen.insert(key)
            }
        }
        
        if removed > 0 {
            try context.save()
        }
        
        return removed
    }
    
    /// Removes old logs beyond a certain date
    static func removeOldLogs(
        context: NSManagedObjectContext,
        olderThan days: Int
    ) async throws -> Int {
        let cutoffDate = Calendar.current.date(
            byAdding: .day,
            value: -days,
            to: Date()
        )!
        
        let fetchRequest: NSFetchRequest<PoolLog> = PoolLog.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date < %@", cutoffDate as NSDate)
        
        let logs = try context.fetch(fetchRequest)
        
        for log in logs {
            context.delete(log)
        }
        
        if !logs.isEmpty {
            try context.save()
        }
        
        return logs.count
    }
    
    /// Fixes invalid data values
    static func fixInvalidValues(context: NSManagedObjectContext) async throws -> Int {
        let fetchRequest: NSFetchRequest<PoolLog> = PoolLog.fetchRequest()
        let logs = try context.fetch(fetchRequest)
        var fixed = 0
        
        for log in logs {
            var needsSave = false
            
            // Clamp pH to valid range
            if let phValue = log.phValue, (phValue < 0 || phValue > 14) {
                log.ph = NSNumber(value: phValue.clamped(to: 0...14))
                needsSave = true
                fixed += 1
            }
            
            // Clamp FC
            if let fcValue = log.fcValue, fcValue < 0 {
                log.fc = NSNumber(value: 0)
                needsSave = true
                fixed += 1
            }
            
            // Clamp TA
            if let taValue = log.taValue, taValue < 0 {
                log.ta = NSNumber(value: 0)
                needsSave = true
                fixed += 1
            }
            
            // Clamp CH
            if let chValue = log.chValue, chValue < 0 {
                log.ch = NSNumber(value: 0)
                needsSave = true
                fixed += 1
            }
            
            // Clamp CYA
            if let cyaValue = log.cyaValue, cyaValue < 0 {
                log.cya = NSNumber(value: 0)
                needsSave = true
                fixed += 1
            }
            
            // Clamp Salt
            if let saltValue = log.saltPpmValue, saltValue < 0 {
                log.saltPpm = NSNumber(value: 0)
                needsSave = true
                fixed += 1
            }
            
            if needsSave {
                // Fix is applied automatically
            }
        }
        
        if fixed > 0 {
            try context.save()
        }
        
        return fixed
    }
    
    private static func makeLogKey(_ log: PoolLog) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm"
        let dateString = log.date.map { dateFormatter.string(from: $0) } ?? "no-date"
        
        let phString = log.phValue.map { String($0) } ?? "nil"
        let fcString = log.fcValue.map { String($0) } ?? "nil"
        let taString = log.taValue.map { String($0) } ?? "nil"
        
        return "\(dateString)-\(phString)-\(fcString)-\(taString)"
    }
}

// MARK: - Data Statistics

struct DataStatistics {
    
    /// Generates comprehensive statistics about the data
    static func generateStatistics(context: NSManagedObjectContext) async throws -> Statistics {
        let poolLogs = try context.fetch(PoolLog.fetchRequest() as NSFetchRequest<PoolLog>)
        let chemicals = try context.fetch(ChemicalEntry.fetchRequest() as NSFetchRequest<ChemicalEntry>)
        let tasks = try context.fetch(MaintenanceTask.fetchRequest() as NSFetchRequest<MaintenanceTask>)
        
        // Pool log statistics
        let phValues = poolLogs.compactMap { $0.phValue }
        let fcValues = poolLogs.compactMap { $0.fcValue }
        
        let dates = poolLogs.compactMap { $0.date }
        let oldestDate = dates.min()
        let newestDate = dates.max()
        
        // Calculate date range in days
        var daysCovered = 0
        if let oldest = oldestDate, let newest = newestDate {
            daysCovered = Calendar.current.dateComponents([.day], from: oldest, to: newest).day ?? 0
        }
        
        // Chemical statistics
        var chemicalTotals: [String: Double] = [:]
        for chemical in chemicals {
            chemicalTotals[chemical.type ?? "unknown", default: 0] += chemical.amount
        }
        
        // Task statistics
        let enabledTasks = tasks.filter { $0.isEnabled }
        let overdueTasks = enabledTasks.filter { $0.status == .overdue }
        
        return Statistics(
            totalLogs: poolLogs.count,
            totalChemicals: chemicals.count,
            totalTasks: tasks.count,
            enabledTasks: enabledTasks.count,
            overdueTasks: overdueTasks.count,
            averagePH: phValues.average,
            averageFC: fcValues.average,
            oldestLogDate: oldestDate,
            newestLogDate: newestDate,
            daysCovered: daysCovered,
            chemicalTotals: chemicalTotals
        )
    }
}

// MARK: - Supporting Types

struct ValidationResult {
    let isValid: Bool
    let issues: [String]
}

struct ValidationReport {
    let logsWithIssues: Int
    let chemicalsWithIssues: Int
    let tasksWithIssues: Int
    let totalLogs: Int
    let totalChemicals: Int
    let totalTasks: Int
    let logDetails: [(PoolLogExportable, ValidationResult)]
    let chemicalDetails: [(ChemicalEntryExportable, ValidationResult)]
    let taskDetails: [(MaintenanceTaskExportable, ValidationResult)]
    
    var isValid: Bool {
        logsWithIssues == 0 && chemicalsWithIssues == 0 && tasksWithIssues == 0
    }
    
    var summary: String {
        """
        Validation Report
        
        Pool Logs: \(logsWithIssues) issues found out of \(totalLogs)
        Chemicals: \(chemicalsWithIssues) issues found out of \(totalChemicals)
        Tasks: \(tasksWithIssues) issues found out of \(totalTasks)
        
        Overall: \(isValid ? "✓ All data valid" : "⚠️ Issues found")
        """
    }
}

struct Statistics {
    let totalLogs: Int
    let totalChemicals: Int
    let totalTasks: Int
    let enabledTasks: Int
    let overdueTasks: Int
    let averagePH: Double
    let averageFC: Double
    let oldestLogDate: Date?
    let newestLogDate: Date?
    let daysCovered: Int
    let chemicalTotals: [String: Double]
    
    var summary: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        let oldestString = oldestLogDate.map { dateFormatter.string(from: $0) } ?? "N/A"
        let newestString = newestLogDate.map { dateFormatter.string(from: $0) } ?? "N/A"
        
        return """
        Data Statistics
        
        Pool Logs: \(totalLogs)
        Date Range: \(oldestString) to \(newestString)
        Days Covered: \(daysCovered)
        Average pH: \(String(format: "%.1f", averagePH))
        Average FC: \(String(format: "%.1f", averageFC)) ppm
        
        Chemical Entries: \(totalChemicals)
        \(chemicalSummary)
        
        Maintenance Tasks: \(totalTasks)
        Enabled: \(enabledTasks)
        Overdue: \(overdueTasks)
        """
    }
    
    private var chemicalSummary: String {
        chemicalTotals
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { "  \($0.key): \(String(format: "%.1f", $0.value)) oz" }
            .joined(separator: "\n")
    }
}

// MARK: - Extensions

extension Collection where Element == Double {
    var average: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Example Usage

/*
 // Validate before import
 let exportData = try JSONDecoder().decode(PoolDataExport.self, from: data)
 let report = DataValidator.validateExportData(exportData)
 
 if report.isValid {
     print("✓ All data is valid")
 } else {
     print(report.summary)
 }
 
 // Clean up data
 let duplicatesRemoved = try await DataCleanup.removeDuplicateLogs(context: context)
 print("Removed \(duplicatesRemoved) duplicate logs")
 
 // Generate statistics
 let stats = try await DataStatistics.generateStatistics(context: context)
 print(stats.summary)
 */
