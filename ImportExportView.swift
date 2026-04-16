import SwiftUI
import UniformTypeIdentifiers

/// Main view for importing and exporting pool data
struct ImportExportView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var exportManager: DataExportManager
    @StateObject private var importManager: DataImportManager
    
    @State private var showingExportOptions = false
    @State private var showingImportPicker = false
    @State private var showingShareSheet = false
    @State private var showingImportResult = false
    @State private var showingError = false
    
    @State private var exportData: Data?
    @State private var exportFileName = "pool_data.json"
    @State private var importResult: ImportResult?
    @State private var errorMessage: String?
    
    @State private var selectedExportFormat: ExportFormat = .jsonComplete
    @State private var selectedMergeStrategy: MergeStrategy = .skipDuplicates
    
    init(context: NSManagedObjectContext) {
        _exportManager = StateObject(wrappedValue: DataExportManager(context: context))
        _importManager = StateObject(wrappedValue: DataImportManager(context: context))
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Export Section
                Section {
                    Button {
                        showingExportOptions = true
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                } header: {
                    Text("Export")
                } footer: {
                    Text("Export your pool data to share or backup")
                }
                
                // Import Section
                Section {
                    Button {
                        showingImportPicker = true
                    } label: {
                        Label("Import Data", systemImage: "square.and.arrow.down")
                    }
                    
                    Picker("Merge Strategy", selection: $selectedMergeStrategy) {
                        Text("Skip Duplicates").tag(MergeStrategy.skipDuplicates)
                        Text("Overwrite").tag(MergeStrategy.overwrite)
                        Text("Keep Both").tag(MergeStrategy.keepBoth)
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Import")
                } footer: {
                    Text(mergeStrategyDescription)
                }
                
                // Quick Actions
                Section {
                    NavigationLink {
                        ExportFormatPickerView(
                            exportManager: exportManager,
                            onExport: handleExport
                        )
                    } label: {
                        Label("Advanced Export Options", systemImage: "gearshape")
                    }
                } header: {
                    Text("Advanced")
                }
            }
            .navigationTitle("Import & Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Export Format", isPresented: $showingExportOptions) {
                Button("Complete Backup (JSON)") {
                    exportData(format: .jsonComplete)
                }
                
                Button("Pool Logs Only (JSON)") {
                    exportData(format: .jsonPoolLogs)
                }
                
                Button("Pool Logs (CSV)") {
                    exportData(format: .csvPoolLogs)
                }
                
                Button("Chemical Entries (CSV)") {
                    exportData(format: .csvChemicals)
                }
                
                Button("Maintenance Tasks (CSV)") {
                    exportData(format: .csvTasks)
                }
                
                Button("Cancel", role: .cancel) {}
            }
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [.json, .commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result: result)
            }
            .sheet(isPresented: $showingShareSheet) {
                if let data = exportData {
                    ShareSheet(items: [createTemporaryFile(data: data, fileName: exportFileName)])
                }
            }
            .alert("Import Complete", isPresented: $showingImportResult) {
                Button("OK") {
                    importResult = nil
                }
            } message: {
                if let result = importResult {
                    Text(result.summary)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let message = errorMessage {
                    Text(message)
                }
            }
        }
    }
    
    // MARK: - Export Methods
    
    private func exportData(format: ExportFormat) {
        do {
            let data: Data
            
            switch format {
            case .jsonComplete:
                data = try exportManager.exportToJSON()
                exportFileName = "pool_backup_\(dateString()).json"
                
            case .jsonPoolLogs:
                data = try exportManager.exportPoolLogsToJSON()
                exportFileName = "pool_logs_\(dateString()).json"
                
            case .csvPoolLogs:
                data = try exportManager.exportPoolLogsToCSV()
                exportFileName = "pool_logs_\(dateString()).csv"
                
            case .csvChemicals:
                data = try exportManager.exportChemicalEntriesToCSV()
                exportFileName = "chemical_entries_\(dateString()).csv"
                
            case .csvTasks:
                data = try exportManager.exportMaintenanceTasksToCSV()
                exportFileName = "maintenance_tasks_\(dateString()).csv"
            }
            
            exportData = data
            showingShareSheet = true
            
        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    // MARK: - Import Methods
    
    private func handleImport(result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            
            // Start accessing the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                throw ImportError.invalidFormat
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            let data = try Data(contentsOf: url)
            
            // Determine file type and import
            if url.pathExtension.lowercased() == "json" {
                let result = try importManager.importFromJSON(data: data, mergeStrategy: selectedMergeStrategy)
                importResult = result
                showingImportResult = true
            } else if url.pathExtension.lowercased() == "csv" {
                let result = try importManager.importPoolLogsFromCSV(data: data)
                importResult = result
                showingImportResult = true
            }
            
        } catch {
            errorMessage = "Import failed: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func handleExport(data: Data, fileName: String) {
        exportData = data
        exportFileName = fileName
        showingShareSheet = true
    }
    
    // MARK: - Helpers
    
    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func createTemporaryFile(data: Data, fileName: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        try? data.write(to: fileURL)
        
        return fileURL
    }
    
    private var mergeStrategyDescription: String {
        switch selectedMergeStrategy {
        case .skipDuplicates:
            return "Existing items with the same ID will be skipped"
        case .overwrite:
            return "Existing items with the same ID will be updated"
        case .keepBoth:
            return "Duplicate items will be imported with new IDs"
        }
    }
}

// MARK: - Export Format Picker

struct ExportFormatPickerView: View {
    @ObservedObject var exportManager: DataExportManager
    let onExport: (Data, String) -> Void
    
    @State private var selectedFormat: ExportFormat = .jsonComplete
    @State private var isExporting = false
    
    var body: some View {
        List {
            Section {
                Picker("Format", selection: $selectedFormat) {
                    ForEach(ExportFormat.allCases) { format in
                        VStack(alignment: .leading) {
                            Text(format.name)
                            Text(format.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(format)
                    }
                }
                .pickerStyle(.inline)
            } header: {
                Text("Choose Export Format")
            }
            
            Section {
                Button {
                    performExport()
                } label: {
                    HStack {
                        Text("Export")
                        Spacer()
                        if isExporting {
                            ProgressView()
                        }
                    }
                }
                .disabled(isExporting)
            }
        }
        .navigationTitle("Export Options")
    }
    
    private func performExport() {
        isExporting = true
        
        Task {
            do {
                let data: Data
                let fileName: String
                
                switch selectedFormat {
                case .jsonComplete:
                    data = try await exportManager.exportToJSON()
                    fileName = "pool_backup_\(dateString()).json"
                    
                case .jsonPoolLogs:
                    data = try await exportManager.exportPoolLogsToJSON()
                    fileName = "pool_logs_\(dateString()).json"
                    
                case .csvPoolLogs:
                    data = try await exportManager.exportPoolLogsToCSV()
                    fileName = "pool_logs_\(dateString()).csv"
                    
                case .csvChemicals:
                    data = try await exportManager.exportChemicalEntriesToCSV()
                    fileName = "chemical_entries_\(dateString()).csv"
                    
                case .csvTasks:
                    data = try await exportManager.exportMaintenanceTasksToCSV()
                    fileName = "maintenance_tasks_\(dateString()).csv"
                }
                
                await MainActor.run {
                    onExport(data, fileName)
                    isExporting = false
                }
                
            } catch {
                await MainActor.run {
                    isExporting = false
                }
            }
        }
    }
    
    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// MARK: - Export Format Enum

enum ExportFormat: String, CaseIterable, Identifiable {
    case jsonComplete = "json_complete"
    case jsonPoolLogs = "json_logs"
    case csvPoolLogs = "csv_logs"
    case csvChemicals = "csv_chemicals"
    case csvTasks = "csv_tasks"
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .jsonComplete: return "Complete Backup (JSON)"
        case .jsonPoolLogs: return "Pool Logs Only (JSON)"
        case .csvPoolLogs: return "Pool Logs (CSV)"
        case .csvChemicals: return "Chemical Entries (CSV)"
        case .csvTasks: return "Maintenance Tasks (CSV)"
        }
    }
    
    var description: String {
        switch self {
        case .jsonComplete:
            return "All data including logs, chemicals, and tasks"
        case .jsonPoolLogs:
            return "Only pool chemistry readings"
        case .csvPoolLogs:
            return "Pool logs in spreadsheet format"
        case .csvChemicals:
            return "Chemical usage in spreadsheet format"
        case .csvTasks:
            return "Maintenance schedule in spreadsheet format"
        }
    }
}

// MARK: - Share Sheet (UIKit Bridge)

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    ImportExportView(context: PersistenceController.preview.container.viewContext)
}
