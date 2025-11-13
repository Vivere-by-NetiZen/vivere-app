//
//  IphoneView.swift
//  vivere
//
//  Created by Reinhart on 07/11/25.
//

import SwiftUI
import AVFoundation

struct IphoneView: View {
    @State private var router = Router()
    @Environment(MPCManager.self) private var mpc
    
    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .home:
                        HomeView()
                    case .transcribe:
                        SpeechTranscriberView()
                    }
                }
                // Trigger navigation on every "show_transcriber" command by ticking a counter
                .onChange(of: mpc.lastCommandTick) { _, _ in
                    router.goToTranscribe()
                }
                .onChange(of: mpc.receivedInitialQuestionImage) { _, newImage in
                    if let img = newImage {
                        SpeechTranscriberViewModel.shared.getInitialQuestion(image: img)
                    }
                }
        }
        .environment(router)
    }
}
