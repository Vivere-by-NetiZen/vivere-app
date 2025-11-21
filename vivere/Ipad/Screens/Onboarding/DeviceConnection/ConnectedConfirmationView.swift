//
//  ConnectedConfirmationView.swift
//  vivere
//
//  Created by Assistant on 11/21/25.
//

import SwiftUI

struct ConnectedConfirmationView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea(.all)

            VStack(spacing: 16) {
                // Title
                Text("Perangkat berhasil terhubung")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)

                // Face ID–style checkmark
                ZStack {
                    Circle()
                        .fill(.clear)
                        .stroke(.blue, lineWidth: 4)
                        .frame(width: 88, height: 82)
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)

                    Image(systemName: "checkmark")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                        .scaleEffect(1.0)
                }
//                .padding(.top, 4)

//                Spacer(minLength: 0)

                Text("Sekarang iPad dan iPhone Anda sudah terhubung satu sama lain dan siap untuk digunakan.")
                    .font(.body)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
            }
            .padding(40)
            .frame(maxWidth: 500, maxHeight: 320)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .shadow(radius: 16)
            )
        }
    }
}

#Preview {
    ConnectedConfirmationView()
}
