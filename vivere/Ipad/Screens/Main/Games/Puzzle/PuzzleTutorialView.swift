//
//  PuzzleTutorialView.swift
//  vivere
//
//  Created by Imo Madjid on 11/12/25.
//

import Foundation
import SwiftUI

struct PuzzleTutorialView: View {
    @State private var showPuzzleView = false

    var body: some View {
        ZStack {
            // Background
            Color.viverePrimary
                .ignoresSafeArea()

            // Modal Card - Centered
            VStack(spacing: 40) {
                // Top Part
                VStack(alignment: .leading, spacing: 30) {
                    // Title
                    Text("Cara Mainnya")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundColor(.darkBlue)
                        .tracking(0.136)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Instructions
                    HStack(spacing: 40) {
                        // Instruction 1
                        VStack(spacing: 20) {
                            Image("step1")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 300)

                            Text("Pindahkan setiap potongan gambar ke tempatnya")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                                .tracking(-0.0731)
                                .lineSpacing(5)
                        }
                        .frame(width: 300)

                        // Instruction 2
                        VStack(spacing: 20) {
                            Image("step2")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 300)

                            Text("Kalau cocok, potongan gambar akan menempel otomatis")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                                .tracking(-0.0731)
                                .lineSpacing(5)
                        }
                        .frame(width: 300)
                    }
                }

                // Button
                Button(action: {
                    showPuzzleView = true
                }) {
                    Text("Oke")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 200, height: 70)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.darkBlue)
                                    .shadow(
                                        color: Color(hex: "182238"),
                                        radius: 0,
                                        x: 2,
                                        y: 3
                                    )

                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [15]))
                                    .padding(5)
                                    .foregroundColor(.white)
                            }
                        )
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
        .navigationDestination(isPresented: $showPuzzleView) {
            PuzzleView()
        }
    }
}

#Preview {
    PuzzleTutorialView()
}
