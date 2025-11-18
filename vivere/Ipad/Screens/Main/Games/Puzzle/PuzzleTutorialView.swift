//
//  PuzzleTutorialView.swift
//  vivere
//
//  Created on 11/14/25.
//

import SwiftUI

struct PuzzleTutorialView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.viverePrimary
                .ignoresSafeArea(.all)

            VStack(spacing: 40) {
                // Top Part
                VStack(alignment: .leading, spacing: 30) {
                    // Header with title
                    Text("Cara Mainnya")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.darkBlue)
                        .tracking(0.136)

                    // Instructions - Two steps side by side
                    HStack(spacing: 40) {
                        // Step 1
                        VStack(spacing: 20) {
                            Image("step1")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 300)

                            Text("Pindahkan setiap potongan gambar ke tempatnya")
                                .font(.body)
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                                .tracking(-0.0731)
                                .lineSpacing(5)
                        }
                        .frame(width: 300)

                        // Step 2
                        VStack(spacing: 20) {
                            Image("step2")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 300)

                            Text("Kalau cocok, potongan gambar akan menempel otomatis")
                                .font(.body)
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                                .tracking(-0.0731)
                                .lineSpacing(5)
                        }
                        .frame(width: 300)
                    }
                }

                // Button
                NavigationLink(value: HomeDestination.puzzle) {
                    CustomIpadButton(
                        color: .darkBlue,
                        showDashedBorder: true,
                        shadowColor: Color(hex: "182238"),
                        shadowOffset: CGSize(width: 2, height: 3),
                        action: {}
                    ) {
                        Text("Oke")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 200, height: 70)
                    }
                    .styledContent
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 30)
            .frame(maxWidth: 720)
            .background(Color.accent)
            .cornerRadius(20)
            .shadow(
                color: Color(hex: "87622a"),
                radius: 0,
                x: 5,
                y: 6
            )
            .overlay(
                // Decorative accessories
                ZStack {
                    // Bottom right accessory
                    Image("buttonRight")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(.bottom, 17)
                        .padding(.trailing, 20)

                    // Bottom left accessory
                    Image("buttonLeft")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                        .padding(.bottom, 17)
                        .padding(.leading, 20)
                }
            )
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NavigationStack {
        PuzzleTutorialView()
    }
}

