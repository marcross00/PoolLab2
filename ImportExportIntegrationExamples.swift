import SwiftUI
import CoreData

// MARK: - Integration Examples

/*
 This file demonstrates how to integrate the Import/Export feature
 into your existing pool tracking app.
 */

// MARK: - Example 1: Add to Settings/More Tab

struct SettingsViewWithImportExport: View {
    @Environment(\.managedObjectContext) private var context
    @State private var showingImportExport = false
    
    var body: some View {
        NavigationStack {
            List {
                // Account Section
                Section("Account") {
                    NavigationLink("Profile") {
                        Text("Profile View")
                    }
                    NavigationLink("Preferences") {
                        Text("Preferences View")
                    }
                }
                
                // Data Management Section
                Section("Data Management") {
                    // Option A: Navigate to full view
                    NavigationLink("Import & Export") {
                        ImportExportView(context: context)
                    }
                    
                    // OR Option B: Present as sheet
                    /*
                    Button {
                        showingImportExport = true
                    } label: {
                        Label("Import & Export", systemImage: "arrow.up.arrow.down.circle")
                    }
                    */
                }
                
                // Other Sections
                Section("About") {
                    NavigationLink("Help") {
                        Text("Help View")
                    }
                    NavigationLink("Privacy Policy") {
                        Text("Privacy View")
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingImportExport) {
                ImportExportView(context: context)
            }
        }
    }
}

// MARK: - Example 2: Add to Dashboard/Home View

struct DashboardWithImportExport: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PoolLog.date, ascending: false)],
        animation: .default
    )
    private var poolLogs: FetchedResults<PoolLog>
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Latest readings card
                if let latestLog = poolLogs.first {
                    LatestReadingsCard(log: latestLog)
                        .padding(.horizontal)
                }
                
                // Quick actions
                QuickActionsGrid(context: context)
                    .padding(.horizontal)
                
                // Import/Export card
                ImportExportCard(context: context)
                    .padding(.horizontal)
                
                // Analytics preview
                if !poolLogs.isEmpty {
                    SimpleDashboardPreview(logs: Array(poolLogs))
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Pool Overview")
    }
}

// MARK: - Example 3: Toolbar Button

struct LogsViewWithExportButton: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PoolLog.date, ascending: false)],
        animation: .default
    )
    private var poolLogs: FetchedResults<PoolLog>
    
    @State private var showingExport = false
    @State private var exportData: Data?
    @State private var showingShareSheet = false
    
    var body: some View {
        List {
            ForEach(poolLogs) { log in
                PoolLogRow(log: log)
            }
        }
        .navigationTitle("Pool Logs")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        exportCurrentLogs()
                    } label: {
                        Label("Export Logs", systemImage: "square.and.arrow.up")
                    }
                    
                    Button {
                        showingExport = true
                    } label: {
                        Label("Import & Export", systemImage: "arrow.up.arrow.down.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingExport) {
            ImportExportView(context: context)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let data = exportData {
                ShareSheet(items: [createTemporaryFile(data: data)])
            }
        }
    }
    
    private func exportCurrentLogs() {
        let exportManager = DataExportManager(context: context)
        
        do {
            let data = try exportManager.exportPoolLogsToCSV()
            exportData = data
            showingShareSheet = true
        } catch {
            print("Export failed: \(error)")
        }
    }
    
    private func createTemporaryFile(data: Data) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        let fileURL = tempDir.appendingPathComponent("pool_logs_\(dateString).csv")
        try? data.write(to: fileURL)
        return fileURL
    }
}

// MARK: - Example 4: Context Menu Integration

struct LogDetailWithExport: View {
    let log: PoolLog
    @Environment(\.managedObjectContext) private var context
    
