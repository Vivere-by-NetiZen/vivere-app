//
//  InstructionSheetView.swift
//  vivere
//
//  Created on 11/14/25.
//

import SwiftUI

struct InstructionSheetView: View {
    // Replace environment dismiss with an explicit callback supplied by parent
    var onDismiss: () -> Void = {}

    @State private var currentStep: Int = 1

    private let steps: [(image: String, text: String)] = [
        ("tutorial_1", "Berikan iPad kepada Eyang dan biarkan Ia memilih game"),
        ("tutorial_2", "Persiapkan iPhone Anda dan tekan mulai. Vivere akan otomatis mendengarkan setiap percakapan yang terjadi dengan Eyang."),
        ("tutorial_3", "Lihat sesekali pada iPhone Anda. Vivere akan menemani Anda dengan pertanyaan kecil yang membantu cerita mengalir alami.")
    ]

    var body: some View {
        ZStack {
            // Overlay background
            Color.black.opacity(0.23)
                .ignoresSafeArea(.all)
                .onTapGesture {
                    onDismiss()
                }

            // Modal Sheet
            VStack(spacing: 20) {
                // Header with title and close button
                HStack {
                    Text("Instruksi Cara Penggunaan")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.darkBlue)
                        .tracking(0.136)

                    Spacer()

                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.black)
                    }
                }

                // Instruction content
                VStack(alignment: .center, spacing: 20) {
                    // Image placeholder
                    Image(steps[currentStep-1].image)
                        .resizable()
                        .frame(maxWidth: 375, maxHeight: 250)

                    // Instruction text
                    Text(steps[currentStep - 1].text)
                        .font(.body)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .tracking(-0.0731)
                        .lineSpacing(5)
                        .id(currentStep) // Force view update for animation
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)
                }

                // Progress Bar
                VStack(spacing: 11) {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "F9FAFB"))
                        .frame(
                            width: 25,
                            height: currentStep == 3 ? 117 : 25
                        )
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentStep)
                        .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: 2)

                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "F9FAFB"))
                        .frame(
                            width: 25,
                            height: currentStep == 2 ? 117 : 25
                        )
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentStep)
                        .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: 2)

                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "F9FAFB"))
                        .frame(
                            width: 25,
                            height: currentStep == 1 ? 117 : 25
                        )
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentStep)
                        .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: 2)
                }
                .rotationEffect(.degrees(90))
                .frame(width: 117, height: 25)

                // Button
                CustomIpadButton(
                    color: .darkBlue,
                    showDashedBorder: true,
                    shadowColor: Color(hex: "182238"),
                    shadowOffset: CGSize(width: 2, height: 3),
                    action: {
                        if currentStep < 3 {
                            currentStep += 1
                        } else {
                            onDismiss()
                        }
                    }
                ) {
                    Text(currentStep < 3 ? "Selanjutnya" : "Saya Mengerti")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 70)
                }
            }
            .padding(.horizontal, 40)
//            .padding(.top, 0)
            .frame(width: 720, height: 620)
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
    }
}

#Preview {
    InstructionSheetView()
}

