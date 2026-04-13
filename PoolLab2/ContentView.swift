import SwiftUI

struct ContentView: View {
    var body: some View {
        LogListView()
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
