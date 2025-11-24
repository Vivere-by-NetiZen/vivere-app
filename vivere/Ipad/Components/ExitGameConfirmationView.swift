//
//  ExitGameConfirmationView.swift
//  vivere
//
//  Created by Reinhart on 20/11/25.
//

import SwiftUI

struct ExitGameConfirmationView: View {
    @Binding var isPresented: Bool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.viverePrimary
                .ignoresSafeArea(.all)
            
            VStack {
                Image("exitGameConfirmation")
                    .padding()
                Text("Apakah kamu yakin keluar permainan?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.white)
                    .padding()
                HStack {
                    CustomIpadButton(label: "Tetap Bermain", color: Color(hex: "D8E0F4"), style: .large) {
                        isPresented = false
                    }
                    .padding()
                    
                    CustomIpadButton(label: "Keluar", color: .accent, style: .large) {
                        dismiss()
                    }
                    .padding()
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var isPresented: Bool = true
    ExitGameConfirmationView(isPresented: $isPresented)
}
