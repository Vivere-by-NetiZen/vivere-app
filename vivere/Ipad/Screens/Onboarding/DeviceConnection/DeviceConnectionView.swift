//
//  DeviceConnectionView.swift
//  vivere
//
//  Created by Reinhart on 09/11/25.
//

import SwiftUI

struct DeviceConnectionView: View {
    @State private var isNextPressed: Bool = false
    @State private var isPaired: Bool = false
    @State private var showConnectedConfirmation: Bool = false
    @AppStorage("debugSkipDeviceConnection") private var skipDeviceConnection: Bool = false
    @Environment(MPCManager.self) private var mpc

    var body: some View {
        ZStack {
            Color.viverePrimary.ignoresSafeArea(edges: .all)

            VStack(spacing: 32) {

                Image("downloadVivere")
                    .frame(width: 300, height: 300)

                VStack(spacing: 16){
                    Text("Install Vivere di iPhonemu")
                        .font(Font.largeTitle.bold())
                        .foregroundColor(.white)

                    Text("Vivere menggunakan dua perangkat, iPad dan iPhone untuk interaksi satu sama lain. Jadi pastikan Anda sudah unduh Vivere di iPhone ya.")
                        .font(Font.title)
                        .foregroundColor(Color.white)
                        .frame(width: 800)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }

                CustomIpadButton(label: "Sudah Install", color: .accent, style: .large){
                    isNextPressed = true
                }
                .font(Font.title.bold())
            }

            if isNextPressed {
                PairDeviceView(isNextPressed: $isNextPressed, isPaired: $isPaired)
            }

            // Connected confirmation overlay (shows after connection is established)
            if showConnectedConfirmation {
                ConnectedConfirmationView()
                    .transition(.opacity.combined(with: .scale))
                    .zIndex(1)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $isPaired) {
            MediaCollectionView()
        }
        .onChange(of: isNextPressed) { _, next in
            // If user opens the pairing sheet and is already connected, show confirmation instead of navigating immediately
            if next, !mpc.connectedPeers.isEmpty {
                presentConnectedConfirmationThenNavigate()
            }
        }
        .onChange(of: mpc.connectedPeers) { _, peers in
            // When pairing UI is visible and a connection happens, show confirmation overlay first
            if isNextPressed, !peers.isEmpty {
                presentConnectedConfirmationThenNavigate()
            }
        }
        .onAppear {
            // Skip device connection if debug toggle is enabled
            if skipDeviceConnection {
                isPaired = true
            }
        }
        .onChange(of: skipDeviceConnection) { _, skip in
            // If debug toggle is enabled, skip to next step
            if skip {
                isPaired = true
            }
        }
    }

    private func presentConnectedConfirmationThenNavigate() {
        // Close the pairing overlay and show confirmation overlay
        isNextPressed = false
        showConnectedConfirmation = true

        // Auto-dismiss after a short delay and navigate
        let delay: TimeInterval = 1.8
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            showConnectedConfirmation = false
            isPaired = true
        }
    }
}

#Preview {
    DeviceConnectionView()
}
