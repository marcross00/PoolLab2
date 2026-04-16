import Foundation
import Combine
internal import CoreData

@MainActor
class AddEditTaskViewModel: ObservableObject {
    @Published var name: String
    @Published var intervalDays: Int
    @Published var lastCompletedDate: Date
    @Published var isEnabled: Bool
    @Published var notes: String
    
    private let task: MaintenanceTask?
    private let reminderManager = ReminderManager.shared
    
    var isEditing: Bool {
        task != nil
    }
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && intervalDays > 0
    }
    
    var nextDueDate: Date? {
        Calendar.current.date(byAdding: .day, value: intervalDays, to: lastCompletedDate)
    }
    
    init(task: MaintenanceTask? = nil) {
        self.task = task
        self.name = task?.name ?? ""
        self.intervalDays = Int(task?.intervalDays ?? 7)
        self.lastCompletedDate = task?.lastCompletedDate ?? Date()
        self.isEnabled = task?.isEnabled ?? true
        self.notes = task?.notes ?? ""
    }
    
    func save(context: NSManagedObjectContext) async {
        let taskToSave: MaintenanceTask
        
        if let existingTask = task {
            taskToSave = existingTask
        } else {
            taskToSave = MaintenanceTask(context: context)
            taskToSave.id = UUID()
        }
        
        taskToSave.name = name.trimmingCharacters(in: .whitespaces)
        taskToSave.intervalDays = Int16(intervalDays)
        taskToSave.lastCompletedDate = lastCompletedDate
        taskToSave.isEnabled = isEnabled
        taskToSave.notes = notes.isEmpty ? nil : notes
        
        do {
            try context.save()
            await reminderManager.scheduleNotification(for: taskToSave)
        } catch {
            print("Error saving task: \(error)")
        }
    }
    
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
