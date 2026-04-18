import SwiftUI
internal import CoreData

struct LogDetailView: View {
    let log: PoolLog
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        List {
            // Date Section
            Section {
                LabeledContent("Date") {
                    Text(log.wrappedDate, format: .dateTime.month().day().year())
                }
                LabeledContent("Time") {
                    Text(log.wrappedDate, format: .dateTime.hour().minute())
                }
            }
            
            // Water Chemistry Section
            Section("Water Chemistry") {
                ChemistryRow(
                    label: "pH",
                    value: log.phValue,
                    format: "%.1f",
                    icon: "drop.fill",
                    color: .blue,
                    idealRange: "7.2 - 7.6"
                )
                
                ChemistryRow(
                    label: "Free Chlorine",
                    value: log.fcValue,
                    format: "%.1f",
                    unit: "ppm",
                    icon: "bubbles.and.sparkles",
                    color: .green,
                    idealRange: "2 - 4 ppm"
                )
                
                ChemistryRow(
                    label: "Total Alkalinity",
                    value: log.taValue,
                    format: "%.0f",
                    unit: "ppm",
                    icon: "chart.bar.fill",
                    color: .orange,
                    idealRange: "80 - 120 ppm"
                )
                
                ChemistryRow(
                    label: "Calcium Hardness",
                    value: log.chValue,
                    format: "%.0f",
                    unit: "ppm",
                    icon: "cube.fill",
                    color: .purple,
                    idealRange: "200 - 400 ppm"
                )
                
                ChemistryRow(
                    label: "CYA",
                    value: log.cyaValue,
                    format: "%.0f",
                    unit: "ppm",
                    icon: "sun.max.fill",
                    color: .yellow,
                    idealRange: "30 - 50 ppm"
                )
                
                ChemistryRow(
                    label: "Salt",
                    value: log.saltPpmValue,
                    format: "%.0f",
                    unit: "ppm",
                    icon: "sparkles",
                    color: .cyan,
                    idealRange: "2700 - 3400 ppm"
                )
            }
            
            // Chemicals Added Section
            if !log.chemicalsArray.isEmpty {
                Section("Chemicals Added") {
                    ForEach(log.chemicalsArray) { chemical in
                        HStack {
                            Image(systemName: "flask.fill")
                                .foregroundStyle(.secondary)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(chemical.wrappedType.capitalized)
                                    .font(.subheadline)
                                Text("\(chemical.amount, specifier: "%.1f") \(chemical.wrappedUnit)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            
            // Notes Section
            if let notes = log.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                        .font(.body)
                }
            }
            
            // Delete Section
            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    HStack {
                        Spacer()
                        Label("Delete Log", systemImage: "trash")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Log Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingEditSheet = true
                } label: {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                AddEditLogView(log: log)
            }
        }
        .alert("Delete This Log?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteLog()
            }
        } message: {
            Text("This will permanently delete this log entry. This action cannot be undone.")
        }
    }
    
    private func deleteLog() {
        viewContext.delete(log)
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error deleting log: \(error.localizedDescription)")
        }
    }
}

// MARK: - Chemistry Row Component

private struct ChemistryRow: View {
    let label: String
    let value: Double?
    let format: String
    var unit: String = ""
    let icon: String
    let color: Color
    let idealRange: String
    
    var isInIdealRange: Bool {
        guard let value = value else { return false }
        
        // Parse ideal range and check if value is within it
        // This is a simplified check - you could make it more sophisticated
        switch label {
        case "pH":
            return (7.2...7.6).contains(value)
        case "Free Chlorine":
            return (2.0...4.0).contains(value)
        case "Total Alkalinity":
            return (80...120).contains(value)
        case "Calcium Hardness":
            return (200...400).contains(value)
        case "CYA":
            return (30...50).contains(value)
        case "Salt":
            return (2700...3400).contains(value)
        default:
            return false
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                
                Text("Ideal: \(idealRange)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                if let value = value {
                    Text(String(format: format, value))
                        .font(.body)
                        .fontWeight(.medium)
                    
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Image(systemName: isInIdealRange ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(isInIdealRange ? .green : .orange)
                        .font(.caption)
                } else {
                    Text("--")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        let context = PersistenceController.preview.container.viewContext
        let log = PoolLog(context: context)
        log.id = UUID()
        log.date = Date()
        log.ph = NSNumber(value: 7.4)
        log.fc = NSNumber(value: 3.2)
        log.ta = NSNumber(value: 95)
        log.ch = NSNumber(value: 250)
        log.cya = NSNumber(value: 35)
        log.saltPpm = NSNumber(value: 3200)
        log.notes = "Pool looking great! Added some chlorine."
        
        let chemical = ChemicalEntry(context: context)
        chemical.id = UUID()
        chemical.date = Date()
        chemical.type = "chlorine"
        chemical.amount = 2.5
        chemical.unit = "oz"
        chemical.poolLog = log
        
        return LogDetailView(log: log)
            .environment(\.managedObjectContext, context)
    }
}
