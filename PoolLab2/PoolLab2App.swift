import SwiftUI
internal import CoreData
import UserNotifications

@main
struct PoolLab2App: App {
    let persistenceController = PersistenceController.shared
    @ObservedObject private var reminderManager = ReminderManager.shared
    private let notificationDelegate: NotificationDelegate
    
    init() {
        // Set up notification delegate - must be stored as a property
        let delegate = NotificationDelegate(persistenceController: PersistenceController.shared)
        self.notificationDelegate = delegate
        UNUserNotificationCenter.current().delegate = delegate
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .task {
                    await setupNotifications()
                }
        }
    }
    
    private func setupNotifications() async {
        // Request authorization if needed
        if reminderManager.authorizationStatus == .notDetermined {
            _ = await reminderManager.requestAuthorization()
        }
        
        // Reschedule all enabled tasks
        await reminderManager.rescheduleAllNotifications(context: persistenceController.container.viewContext)
    }
}
