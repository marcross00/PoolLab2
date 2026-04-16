import SwiftUI
public import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        TabView {
            LogListView()
                .tabItem {
                    Label("Logs", systemImage: "drop.circle")
                }
            
            TaskListView()
                .tabItem {
                    Label("Tasks", systemImage: "calendar.badge.clock")
                }
            
            AnalyticsView(context: viewContext)
                .tabItem {
                    Label("Analytics", systemImage: "chart.xyaxis.line")
                }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
