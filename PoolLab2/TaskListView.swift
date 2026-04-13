import SwiftUI
import CoreData

struct TaskListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var reminderManager = ReminderManager.shared
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \MaintenanceTask.lastCompletedDate, ascending: false)
        ],
        animation: .default
    )
    private var tasks: FetchedResults<MaintenanceTask>
    
    @State private var showingAddTask = false
    @State private var showingPermissionAlert = false
    
    var body: some View {
        NavigationStack {
            Group {
                if tasks.isEmpty {
                    ContentUnavailableView(
                        "No Maintenance Tasks",
                        systemImage: "calendar.badge.clock",
                        description: Text("Tap + to add your first maintenance reminder.")
                    )
                } else {
                    List {
                        ForEach(sortedTasks) { task in
                            NavigationLink {
                                AddEditTaskView(task: task)
                            } label: {
                                TaskRowView(task: task)
                            }
                        }
                        .onDelete(perform: deleteTasks)
                    }
                }
            }
            .navigationTitle("Maintenance Tasks")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddTask = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                NavigationStack {
                    AddEditTaskView()
                }
            }
            .alert("Notifications Disabled", isPresented: $showingPermissionAlert) {
                Button("Settings", role: .cancel) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please enable notifications in Settings to receive maintenance reminders.")
            }
            .task {
                await checkNotificationPermissions()
            }
        }
    }
    
    private var sortedTasks: [MaintenanceTask] {
        tasks.sorted { task1, task2 in
            // Sort by status (overdue first, then due today, then upcoming)
            let status1Priority = statusPriority(task1.status)
            let status2Priority = statusPriority(task2.status)
            
            if status1Priority != status2Priority {
                return status1Priority < status2Priority
            }
            
            // If same status, sort by next due date
            return task1.nextDueDate < task2.nextDueDate
        }
    }
    
    private func statusPriority(_ status: MaintenanceTask.TaskStatus) -> Int {
        switch status {
        case .overdue: return 0
        case .dueToday: return 1
        case .upcoming: return 2
        }
    }
    
    private func checkNotificationPermissions() async {
        await reminderManager.checkAuthorizationStatus()
        
        if reminderManager.authorizationStatus == .notDetermined {
            _ = await reminderManager.requestAuthorization()
        }
    }
    
    private func deleteTasks(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let task = sortedTasks[index]
                await reminderManager.cancelNotification(for: task)
                viewContext.delete(task)
            }
            
            try? viewContext.save()
        }
    }
}

private struct TaskRowView: View {
    @ObservedObject var task: MaintenanceTask
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var reminderManager = ReminderManager.shared
    
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()
    
    var body: some View {
        HStack(spacing: 12) {
            // Status Icon
            Image(systemName: task.status.icon)
                .foregroundStyle(statusColor)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.headline)
                
                HStack(spacing: 16) {
                    Label(statusText, systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Label("Every \(task.intervalDays) days", systemImage: "arrow.clockwise")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                Toggle("", isOn: Binding(
                    get: { task.isEnabled },
                    set: { newValue in
                        task.isEnabled = newValue
                        try? viewContext.save()
                        Task {
                            await reminderManager.scheduleNotification(for: task)
                        }
                    }
                ))
                .labelsHidden()
                
                Button {
                    Task {
                        await reminderManager.markTaskComplete(task, context: viewContext)
                    }
                } label: {
                    Text("Complete")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var statusColor: Color {
        switch task.status {
        case .overdue: return .red
        case .dueToday: return .orange
        case .upcoming: return .green
        }
    }
    
    private var statusText: String {
        let days = task.daysUntilDue
        
        switch task.status {
        case .overdue:
            return "\(abs(days)) day\(abs(days) == 1 ? "" : "s") overdue"
        case .dueToday:
            return "Due today"
        case .upcoming:
            return "Due in \(days) day\(days == 1 ? "" : "s")"
        }
    }
}

#Preview {
    let controller = PersistenceController.preview
    let context = controller.container.viewContext
    
    // Add sample tasks
    let task1 = MaintenanceTask(context: context)
    task1.id = UUID()
    task1.name = "Check pH"
    task1.intervalDays = 3
    task1.lastCompletedDate = Calendar.current.date(byAdding: .day, value: -4, to: Date())!
    task1.isEnabled = true
    
    let task2 = MaintenanceTask(context: context)
    task2.id = UUID()
    task2.name = "Check Total Alkalinity"
    task2.intervalDays = 14
    task2.lastCompletedDate = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
    task2.isEnabled = true
    
    let task3 = MaintenanceTask(context: context)
    task3.id = UUID()
    task3.name = "Check CYA"
    task3.intervalDays = 30
    task3.lastCompletedDate = Date()
    task3.isEnabled = false
    
    try? context.save()
    
    return TaskListView()
        .environment(\.managedObjectContext, context)
}
