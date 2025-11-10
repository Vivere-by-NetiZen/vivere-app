import SwiftUI

@Observable
final class AppState {
    var isPairingComplete: Bool = false
}

struct RootView: View {
    @State private var appState = AppState()

    var body: some View {
        if appState.isPairingComplete {
            ContentView()
                .transition(.opacity)
        } else {
            PairingView(continueAction: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    appState.isPairingComplete = true
                }
            })
            .transition(.opacity)
        }
    }
}
