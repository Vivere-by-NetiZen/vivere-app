//
//  PuzzleCompletionView.swift
//  vivere
//
//  Created by Imo Madjid on 11/12/25.
//

import Foundation
import SwiftUI
import SwiftData

struct PuzzleCompletionView: View {
    let imageModel: ImageModel?

    @State private var confettiTrigger: Int = 0
    @State private var showReminiscenceTherapy = false
    @Environment(\.dismiss) private var dismiss

    init(imageModel: ImageModel? = nil) {
        self.imageModel = imageModel
    }

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
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .tracking(0.136)

                        Text("Anda berhasil merangkainya, kami punya hadiah untukmu!")
                            .font(.title3)
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

                // Debug menu - always visible
                DebugMenuView()
                    .zIndex(1000)
            }
            .onAppear {
                confettiTrigger += 1
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigateToHome)) { _ in
                // Dismiss this view to go back to home
                dismiss()
            }
            .navigationDestination(isPresented: $showReminiscenceTherapy) {
                ReminiscenceTherapyView(operationId: imageModel?.operationId, imageModel: imageModel)
            }
        }
    }
}

#Preview {
    // Create a mock ImageModel for preview
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: ImageModel.self, configurations: config)
    let mockImage = ImageModel(assetId: "mock", context: "Mock Context", operationId: "mock-op-id")

    return PuzzleCompletionView(imageModel: mockImage)
        .modelContainer(container)
}

