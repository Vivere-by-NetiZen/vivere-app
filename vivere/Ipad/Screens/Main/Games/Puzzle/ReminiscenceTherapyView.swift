//
//  ReminiscenceTherapyView.swift
//  vivere
//
//  Created by Imo Madjid on 11/12/25.
//

import Foundation
import SwiftUI

struct ReminiscenceTherapyView: View {
    @Environment(MPCManager.self) var mpcManager
    var body: some View {
        ZStack {
            // Frame image extending from top
            Image("frame")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.container, edges: .top)
                .padding(.horizontal)
                .padding(.bottom)
                .shadow(radius: 10, y: 10)
        }
        .navigationBarBackButtonHidden(true)
        .background(.viverePrimary)
        .ignoresSafeArea(.container, edges: .top)
        .onAppear {
            mpcManager.send(message: "show_transcriber")
        }
    }
}

#Preview {
    ReminiscenceTherapyView()
}
