import Foundation
import SwiftUI
internal import CoreData

@Observable
final class AddEditTaskViewModel {
    var name: String = ""
    var intervalValue: Int = 1
    var intervalUnit: MaintenanceTask.IntervalUnit = .day
    var lastCompletedDate: Date = Date()
    var isEnabled: Bool = true
    var notes: String = ""
    
    private var task: MaintenanceTask?
    private let reminderManager = ReminderManager.shared
    
    var isEditing: Bool {
        task != nil
    }
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var intervalDescription: String {
        let unit = intervalUnit.displayName(count: intervalValue)
        return intervalValue == 1 ? "Every \(unit)" : "Every \(intervalValue) \(unit)"
    }
    
    var nextDueDate: Date? {
        let calendar = Calendar.current
        
        switch intervalUnit {
        case .day:
            return calendar.date(byAdding: .day, value: intervalValue, to: lastCompletedDate)
        case .week:
            return calendar.date(byAdding: .weekOfYear, value: intervalValue, to: lastCompletedDate)
        case .month:
            return calendar.date(byAdding: .month, value: intervalValue, to: lastCompletedDate)
        }
    }
    
    init(task: MaintenanceTask? = nil) {
        self.task = task
        
        if let task = task {
            self.name = task.name
            self.intervalValue = Int(task.intervalValue)
            self.intervalUnit = task.intervalType
            self.lastCompletedDate = task.lastCompletedDate
            self.isEnabled = task.isEnabled
            self.notes = task.notes ?? ""
        }
    }
    
    @MainActor
    func save(context: NSManagedObjectContext) async {
        let taskToSave: MaintenanceTask
        
        if let existingTask = task {
            taskToSave = existingTask
        } else {
            taskToSave = MaintenanceTask(context: context)
            taskToSave.id = UUID()
        }
        
        taskToSave.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        taskToSave.intervalValue = Int16(intervalValue)
        taskToSave.intervalUnit = intervalUnit.rawValue
        taskToSave.lastCompletedDate = lastCompletedDate
        taskToSave.isEnabled = isEnabled
        taskToSave.notes = notes.isEmpty ? nil : notes
        
        // Update intervalDays for backwards compatibility
        let calendar = Calendar.current
        if let nextDue = nextDueDate {
            let days = calendar.dateComponents([.day], from: lastCompletedDate, to: nextDue).day ?? 0
            taskToSave.intervalDays = Int16(days)
        }
        
        do {
            try context.save()
            await reminderManager.scheduleNotification(for: taskToSave)
        } catch {
            print("Error saving task: \(error)")
        }
    }
    
    @MainActor
    func delete(context: NSManagedObjectContext) async {
        guard let task = task else { return }
        
        await reminderManager.cancelNotification(for: task)
        context.delete(task)
        
        do {
            try context.save()
        } catch {
            print("Error deleting task: \(error)")
        }
    }
}
