import SwiftUI
import CoreData

struct ContentView: View {
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
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
