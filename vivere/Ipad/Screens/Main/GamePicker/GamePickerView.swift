//
//  GamePickerView.swift
//  vivere
//
//  Created by Imo Madjid on 11/11/25.
//

import SwiftUI

struct GamePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showPuzzleView = false

    var body: some View {
        ZStack {
            Color.viverePrimary
                .ignoresSafeArea(edges: .all)

            VStack(spacing: 0) {
                // Title Section
                VStack(alignment: .leading, spacing: 78) {
                    Text("Mau main apa hari ini?")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundColor(.white)
                        .tracking(0.192)
                        .padding(.top, 51)

                    // Game Cards Section
                    HStack(alignment: .center, spacing: 114) {
                        // Cocokkan Gambar Card
                        CustomIpadButton(
                            color: .accent,
                            showDashedBorder: false,
                            shadowColor: Color(hex: "87622a"),
                            shadowOffset: CGSize(width: 3, height: 4),
                            action: {
                                // Action for Cocokkan Gambar
                            }
                        ) {
                            VStack(spacing: 20) {
                                Image("cocokkanGambar")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 340, height: 350)

                                Text("Cocokkan Gambar")
                                    .font(.system(size: 32, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                            .padding(30)
                            .frame(minWidth: 400, minHeight: 470)
                        }

                        // Puzzle Card
                        CustomIpadButton(
                            color: .accent,
                            showDashedBorder: false,
                            shadowColor: Color(hex: "87622a"),
                            shadowOffset: CGSize(width: 3, height: 4),
                            action: {
                                showPuzzleView = true
                            }
                        ) {
                            VStack(spacing: 20) {
                                Image("puzzle")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 340, height: 350)

                                Text("Puzzle")
                                    .font(.system(size: 32, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                            .padding(30)
                            .frame(minWidth: 400, minHeight: 470)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Back Button
                    CustomIpadButton(
                        label: "Kembali",
                        icon: Image(systemName: "chevron.left"),
                        color: .vivereSecondary,
                        style: .small
                    ) {
                        dismiss()
                    }
                }
                .padding(.horizontal, 66)
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showPuzzleView) {
            PuzzleTutorialView()
        }
    }
}

#Preview {
    NavigationStack {
        GamePickerView()
    }
}
