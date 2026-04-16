import Foundation
import UserNotifications
internal import CoreData

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    let persistenceController: PersistenceController
    
    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
        super.init()
    }
    
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        if let taskIdString = userInfo["taskId"] as? String,
           let taskId = UUID(uuidString: taskIdString) {
            
            // Find and open the task
            let context = persistenceController.container.viewContext
            let fetchRequest: NSFetchRequest<MaintenanceTask> = MaintenanceTask.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", taskId as CVarArg)
            
            if let task = try? context.fetch(fetchRequest).first {
                print("User tapped notification for task: \(task.name)")
                // You can post a notification to navigate to this task in the UI
                NotificationCenter.default.post(
                    name: .didTapTaskNotification,
                    object: nil,
                    userInfo: ["taskId": taskId]
                )
            }
        }
        
        completionHandler()
    }
}

extension Notification.Name {
    static let didTapTaskNotification = Notification.Name("didTapTaskNotification")
}
