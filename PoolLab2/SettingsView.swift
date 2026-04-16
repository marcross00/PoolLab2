import SwiftUI
internal import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var context
    
    var body: some View {
        NavigationStack {
            List {
                // Data Management Section
                Section {
                    NavigationLink {
                        ImportExportView(context: context)
                    } label: {
                        Label("Import & Export", systemImage: "arrow.up.arrow.down.circle")
                    }
                } header: {
                    Text("Data Management")
                } footer: {
                    Text("Backup, restore, and share your pool data")
                }
                
                // App Information Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://support.apple.com")!) {
                        HStack {
                            Text("Help & Support")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // Data Statistics Section
                DataStatisticsSection()
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Data Statistics Section

struct DataStatisticsSection: View {
    @Environment(\.managedObjectContext) private var context
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PoolLog.date, ascending: false)],
        animation: .default
    )
    private var poolLogs: FetchedResults<PoolLog>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ChemicalEntry.date, ascending: false)],
        animation: .default
    )
    private var chemicals: FetchedResults<ChemicalEntry>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MaintenanceTask.name, ascending: true)],
        animation: .default
    )
    private var tasks: FetchedResults<MaintenanceTask>
    
    var body: some View {
        Section("Data Statistics") {
            HStack {
                Label("Pool Logs", systemImage: "drop.fill")
                Spacer()
                Text("\(poolLogs.count)")
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Label("Chemical Entries", systemImage: "flask.fill")
                Spacer()
                Text("\(chemicals.count)")
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Label("Maintenance Tasks", systemImage: "wrench.and.screwdriver.fill")
                Spacer()
                Text("\(tasks.count)")
                    .foregroundStyle(.secondary)
            }
            
            if let oldestLog = poolLogs.last?.date {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tracking Since")
                        .font(.subheadline)
                    Text(oldestLog, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
