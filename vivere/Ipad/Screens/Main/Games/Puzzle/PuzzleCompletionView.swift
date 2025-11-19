//
//  PuzzleCompletionView.swift
//  vivere
//
//  Created by Imo Madjid on 11/12/25.
//

import Foundation
import SwiftUI
import ConfettiSwiftUI

struct PuzzleCompletionView: View {
    @State private var confettiTrigger: Int = 0
    @State private var showReminiscenceTherapy = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.viverePrimary
                    .ignoresSafeArea()

                VStack(spacing: 42) {
                    Image("medal")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 498, height: 357)

                    VStack(spacing: 16) {
                        Text("Kamu Hebat!")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                            .tracking(0.136)

                        Text("Anda berhasil merangkainya, kami punya hadiah untukmu!")
                            .font(.system(size: 28, weight: .regular))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .tracking(0.1064)
                            .lineSpacing(6)
                            .frame(maxWidth: 750)
                    }

                    // Button to navigate to Reminiscence Therapy
                    CustomIpadButton(label: "Lihat Hadiah", color: .accent, style: .large) {
                        showReminiscenceTherapy = true
                    }
                }
                .padding(41)
                .frame(minWidth: 600, maxWidth: 750)

                VStack {
                    Spacer()
                    HStack {
                        Color.clear
                            .frame(width: 10, height: 10)
                            .confettiCannon(
                                trigger: $confettiTrigger,
                                num: 50,
                                openingAngle: Angle.degrees(0),
                                closingAngle: Angle.degrees(90),
                                radius: 800,
                                repetitions: 3,
                                repetitionInterval: 0.5
                            )

                        Spacer()

                        // Right cannon (bottom-right corner)
                        Color.clear
                            .frame(width: 10, height: 10)
                            .confettiCannon(
                                trigger: $confettiTrigger,
                                num: 50,
                                openingAngle: Angle.degrees(90),
                                closingAngle: Angle.degrees(180),
                                radius: 800,
                                repetitions: 3,
                                repetitionInterval: 0.5
                            )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .onAppear {
                confettiTrigger += 1
            }
            .navigationDestination(isPresented: $showReminiscenceTherapy) {
                ReminiscenceTherapyView()
                    .navigationBarBackButtonHidden(true)
            }
        }
    }
}

#Preview {
    PuzzleCompletionView()
}

