import Foundation
import Combine
import UserNotifications
import CoreData

class ReminderManager: ObservableObject {
    @MainActor static let shared = ReminderManager()
    
    @Published @MainActor var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let notificationTime = DateComponents(hour: 9, minute: 0) // 9:00 AM
    
    private init() {
        Task { @MainActor in
            await checkAuthorizationStatus()
        }
    }
    
    // MARK: - Authorization
    
    @MainActor
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            await checkAuthorizationStatus()
            return granted
        } catch {
            print("Error requesting notification authorization: \(error)")
            return false
        }
    }
    
    @MainActor
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }
    
    // MARK: - Notification Scheduling
    
    func scheduleNotification(for task: MaintenanceTask) async {
        guard task.isEnabled else {
            await cancelNotification(for: task)
            return
        }
        
        // Cancel existing notification
        await cancelNotification(for: task)
        
        // Calculate next due date
        let dueDate = task.nextDueDate
        
        // Create date components for trigger
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
        dateComponents.hour = notificationTime.hour
        dateComponents.minute = notificationTime.minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = task.name
        
        if task.status == .overdue {
            content.body = "Pool maintenance task is overdue"
        } else {
            content.body = "Pool maintenance task is due today"
        }
        
        content.sound = .default
        content.categoryIdentifier = "TASK_REMINDER"
        content.userInfo = ["taskId": task.id.uuidString]
        
        // Create request
        let request = UNNotificationRequest(
            identifier: task.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            print("Scheduled notification for \(task.name) on \(dueDate)")
        } catch {
            print("Error scheduling notification: \(error)")
        }
    }
    
    func cancelNotification(for task: MaintenanceTask) async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
        print("Cancelled notification for \(task.name)")
    }
    
    func rescheduleAllNotifications(context: NSManagedObjectContext) async {
        let fetchRequest: NSFetchRequest<MaintenanceTask> = MaintenanceTask.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isEnabled == YES")
        
        do {
            let tasks = try context.fetch(fetchRequest)
            for task in tasks {
                await scheduleNotification(for: task)
            }
        } catch {
            print("Error fetching tasks for rescheduling: \(error)")
        }
    }
    
    func cancelAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    // MARK: - Task Completion
    
    func markTaskComplete(_ task: MaintenanceTask, context: NSManagedObjectContext) async {
        task.lastCompletedDate = Date()
        
        do {
            try context.save()
            await scheduleNotification(for: task)
        } catch {
            print("Error saving task completion: \(error)")
        }
    }
    
    // MARK: - Debug
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }
}

extension MaintenanceTask {
    static func fetchRequest() -> NSFetchRequest<MaintenanceTask> {
        NSFetchRequest<MaintenanceTask>(entityName: "MaintenanceTask")
    }
}
