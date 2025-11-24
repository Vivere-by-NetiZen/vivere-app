//
//  GoodbyeView.swift
//  vivere
//
//  Created by Reinhart on 18/11/25.
//

import SwiftUI

struct GoodbyeView: View {
    @State private var autoReturnTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea(.all)
            
            HStack {
                VStack(alignment: .leading) {
                    Image("buttonLeft")
                        .padding()
                    Spacer()
                    Image("buttonLeft")
                        .padding()
                }
                .padding()
                
                VStack {
                    Image("medal")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 450)
                        .padding()
                    Text("Terima kasih telah bermain bersama Vivere! Kami tunggu permainan selanjutnya ya!")
                        .font(.system(size: 40))
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .multilineTextAlignment(.center)
                .padding(.vertical, 30)
                
                VStack(alignment: .trailing) {
                    Image("buttonRight")
                        .padding()
                    Spacer()
                    Image("buttonRight")
                        .padding()
                }
                .padding()
            }
            .frame(maxWidth: 1000, maxHeight: 600)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .foregroundColor(.accent)
            )
        }
        .onAppear {
            autoReturnTask = Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    NotificationCenter.default.post(name: .navigateToHome, object: nil)
                }
            }
        }
        .onDisappear {
            autoReturnTask?.cancel()
            autoReturnTask = nil
        }
    }
}

#Preview {
    GoodbyeView()
}
