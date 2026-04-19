import SwiftUI
internal import CoreData

struct AddEditTaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AddEditTaskViewModel
    
    init(task: MaintenanceTask? = nil) {
        _viewModel = State(wrappedValue: AddEditTaskViewModel(task: task))
    }
    
    var body: some View {
        Form {
            Section("Task Details") {
                TextField("Task Name", text: $viewModel.name)
                    .autocorrectionDisabled()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Repeat Interval")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 12) {
                        Stepper(value: $viewModel.intervalValue, in: 1...999) {
                            Text("\(viewModel.intervalValue)")
                                .font(.title2.monospacedDigit())
                                .frame(minWidth: 50, alignment: .leading)
                        }
                        
                        Picker("Unit", selection: $viewModel.intervalUnit) {
                            ForEach(MaintenanceTask.IntervalUnit.allCases, id: \.self) { unit in
                                Label(unit.displayName(count: viewModel.intervalValue), 
                                      systemImage: unit.icon)
                                    .tag(unit)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    Text(viewModel.intervalDescription)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
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
    task.intervalValue = 1
    task.intervalUnit = "week"
    task.intervalDays = 7  // Keep for backwards compatibility
    task.lastCompletedDate = Date()
    task.isEnabled = true
    task.notes = "Test weekly"
    
    try? context.save()
    
    return NavigationStack {
        AddEditTaskView(task: task)
            .environment(\.managedObjectContext, context)
    }
}
