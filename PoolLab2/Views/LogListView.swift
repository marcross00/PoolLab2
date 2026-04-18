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
                                AddEditLogView(log: log)
                            } label: {
                                LogRowView(log: log)
                            }
                        }
                        .onDelete(perform: deleteLogs)
                    }
                }
            }
            .navigationTitle("Pool Logs")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddLog = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddLog) {
                NavigationStack {
                    AddEditLogView()
                }
            }
        }
    }

    private func deleteLogs(at offsets: IndexSet) {
        for index in offsets {
            viewContext.delete(logs[index])
        }
        try? viewContext.save()
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
