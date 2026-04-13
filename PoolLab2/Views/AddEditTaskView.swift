import SwiftUI
import CoreData

struct AddEditTaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AddEditTaskViewModel
    
    init(task: MaintenanceTask? = nil) {
        _viewModel = StateObject(wrappedValue: AddEditTaskViewModel(task: task))
    }
    
    var body: some View {
        Form {
            Section("Task Details") {
                TextField("Task Name", text: $viewModel.name)
                    .autocorrectionDisabled()
                
                Stepper(value: $viewModel.intervalDays, in: 1...365) {
                    HStack {
                        Text("Interval")
                        Spacer()
                        Text("\(viewModel.intervalDays) day\(viewModel.intervalDays == 1 ? "" : "s")")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section("Scheduling") {
                DatePicker(
                    "Last Completed",
                    selection: $viewModel.lastCompletedDate,
                    displayedComponents: .date
                )
                
                if let nextDue = viewModel.nextDueDate {
                    LabeledContent("Next Due") {
                        Text(nextDue, style: .date)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Toggle("Enable Reminder", isOn: $viewModel.isEnabled)
            }
            
            Section("Notes") {
                TextField("Optional notes", text: $viewModel.notes, axis: .vertical)
                    .lineLimit(3...6)
            }
            
            if viewModel.isEditing {
                Section {
                    Button("Delete Task", role: .destructive) {
                        deleteTask()
                    }
                }
            }
        }
        .navigationTitle(viewModel.isEditing ? "Edit Task" : "New Task")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveTask()
                }
                .disabled(!viewModel.isValid)
            }
        }
    }
    
    private func saveTask() {
        Task {
            await viewModel.save(context: viewContext)
            dismiss()
        }
    }
    
    private func deleteTask() {
        Task {
            await viewModel.delete(context: viewContext)
            dismiss()
        }
    }
}

#Preview("New Task") {
    NavigationStack {
        AddEditTaskView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

#Preview("Edit Task") {
    let controller = PersistenceController.preview
    let context = controller.container.viewContext
    
    let task = MaintenanceTask(context: context)
    task.id = UUID()
    task.name = "Check pH"
    task.intervalDays = 3
    task.lastCompletedDate = Date()
    task.isEnabled = true
    task.notes = "Test weekly"
    
    try? context.save()
    
    return NavigationStack {
        AddEditTaskView(task: task)
            .environment(\.managedObjectContext, context)
    }
}
