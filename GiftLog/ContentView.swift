import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        MainAppView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: GiftEntry.self, inMemory: true)
}
