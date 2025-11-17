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
    @AppStorage("debugSkipDeviceConnection") private var skipDeviceConnection: Bool = false
    @Environment(MPCManager.self) private var mpc

    var body: some View {
        ZStack {
            Color.viverePrimary.ignoresSafeArea(edges: .all)

            VStack {
                HStack {
                    Image("progressStepper1")
                    Line()
                        .stroke(style: StrokeStyle(lineWidth: 4, dash: [15]))
                        .frame(height: 1)
                    Image("progressStepper2")
                        .saturation(0)
                    Line()
                        .stroke(style: StrokeStyle(lineWidth: 4, dash: [15]))
                        .frame(height: 1)
                    Image("progressStepper3")
                        .saturation(0)
                }
                .frame(maxWidth: 400)
                .padding()

                ZStack {
                    Color.vivereSecondary.frame(width: 300, height: 300)
                        .clipShape(Circle())
                    Text("ASET")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.red)
                }

                Text("Unduh Vivere di iPhone Anda")
                    .font(Font.largeTitle.bold())
                    .foregroundColor(.white)
                    .padding(.top, 30)

                Text("Vivere menggunakan dua perangkat, iPad dan iPhone untuk interaksi satu sama lain. Jadi pastikan Anda sudah unduh Vivere di iPhone ya.")
                    .font(Font.title)
                    .foregroundColor(Color.white)
                    .frame(width: 800)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                    .padding(.bottom, 30)

                CustomIpadButton(label: "Lanjut", color: .accent, style: .large){
                    isNextPressed = true
                }

            }

            if isNextPressed {
                PairDeviceView(isNextPressed: $isNextPressed, isPaired: $isPaired)
            }

        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $isPaired) {
            MediaCollectionView()
        }
        .onChange(of: isNextPressed) { _, next in
            if next, !mpc.connectedPeers.isEmpty {
                isPaired = true
            }
        }
        .onChange(of: mpc.connectedPeers) { _, peers in
            if isNextPressed, !peers.isEmpty {
                isPaired = true
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
}

#Preview {
    DeviceConnectionView()
}
