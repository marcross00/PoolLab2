import SwiftUI
internal import CoreData

struct LogListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PoolLog.date, ascending: false)],
        animation: .default
    )
    private var logs: FetchedResults<PoolLog>

    @State private var showingAddLog = false
    @State private var showingDeleteAllAlert = false
    @State private var showingDeleteOldAlert = false
    @State private var logToDelete: PoolLog?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            Group {
                if logs.isEmpty {
                    ContentUnavailableView(
                        "No Logs Yet",
                        systemImage: "drop.circle",
                        description: Text("Tap + to add your first pool log.")
                    )
                } else {
                    List {
                        ForEach(logs) { log in
                            NavigationLink {
                                LogDetailView(log: log)
                            } label: {
                                LogRowView(log: log)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteLog(log)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .contextMenu {
                                Button {
                                    logToDelete = log
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    // Edit action
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                            }
                        }
                        .onDelete(perform: deleteLogs)
                    }
                }
            }
            .navigationTitle("Pool Logs")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !logs.isEmpty {
                        EditButton()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingAddLog = true
                        } label: {
                            Label("Add Log", systemImage: "plus")
                        }
                        
                        if !logs.isEmpty {
                            Divider()
                            
                            Button(role: .destructive) {
                                showingDeleteOldAlert = true
                            } label: {
                                Label("Delete Old Logs", systemImage: "calendar.badge.minus")
                            }
                            
                            Button(role: .destructive) {
                                showingDeleteAllAlert = true
                            } label: {
                                Label("Delete All Logs", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAddLog) {
                NavigationStack {
                    AddEditLogView()
                }
            }
            .alert("Delete Log?", isPresented: $showingDeleteConfirmation, presenting: logToDelete) { log in
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteLog(log)
                }
            } message: { log in
                Text("This will permanently delete the log from \(log.wrappedDate, format: .dateTime.month().day().year()).")
            }
            .alert("Delete All Logs?", isPresented: $showingDeleteAllAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete All", role: .destructive) {
                    deleteAllLogs()
                }
            } message: {
                Text("This will permanently delete all \(logs.count) logs. This action cannot be undone.")
            }
            .alert("Delete Old Logs", isPresented: $showingDeleteOldAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Older than 90 days", role: .destructive) {
                    deleteOldLogs(days: 90)
                }
                Button("Older than 180 days", role: .destructive) {
                    deleteOldLogs(days: 180)
                }
                Button("Older than 1 year", role: .destructive) {
                    deleteOldLogs(days: 365)
                }
            } message: {
                Text("Choose how old logs should be deleted.")
            }
        }
    }

    private func deleteLogs(at offsets: IndexSet) {
        for index in offsets {
            viewContext.delete(logs[index])
        }
        do {
            try viewContext.save()
        } catch {
            print("Error deleting logs: \(error.localizedDescription)")
        }
    }
    
    private func deleteLog(_ log: PoolLog) {
        viewContext.delete(log)
        do {
            try viewContext.save()
        } catch {
            print("Error deleting log: \(error.localizedDescription)")
        }
    }
    
    private func deleteAllLogs() {
        for log in logs {
            viewContext.delete(log)
        }
        do {
            try viewContext.save()
        } catch {
            print("Error deleting all logs: \(error.localizedDescription)")
        }
    }
    
    private func deleteOldLogs(days: Int) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        var deletedCount = 0
        for log in logs {
            if let logDate = log.date, logDate < cutoffDate {
                viewContext.delete(log)
                deletedCount += 1
            }
        }
        
        do {
            try viewContext.save()
            print("Deleted \(deletedCount) logs older than \(days) days")
        } catch {
            print("Error deleting old logs: \(error.localizedDescription)")
        }
    }
}

private struct LogRowView: View {
    let log: PoolLog

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(log.wrappedDate, formatter: Self.dateFormatter)
                .font(.headline)
            HStack(spacing: 16) {
                Label(log.phValue.formatted(with: "%.1f"), systemImage: "drop.fill")
                    .foregroundStyle(.blue)
                Label(log.fcValue.formatted(with: "%.1f"), systemImage: "bubbles.and.sparkles")
                    .foregroundStyle(.orange)
                Label(log.saltPpmValue.formatted(with: "%.0f"), systemImage: "cube.fill")
                    .foregroundStyle(.gray)
            }
            .font(.subheadline)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    LogListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
