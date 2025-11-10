import SwiftUI

@main
struct VivereApp: App {
    var body: some Scene {
        WindowGroup {
            PairingGateView()
        }
    }
}

private struct PairingGateView: View {
    @State private var pairingCoordinator = PairingCoordinator()

    var body: some View {
        Group {
            if pairingCoordinator.hasEnteredApp {
                ContentView()
            } else {
                PairingScreen(coordinator: pairingCoordinator)
            }
        }
    }
}
