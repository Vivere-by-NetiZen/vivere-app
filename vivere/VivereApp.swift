import SwiftUI
import SwiftData

@main
struct VivereApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
        .modelContainer(for: [ImageModel.self])
    }
}
