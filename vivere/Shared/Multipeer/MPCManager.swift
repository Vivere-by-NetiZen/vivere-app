//
//  MPCManager.swift
//  vivere
//
//  Created by Ahmed Nizhan Haikal on 11/11/25.
//

import Foundation
import MultipeerConnectivity
import Combine
import UIKit

enum DeviceRole {
    case ipadHost
    case iphoneClient
}

struct PendingInvitation: Identifiable {
    let id = UUID()
    let peer: MCPeerID
}

private struct PendingSend {
    let peer: MCPeerID
    let data: Data
}

@Observable
class MPCManager: NSObject {
    private let serviceType = "vivere-sync"
    private let preferredPeerKey = "preferredPeerKey"
    private let localPeerKey = "localPeerKey"
    
    let role: DeviceRole
    let peerID: MCPeerID
    let session: MCSession
    
    var discoveredPeers: [MCPeerID] = []
    var connectedPeers: [MCPeerID] = []
    var lastReceivedMessage: String = ""
    
    // Publish received image intended for initial question
    var receivedInitialQuestionImage: UIImage? = nil
    
    // A monotonically increasing tick for command events (e.g., "show_transcriber")
    var lastCommandTick: Int = 0
    
    var pendingInvitation: PendingInvitation?
    private var pendingInvitationHandler: ((Bool, MCSession?) -> Void)?
    
    // Track which peer is currently being invited by the iPad
    var invitingPeer: MCPeerID?
    
    private(set) var preferredPeer: MCPeerID?
    
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    // Queue for pending sends while waiting for connection
    private var pendingSends: [PendingSend] = []
    
    override init() {
        // Determine role without referencing self
        let resolvedRole: DeviceRole
        #if os(iOS)
        let idiom = UIDevice.current.userInterfaceIdiom
        resolvedRole = (idiom == .pad) ? .ipadHost : .iphoneClient
        #else
        resolvedRole = .iphoneClient
        #endif
        self.role = resolvedRole
        
        // Load or create a stable local MCPeerID without referencing self
        let localKey = "localPeerKey"
        let localPeer = MPCManager.loadLocalPeer(withKey: localKey) ?? {
            #if os(iOS)
            let displayName = UIDevice.current.name
            #else
            let displayName = Host.current().localizedName ?? "Device"
            #endif
            let newPeer = MCPeerID(displayName: displayName)
            MPCManager.saveLocalPeer(newPeer, withKey: localKey)
            return newPeer
        }()
        self.peerID = localPeer
        
        // Create session
        let session = MCSession(peer: localPeer, securityIdentity: nil, encryptionPreference: .required)
        self.session = session
        
        super.init()
        
        self.session.delegate = self
        self.preferredPeer = loadPreferredPeer()
        setupConnectivity()
    }
    
    private func setupConnectivity() {
        switch role {
        case .ipadHost:
            browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
            browser?.delegate = self
            browser?.startBrowsingForPeers()
            
        case .iphoneClient:
            advertiser = MCNearbyServiceAdvertiser(
                peer: peerID,
                discoveryInfo: ["role": "iphoneClient"],
                serviceType: serviceType
            )
            advertiser?.delegate = self
            advertiser?.startAdvertisingPeer()
        }
    }
    
    // iPad manually connects first time
    func connect(to peer: MCPeerID) {
        guard role == .ipadHost else { return }
        guard session.connectedPeers.isEmpty else { return }   // only 1 at a time
        // Mark inviting state and use a longer timeout to allow slow accepts
        DispatchQueue.main.async {
            self.invitingPeer = peer
        }
        browser?.invitePeer(peer, to: session, withContext: nil, timeout: 60)
    }
    
