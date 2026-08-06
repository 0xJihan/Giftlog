import SwiftUI
import SwiftData

@main
struct GiftLogApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: GiftEntry.self)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
    }
}
