import SwiftUI
import SwiftData

@main
struct VivereApp: App {
    init() {
        // Request microphone permission as early as possible at app launch.
        SpeechTranscriberViewModel.requestMicrophonePermissionIfNeeded()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
        .modelContainer(for: [ImageModel.self])
    }
}