    // Save & load preferred peer
    private func savePreferredPeer(_ peer: MCPeerID) {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: peer, requiringSecureCoding: true)
            UserDefaults.standard.set(data, forKey: preferredPeerKey)
            preferredPeer = peer
        } catch {
            print("Failed to archive preferred peer: \(error)")
        }
    }
    
    private func loadPreferredPeer() -> MCPeerID? {
        guard let data = UserDefaults.standard.data(forKey: preferredPeerKey) else { return nil }
        do {
            let peer = try NSKeyedUnarchiver.unarchivedObject(ofClass: MCPeerID.self, from: data)
            return peer
        } catch {
            print("Failed to unarchive preferred peer: \(error)")
            return nil
        }
    }
    
    // Persist local MCPeerID so identity survives app restarts
    private static func saveLocalPeer(_ peer: MCPeerID, withKey key: String) {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: peer, requiringSecureCoding: true)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Failed to archive local peer: \(error)")
        }
    }
    
    private static func loadLocalPeer(withKey key: String) -> MCPeerID? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        do {
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: MCPeerID.self, from: data)
        } catch {
            print("Failed to unarchive local peer: \(error)")
            return nil
        }
    }
    
    // Optional: reset local identity if you ever need to re-pair as a new device
    func resetLocalPeerIdentity() {
        // Warning: changing MCPeerID will break existing pairings until re-paired.
        UserDefaults.standard.removeObject(forKey: localPeerKey)
    }
    
    func respondToInvitation(accept: Bool) {
        pendingInvitationHandler?(accept, accept ? session : nil)
        pendingInvitationHandler = nil
        pendingInvitation = nil
    }
    
    // Existing string helper (broadcast)
    func send(message: String) {
        guard !session.connectedPeers.isEmpty else { return }
        guard let data = message.data(using: .utf8) else { return }
        try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
    }
    
    // Existing generic data send (broadcast)
    func send(data: Data) {
        guard !session.connectedPeers.isEmpty else { return }
        try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
    }
    
    // Views call this; MPCManager handles encoding, targeting, queueing and flushing
    func sendInitialQuestionImage(_ image: UIImage) {
        // Encode image (prefer JPEG if no alpha)
        let hasAlpha: Bool = {
            guard let cgImage = image.cgImage else { return false }
            switch cgImage.alphaInfo {
            case .first, .last, .premultipliedFirst, .premultipliedLast:
                return true
            default:
                return false
            }
        }()
        
        let imageData: Data?
        if hasAlpha {
            imageData = image.pngData()
        } else {
            imageData = image.jpegData(compressionQuality: 0.8) ?? image.pngData()
        }
        guard let payload = imageData else { return }
        
        // Envelope: [4 bytes typeLen][type utf8][payload]
        let type = "initial_question_image"
        guard let typeData = type.data(using: .utf8) else { return }
        var envelope = Data()
        var typeLen = UInt32(typeData.count).bigEndian
        withUnsafeBytes(of: &typeLen) { envelope.append(contentsOf: $0) }
        envelope.append(typeData)
        envelope.append(payload)
        
        // Target preferred peer if known, else first connected peer, else queue against preferred when it becomes known/connected
        if let target = preferredPeer ?? session.connectedPeers.first {
            send(data: envelope, to: target)
        } else {
            // No known peer to associate with; we cannot enqueue without a target.
            // We could choose to wait until a preferred peer is discovered; for now, do nothing.
            #if DEBUG
            print("MPC: No target peer available to send initial question image.")
            #endif
        }
    }
    
    // MARK: - Internal targeted send with queue
    
    @discardableResult
    private func send(data: Data, to peer: MCPeerID) -> Bool {
        if session.connectedPeers.contains(peer) {
            do {
                try session.send(data, toPeers: [peer], with: .reliable)
                return true
            } catch {
                enqueue(data: data, to: peer)
                return false
            }
        } else {
            enqueue(data: data, to: peer)
            return false
        }
    }
    
    private func enqueue(data: Data, to peer: MCPeerID) {
        pendingSends.append(PendingSend(peer: peer, data: data))
        #if DEBUG
        print("MPC: Enqueued \(data.count) bytes for \(peer.displayName)")
        #endif
    }
    
    private func flushPending(for peer: MCPeerID) {
        guard !pendingSends.isEmpty else { return }
        var remaining: [PendingSend] = []
        for item in pendingSends {
            if item.peer == peer, session.connectedPeers.contains(peer) {
                do {
                    try session.send(item.data, toPeers: [peer], with: .reliable)
                    #if DEBUG
                    print("MPC: Flushed \(item.data.count) bytes to \(peer.displayName)")
                    #endif
                } catch {
                    // Keep it for a later retry
                    remaining.append(item)
                }
            } else {
                remaining.append(item)
            }
        }
        pendingSends = remaining
    }
}

