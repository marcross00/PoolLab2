import SwiftUI
import CoreData
import UniformTypeIdentifiers

/// Compact import/export buttons for integration into existing views
struct ImportExportQuickActions: View {
    @Environment(\.managedObjectContext) private var context
    
    @StateObject private var exportManager: DataExportManager
    @StateObject private var importManager: DataImportManager
    
    @State private var showingFullView = false
    @State private var showingExportMenu = false
    @State private var showingImportPicker = false
    @State private var showingShareSheet = false
    
    @State private var exportData: Data?
    @State private var exportFileName = "pool_data.json"
    
    init(context: NSManagedObjectContext) {
        _exportManager = StateObject(wrappedValue: DataExportManager(context: context))
        _importManager = StateObject(wrappedValue: DataImportManager(context: context))
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Quick Export Button
            Button {
                showingExportMenu = true
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            // Quick Import Button
            Button {
                showingImportPicker = true
            } label: {
                Label("Import", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            // Advanced Options Button
            Button {
                showingFullView = true
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .buttonStyle(.bordered)
        }
        .confirmationDialog("Quick Export", isPresented: $showingExportMenu) {
            Button("Complete Backup") {
                quickExport(format: .jsonComplete)
            }
            
            Button("Pool Logs (CSV)") {
                quickExport(format: .csvPoolLogs)
            }
            
            Button("Cancel", role: .cancel) {}
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [.json, .commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            handleQuickImport(result: result)
        }
        .sheet(isPresented: $showingFullView) {
            ImportExportView(context: context)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let data = exportData {
                ShareSheet(items: [createTemporaryFile(data: data, fileName: exportFileName)])
            }
        }
    }
    
    private func quickExport(format: ExportFormat) {
        Task {
            do {
                let data: Data
                
                switch format {
                case .jsonComplete:
                    data = try await exportManager.exportToJSON()
                    exportFileName = "pool_backup_\(dateString()).json"
                    
                case .csvPoolLogs:
                    data = try await exportManager.exportPoolLogsToCSV()
                    exportFileName = "pool_logs_\(dateString()).csv"
                    
                default:
                    return
                }
                
                await MainActor.run {
                    exportData = data
                    showingShareSheet = true
                }
            } catch {
                print("Export error: \(error)")
            }
        }
    }
    
    private func handleQuickImport(result: Result<[URL], Error>) {
        // Quick import with default settings
        do {
            guard let url = try result.get().first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            let data = try Data(contentsOf: url)
            
            Task {
                do {
                    if url.pathExtension.lowercased() == "json" {
                        _ = try await importManager.importFromJSON(data: data, mergeStrategy: .skipDuplicates)
                    } else if url.pathExtension.lowercased() == "csv" {
                        _ = try await importManager.importPoolLogsFromCSV(data: data)
                    }
                } catch {
                    print("Import error: \(error)")
                }
            }
        } catch {
            print("File access error: \(error)")
        }
    }
    
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
}

// MARK: - Preview

#Preview("Quick Actions") {
    VStack {
        ImportExportQuickActions(
            context: PersistenceController.preview.container.viewContext
        )
        .padding()
    }
}


