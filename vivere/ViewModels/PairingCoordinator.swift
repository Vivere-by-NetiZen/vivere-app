import Foundation
import Observation
import UIKit
import Network
import WiFiAware

@MainActor
@Observable
final class PairingCoordinator {

    enum Role {
        case initiator
        case responder
    }

    static let pairingServiceName = "_vivere-share._tcp"

    private(set) var role: Role
    var isPaired: Bool = false
    var statusMessage: String?
    var errorMessage: String?
    var lastPairedDeviceName: String?
    var hasEnteredApp: Bool = false

    @ObservationIgnored private var observerTask: Task<Void, Never>?

    init() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.role = .initiator
        } else {
            self.role = .responder
        }

        statusMessage = "Waiting to pair with a nearby device."
        startObservingPairedDevices()
    }

    deinit {
        observerTask?.cancel()
    }

    func beginInitiating() {
        statusMessage = "Searching for nearby devices…"
    }

    func beginAdvertising() {
        statusMessage = "Ready to accept pairing requests."
    }

    func recordPairingConfirmation() {
        statusMessage = "Paired endpoint ready."
        isPaired = true
    }

    func continueToApp() {
        hasEnteredApp = true
    }

    private func startObservingPairedDevices() {
        observerTask?.cancel()
        observerTask = Task {
            do {
                let anyDevicePredicate = #Predicate<WAPairedDevice> { _ in true }
                for try await devices in WAPairedDevice.allDevices(matching: anyDevicePredicate) {
                    let matchedDevices = devices.values
                    let firstDevice = matchedDevices.first
                    await MainActor.run {
                        self.isPaired = firstDevice != nil
                        if let device = firstDevice {
                            let name = device.pairingInfo?.pairingName ?? "Paired Device"
                            self.lastPairedDeviceName = name
                            self.statusMessage = "Paired with \(name)."
                        } else {
                            self.lastPairedDeviceName = nil
                            self.statusMessage = "Waiting to pair with a nearby device."
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Unable to monitor paired devices: \(error.localizedDescription)"
                }
            }
        }
    }

    static var publishableService: WAPublishableService? {
        WAPublishableService.allServices[pairingServiceName]
    }

    static var subscribableService: WASubscribableService? {
        WASubscribableService.allServices[pairingServiceName]
    }
}

