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
    @Environment(\.dismiss) var dismiss
    @State private var confettiTrigger: Int = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.viverePrimary
                    .ignoresSafeArea()

                VStack(spacing: 42) {
                    // Medal Image
                    Image("medal")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 498, height: 357)

                    // Text Section
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
                }
                .padding(41)
                .frame(minWidth: 600, maxWidth: 750)

                // Confetti cannon positioned at bottom center
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Color.clear
                            .frame(width: 1, height: 1)
                            .confettiCannon(
                                trigger: $confettiTrigger,
                                num: 50,
                                openingAngle: Angle.degrees(135),
                                closingAngle: Angle.degrees(45),
                                radius: 400,
                                repetitions: 3,
                                repetitionInterval: 0.5
                            )
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, 50)
            }
            .onAppear {
                // Trigger confetti when view appears
                confettiTrigger += 1
            }
        }
    }
}

#Preview {
    PuzzleCompletionView()
}

