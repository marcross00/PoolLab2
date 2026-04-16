import Foundation
internal import CoreData
import UserNotifications

// MARK: - Example: Creating a Maintenance Task

/*
 
 Example 1: Creating a new task programmatically
 
 */

func createMaintenanceTask(context: NSManagedObjectContext) async {
    let task = MaintenanceTask(context: context)
    task.id = UUID()
    task.name = "Check pH"
    task.intervalDays = 3
    task.lastCompletedDate = Date()
    task.isEnabled = true
    task.notes = "Test pH levels and adjust as needed"
    
    do {
        try context.save()
        
        // Schedule notification
        await ReminderManager.shared.scheduleNotification(for: task)
        
        print("Task created and notification scheduled")
    } catch {
        print("Error creating task: \(error)")
    }
}

/*
 
 Example 2: Marking a task complete
 
 */

func completeTask(_ task: MaintenanceTask, context: NSManagedObjectContext) async {
    await ReminderManager.shared.markTaskComplete(task, context: context)
    print("Task completed. Next due date: \(task.nextDueDate)")
}

/*
 
 Example 3: Fetching overdue tasks
 
 */

func fetchOverdueTasks(context: NSManagedObjectContext) -> [MaintenanceTask] {
    let fetchRequest: NSFetchRequest<MaintenanceTask> = MaintenanceTask.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "isEnabled == YES")
    
    do {
        let tasks = try context.fetch(fetchRequest)
        return tasks.filter { $0.status == .overdue }
    } catch {
        print("Error fetching tasks: \(error)")
        return []
    }
}

/*
 
 Example 4: Common task templates
 
 */

func createCommonTasks(context: NSManagedObjectContext) async {
    let tasks = [
        ("Check pH", 3),
        ("Check Free Chlorine", 2),
        ("Check Total Alkalinity", 14),
        ("Check Calcium Hardness", 14),
        ("Check CYA", 30),
        ("Check Salt Level", 21),
        ("Clean Skimmer Basket", 7),
        ("Clean Pool Filter", 30),
        ("Backwash Filter", 21),
        ("Vacuum Pool", 7),
        ("Test for Metals", 90)
    ]
    
    for (name, interval) in tasks {
        let task = MaintenanceTask(context: context)
        task.id = UUID()
        task.name = name
        task.intervalDays = Int16(interval)
        task.lastCompletedDate = Date()
        task.isEnabled = false // User can enable as needed
    }
    
    do {
        try context.save()
        print("Created \(tasks.count) common tasks")
    } catch {
        print("Error creating tasks: \(error)")
    }
}

/*
 
 Example 5: Notification scheduling details
 
 The ReminderManager automatically:
 - Schedules notifications at 9:00 AM on the due date
 - Cancels old notifications when rescheduling
 - Handles authorization status
 - Reschedules when tasks are updated or completed
 
 Notification trigger example:
 - If task interval is 3 days
 - Last completed: April 10, 2026
 - Next due date: April 13, 2026
 - Notification fires: April 13, 2026 at 9:00 AM
 
 */

/*
 
 Example 6: Debugging notifications
 
 */

func debugNotifications() async {
    let pending = await ReminderManager.shared.getPendingNotifications()
    
    print("Pending notifications: \(pending.count)")
    for notification in pending {
        print("- \(notification.content.title)")
        if let trigger = notification.trigger as? UNCalendarNotificationTrigger {
            print("  Scheduled for: \(trigger.nextTriggerDate() ?? Date())")
        }
    }
}