extension MPCManager: MCSessionDelegate {
    func session(_ session: MCSession,
                 didReceive stream: InputStream,
                 withName streamName: String,
                 fromPeer peerID: MCPeerID) {}
    
    func session(_ session: MCSession,
                 didStartReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 with progress: Progress) {}
    
    func session(_ session: MCSession,
                 didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 at localURL: URL?,
                 withError error: Error?) {}
    
    func session(_ session: MCSession, didReceive data: Data,
                 fromPeer peerID: MCPeerID) {
        // Try to parse our simple envelope: [4 bytes typeLen][type utf8][payload]
        if data.count >= 4 {
            let typeLenData = data.prefix(4)
            let typeLen = typeLenData.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
            let afterLen = data.dropFirst(4)
            if afterLen.count >= Int(typeLen) {
                let typeData = afterLen.prefix(Int(typeLen))
                let payload = afterLen.dropFirst(Int(typeLen))
                let type = String(data: typeData, encoding: .utf8) ?? ""
                
                if type == "initial_question_image",
                   let image = UIImage(data: payload) {
                    DispatchQueue.main.async {
                        self.receivedInitialQuestionImage = image
                    }
                    return
                }
            }
        }
        
        // Fallback: treat as utf8 string commands/messages
        if let message = String(data: data, encoding: .utf8) {
            DispatchQueue.main.async {
                self.lastReceivedMessage = "From \(peerID.displayName): \(message)"
                if message == "show_transcriber" {
                    self.lastCommandTick &+= 1
                }
            }
        }
    }
    
    func session(_ session: MCSession,
                 peer peerID: MCPeerID,
                 didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.connectedPeers = session.connectedPeers
            
            if self.invitingPeer == peerID && (state == .connected || state == .notConnected) {
                self.invitingPeer = nil
            }
        }
        
        if state == .connected {
            if preferredPeer == nil {
                savePreferredPeer(peerID)
                print("Saved preferred peer: \(peerID.displayName)")
            } else if peerID != preferredPeer {
                print("Connected to non-preferred peer; preferred is \(preferredPeer!.displayName)")
            }
            flushPending(for: peerID)
        }
    }
}

extension MPCManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("iPhone: received invitation from \(peerID.displayName)")
        
        // On iPhone, auto-accept if inviter matches previously paired iPad
        if role == .iphoneClient, let preferred = preferredPeer, preferred == peerID {
            print("Auto-accepting invitation from preferred iPad: \(peerID.displayName)")
            invitationHandler(true, session)
            return
        }
        
        // Otherwise, present alert to the user
        DispatchQueue.main.async {
            self.pendingInvitationHandler = invitationHandler
            self.pendingInvitation = PendingInvitation(peer: peerID)
        }
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didNotStartAdvertisingPeer error: Error) {
        print("Failed to advertise: \(error)")
    }
}

extension MPCManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser,
                 foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String : String]?) {
        
        guard role == .ipadHost else { return }
        
        // If we already have a preferred iPhone saved:
        if let preferred = preferredPeer {
            if peerID == preferred {
                print("Found preferred iPhone \(peerID.displayName)")
                if session.connectedPeers.isEmpty {
                    DispatchQueue.main.async {
                        self.invitingPeer = peerID
                    }
                    browser.invitePeer(peerID, to: session, withContext: nil, timeout: 60)
                }
            } else {
                print("Ignoring non-preferred peer \(peerID.displayName)")
            }
        } else {
            DispatchQueue.main.async {
                if !self.discoveredPeers.contains(where: { $0 == peerID }) {
                    self.discoveredPeers.append(peerID)
                }
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser,
                 lostPeer peerID: MCPeerID) {
        guard role == .ipadHost else { return }
        DispatchQueue.main.async {
            self.discoveredPeers.removeAll { $0 == peerID }
            if self.invitingPeer == peerID {
                self.invitingPeer = nil
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser,
                 didNotStartBrowsingForPeers error: Error) {
        print("Failed to browse: \(error)")
    }
    
    func forgetPreferredPeer() {
        UserDefaults.standard.removeObject(forKey: preferredPeerKey)
        preferredPeer = nil
    }
}

