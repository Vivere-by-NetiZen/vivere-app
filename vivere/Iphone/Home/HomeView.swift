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
    var mainText: String
    
    var body: some View {
        @Bindable var bindableMpc = mpc
        
        ZStack {
            Color.viverePrimary.ignoresSafeArea()
            
            VStack(alignment: .center, spacing: 12) {
                Image("Logo")
                    .resizable()
                    .frame(width: 117, height: 117)
                    .padding(.bottom, 22)
                Text(mainText)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            if !hasSeenBeforeStart {
                showBeforeStart = true
            }
        }
        .fullScreenCover(isPresented: $showBeforeStart) {
            OnBoardingSheetView(onStart: {
                hasSeenBeforeStart = true
                showBeforeStart = false
            })
            .padding()
            .background(.white)
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
