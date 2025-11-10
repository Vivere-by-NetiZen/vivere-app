import SwiftUI
import DeviceDiscoveryUI
import WiFiAware
import Network
import Observation

struct PairingScreen: View {
    @Bindable var coordinator: PairingCoordinator

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Pair Your Devices")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(instructions)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }

                statusSection

                roleSpecificControls
                errorSection

                Spacer()

                Button("Continue to App") {
                    coordinator.continueToApp()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!coordinator.isPaired)
            }
            .padding(32)
            .navigationTitle("Pairing")
        }
    }

    private var instructions: String {
        switch coordinator.role {
        case .initiator:
            return "Use your iPad to find nearby iPhones and request pairing."
        case .responder:
            return "Confirm the pairing request from the iPad to share a high-speed link."
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        if let status = coordinator.statusMessage {
            Label(status, systemImage: coordinator.isPaired ? "checkmark.circle.fill" : "wifi")
                .foregroundStyle(coordinator.isPaired ? Color.green : Color.accentColor)
        }

        if let name = coordinator.lastPairedDeviceName, coordinator.isPaired {
            Text("Connected with: \(name)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var roleSpecificControls: some View {
        switch coordinator.role {
        case .initiator:
            initiatorControls
        case .responder:
            responderControls
        }
    }

    @ViewBuilder
    private var errorSection: some View {
        if let error = coordinator.errorMessage {
            Text(error)
                .multilineTextAlignment(.center)
                .foregroundStyle(.red)
        }
    }

    @ViewBuilder
    private var initiatorControls: some View {
        if let service = PairingCoordinator.subscribableService {
            DevicePicker(
                .wifiAware(.connecting(to: .selected([]), from: service))
            ) { _ in
                coordinator.recordPairingConfirmation()
            } label: {
                Label("Browse Nearby Devices", systemImage: "dot.radiowaves.right")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.accentColor.opacity(0.1)))
            } fallback: {
                Text("Unable to present the device picker.")
                    .foregroundStyle(.red)
            }
            .onAppear { coordinator.beginInitiating() }

            Text("Select your iPhone from the list. Enter the PIN shown on the iPhone to complete pairing.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        } else {
            missingServiceView
        }
    }

    @ViewBuilder
    private var responderControls: some View {
        if let service = PairingCoordinator.publishableService {
            DevicePairingView(
                .wifiAware(.connecting(to: service, from: .selected([])))
            ) {
                VStack(spacing: 12) {
                    Label("Waiting for pairing request", systemImage: "iphone")
                        .foregroundStyle(Color.accentColor)
                    Text("Keep this screen visible to display the pairing PIN when requested by the iPad.")
                        .multilineTextAlignment(.center)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } fallback: {
                Text("Unable to present the pairing interface.")
                    .foregroundStyle(.red)
            }
            .onAppear { coordinator.beginAdvertising() }
        } else {
            missingServiceView
        }
    }

    private var missingServiceView: some View {
        Text("Wi-Fi Aware service is not configured in Info.plist.")
            .multilineTextAlignment(.center)
            .foregroundStyle(.red)
    }
}

