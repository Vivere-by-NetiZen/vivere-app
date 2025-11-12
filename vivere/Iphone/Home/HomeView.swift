//
//  HomeView.swift
//  vivere
//
//  Created by Ahmed Nizhan Haikal on 10/11/25.
//

import Foundation
import SwiftUI
import MultipeerConnectivity

struct HomeView: View {
    @AppStorage("hasSeenBeforeStart") private var hasSeenBeforeStart = false
    @State private var showBeforeStart = false
    @State private var sheetHeight: CGFloat = .zero
    @Environment(Router.self) private var router
    @Environment(MPCManager.self) private var mpc
    
    var body: some View {
        @Bindable var bindableMpc = mpc
        
        VStack (alignment: .center) {
            Image("Logo")
                .resizable()
                .frame(width: 117, height: 117)
                .padding(.bottom, 22)
            Text("Hai! ini Vivere mu")
                .font(.title)
                .foregroundStyle(Color.white)
                .padding(.bottom, 3)
            Text("Ciptakan obrolan bermakna dengan lansia bersama Vivere!")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.white)
            if mpc.connectedPeers.isEmpty {
                Text("Belum ada orang tersambung. Tap to connect.")
            } else {
                Text("Connected to:")
                    .font(.headline)
                ForEach(mpc.connectedPeers, id: \.self) { peer in
                    Text(peer.displayName)
                }
            }
            Button("Open Transcription") {
                router.goToTranscribe()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .background(Color.viverePrimary)
        .onAppear {
            if !hasSeenBeforeStart {
                showBeforeStart = true
            }
        }
        .sheet(isPresented: $showBeforeStart) {
            OnBoardingSheetView(onStart: {
                hasSeenBeforeStart = true
                showBeforeStart = false
            })
            .padding()
            .fixedSize(horizontal: false, vertical: true)
            .modifier(GetHeightModifier(height: $sheetHeight))
            .background(.white)
            .presentationDetents([.height(sheetHeight)])
        }
        .alert(item: $bindableMpc.pendingInvitation) { invitation in
            Alert(
                title: Text("Pair Request"),
                message: Text("\(invitation.peer.displayName) wants to connect"),
                primaryButton: .default(Text("Connect")) {
                    mpc.respondToInvitation(accept: true)
                },
                secondaryButton: .cancel(Text("Decline")) {
                    mpc.respondToInvitation(accept: false)
                }
            )
        }
    }
}

struct GetHeightModifier: ViewModifier {
    @Binding var height: CGFloat

    func body(content: Content) -> some View {
        content.background(
            GeometryReader { geo -> Color in
                DispatchQueue.main.async {
                    height = geo.size.height
                }
                return Color.white
            }
        )
    }
}