    @State private var showingExport = false
    @State private var exportData: Data?
    @State private var showingShareSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Log details
                Group {
                    if let ph = log.phValue {
                        Text("pH: \(ph, specifier: "%.1f")")
                    } else {
                        Text("pH: --")
                    }
                    
                    if let fc = log.fcValue {
                        Text("FC: \(fc, specifier: "%.1f") ppm")
                    } else {
                        Text("FC: --")
                    }
                }
                // ... more details
            }
            .padding()
        }
        .navigationTitle("Log Details")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    exportSingleLog()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let data = exportData {
                ShareSheet(items: [createTemporaryFile(data: data)])
            }
        }
    }
    
    private func exportSingleLog() {
        // Export just this log as JSON
        let exportable = PoolLogExportable(
            id: log.id ?? UUID(),
            date: log.date ?? Date(),
            ph: log.phValue ?? 0.0,
            fc: log.fcValue ?? 0.0,
            ta: log.taValue ?? 0.0,
            ch: log.chValue ?? 0.0,
            cya: log.cyaValue ?? 0.0,
            saltPpm: log.saltPpmValue ?? 0.0,
            notes: log.notes
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted]
        
        if let data = try? encoder.encode([exportable]) {
            exportData = data
            showingShareSheet = true
        }
    }
    
    private func createTemporaryFile(data: Data) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("pool_log.json")
        try? data.write(to: fileURL)
        return fileURL
    }
}

// MARK: - Example 5: Main Tab View Integration

struct MainTabViewWithImportExport: View {
    @Environment(\.managedObjectContext) private var context
    
    var body: some View {
        TabView {
            // Dashboard Tab
            NavigationStack {
                DashboardWithImportExport()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            
            // Logs Tab
            NavigationStack {
                LogsViewWithExportButton()
            }
            .tabItem {
                Label("Logs", systemImage: "list.bullet")
            }
            
            // Analytics Tab
            NavigationStack {
                Text("Analytics View")
            }
            .tabItem {
                Label("Analytics", systemImage: "chart.line.uptrend.xyaxis")
            }
            
            // Settings Tab (with Import/Export)
            NavigationStack {
                SettingsViewWithImportExport()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
    }
}

// MARK: - Supporting Views

struct LatestReadingsCard: View {
    let log: PoolLog
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Latest Reading")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("pH")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let ph = log.phValue {
                        Text("\(ph, specifier: "%.1f")")
                            .font(.title2)
                            .fontWeight(.semibold)
                    } else {
                        Text("--")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("FC")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let fc = log.fcValue {
                        Text("\(fc, specifier: "%.1f") ppm")
                            .font(.title2)
                            .fontWeight(.semibold)
                    } else {
                        Text("--")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct ImportExportCard: View {
    let context: NSManagedObjectContext
    @State private var showingImportExport = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data Management")
                .font(.headline)
            
            Text("Import or export your pool data")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button {
                showingImportExport = true
            } label: {
                Label("Import & Export", systemImage: "arrow.up.arrow.down.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .sheet(isPresented: $showingImportExport) {
            ImportExportView(context: context)
        }
    }
}

struct SimpleDashboardPreview: View {
    let logs: [PoolLog]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Trends")
                .font(.headline)
            
            Text("\(logs.count) total logs")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct QuickActionsGrid: View {
    let context: NSManagedObjectContext
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            QuickActionButton(
                title: "Add Log",
                icon: "plus.circle.fill",
                color: .blue
            ) {
                // Add log action
            }
            
            QuickActionButton(
                title: "Test Water",
                icon: "drop.fill",
                color: .cyan
            ) {
                // Test water action
            }
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
}

struct PoolLogRow: View {
    let log: PoolLog
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(log.date ?? Date(), style: .date)
                .font(.headline)
            
            HStack {
                if let ph = log.phValue {
                    Text("pH: \(ph, specifier: "%.1f")")
                } else {
                    Text("pH: --")
                }
                
                Spacer()
                
                if let fc = log.fcValue {
                    Text("FC: \(fc, specifier: "%.1f")")
                } else {
                    Text("FC: --")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Previews

#Preview("Settings with Import/Export") {
    SettingsViewWithImportExport()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

#Preview("Dashboard with Import/Export") {
    NavigationStack {
        DashboardWithImportExport()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

#Preview("Main Tab View") {
    MainTabViewWithImportExport()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
