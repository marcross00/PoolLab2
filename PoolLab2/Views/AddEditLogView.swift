import SwiftUI
internal import CoreData

struct AddEditLogView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: AddEditLogViewModel?
    private var existingLog: PoolLog?

    init(log: PoolLog? = nil) {
        self.existingLog = log
    }

    private var isEditing: Bool { existingLog != nil }

    var body: some View {
        Group {
            if let viewModel {
                formContent(viewModel)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = AddEditLogViewModel(context: viewContext, log: existingLog)
            }
        }
        .navigationTitle(isEditing ? "Edit Log" : "New Log")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveAndDismiss() }
            }
        }
    }

    @ViewBuilder
    private func formContent(_ vm: AddEditLogViewModel) -> some View {
        Form {
            Section("Date") {
                DatePicker("Date", selection: Binding(
                    get: { vm.date },
                    set: { vm.date = $0 }
                ), displayedComponents: [.date, .hourAndMinute])
            }

            Section("Water Chemistry") {
                NumericTextField(label: "pH", text: Binding(
                    get: { vm.ph }, set: { vm.ph = $0 }
                ))
                NumericTextField(label: "FC (ppm)", text: Binding(
                    get: { vm.fc }, set: { vm.fc = $0 }
                ))
                NumericTextField(label: "TA (ppm)", text: Binding(
                    get: { vm.ta }, set: { vm.ta = $0 }
                ))
                NumericTextField(label: "CH (ppm)", text: Binding(
                    get: { vm.ch }, set: { vm.ch = $0 }
                ))
                NumericTextField(label: "CYA (ppm)", text: Binding(
                    get: { vm.cya }, set: { vm.cya = $0 }
                ))
                NumericTextField(label: "Salt (ppm)", text: Binding(
                    get: { vm.saltPpm }, set: { vm.saltPpm = $0 }
                ))
            }

            Section("Chemicals Added") {
                ForEach(Array(vm.chemicalRows.enumerated()), id: \.element.id) { index, _ in
                    ChemicalRowView(row: Binding(
                        get: { vm.chemicalRows[index] },
                        set: { vm.chemicalRows[index] = $0 }
                    ))
                }
                .onDelete { vm.removeChemicalRows(at: $0) }

                Button {
                    vm.addChemicalRow()
                } label: {
                    Label("Add Chemical", systemImage: "plus.circle.fill")
                }
            }

            Section("Notes") {
                TextEditor(text: Binding(
                    get: { vm.notes }, set: { vm.notes = $0 }
                ))
                .frame(minHeight: 80)
            }
        }
    }

    private func saveAndDismiss() {
        guard let viewModel, viewModel.save() else { return }
        dismiss()
    }
}

private struct ChemicalRowView: View {
    @Binding var row: ChemicalRow

    var body: some View {
        VStack(spacing: 8) {
            Picker("Type", selection: $row.type) {
                ForEach(AddEditLogViewModel.chemicalTypes, id: \.self) { type in
                    Text(type.capitalized).tag(type)
                }
            }

            HStack {
                TextField("Amount", text: $row.amount)
                    .keyboardType(.decimalPad)
                    .frame(maxWidth: .infinity)

                Picker("Unit", selection: $row.unit) {
                    ForEach(AddEditLogViewModel.unitOptions, id: \.self) { unit in
                        Text(unit).tag(unit)
                    }
                }
                .labelsHidden()
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        AddEditLogView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
