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
    
    // New: publish received image intended for initial question
    var receivedInitialQuestionImage: UIImage? = nil
    
    // New: a monotonically increasing tick for command events (e.g., "show_transcriber")
    var lastCommandTick: Int = 0
    
    var pendingInvitation: PendingInvitation?
    private var pendingInvitationHandler: ((Bool, MCSession?) -> Void)?
    
    // New: track which peer is currently being invited by the iPad
    var invitingPeer: MCPeerID?
    
    private(set) var preferredPeer: MCPeerID?
    
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
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
        
        // Now we can call super and then reference self
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
    
    // Existing string helper
    func send(message: String) {
        guard !session.connectedPeers.isEmpty else { return }
        guard let data = message.data(using: .utf8) else { return }
        try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
    }
    
    // New generic data send
    func send(data: Data) {
        guard !session.connectedPeers.isEmpty else { return }
        try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
    }
}

extension MPCManager: MCSessionDelegate {
    // Not used but required
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
                // Always keep lastReceivedMessage for any UI/logs
                self.lastReceivedMessage = "From \(peerID.displayName): \(message)"
                
                // If it's a navigation command, tick the counter so .onChange always fires
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
                    // Mark inviting and use longer timeout for auto-invite as well
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
            // If we were inviting this peer and it disappeared, clear inviting state
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

