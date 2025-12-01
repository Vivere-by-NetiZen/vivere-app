//
//  MatchCardTutorialSheetView.swift
//  vivere
//
//  Created by Reinhart on 18/11/25.
//

import SwiftUI

struct MatchCardTutorialSheetView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea(.all)
                .onTapGesture {_ in
                    isPresented = false
                }

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
                            Image("cardMatchTutorialStep1")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 300)

                            Text("Tekan kartu pada layar dan temukan gambar yang sama")
                                .font(.body)
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                                .tracking(-0.0731)
                                .lineSpacing(5)
                        }
                        .frame(width: 300)

                        // Step 2
                        VStack(spacing: 20) {
                            Image("cardMatchTutorialStep2")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 300)

                            Text("Kurang Tepat")
                                .font(.body)
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                                .tracking(-0.0731)
                                .lineSpacing(5)
                        }
                        .frame(width: 300)
                        
                        // Step 3
                        VStack(spacing: 20) {
                            Image("cardMatchTutorialStep3")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 300)

                            Text("Benar")
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
                CustomIpadButton(
                    color: .darkBlue,
                    showDashedBorder: true,
                    shadowColor: Color(hex: "182238"),
                    shadowOffset: CGSize(width: 2, height: 3),
                    action: {
                        isPresented = false
                    }
                ) {
                    Text("Oke")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 70)
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 30)
            .frame(maxWidth: 1060)
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
    @Previewable @State var isPresented: Bool = true
    MatchCardTutorialSheetView(isPresented: $isPresented)
}
