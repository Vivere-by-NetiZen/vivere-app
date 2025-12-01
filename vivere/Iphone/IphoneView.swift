////
////  IphoneView.swift
////  vivere
////
////  Created by Reinhart on 07/11/25.
////
//
//import SwiftUI
//import AVFoundation
//
//struct IphoneView: View {
//    init() {
//        SpeechTranscriberViewModel.requestMicrophonePermissionIfNeeded()
//    }
//    @State private var router = Router()
//    @Environment(MPCManager.self) private var mpc
//    @State private var mainText = "Pastikan iPhone Terhubung dengan Ipad-mu"
//    
//    var body: some View {
//        NavigationStack(path: $router.path) {
//            HomeView(mainText: mainText)
//                .navigationDestination(for: Route.self) { route in
//                    switch route {
//                    case .home:
//                        HomeView(mainText: mainText)
//                    case .transcribe:
//                        SpeechTranscriberView()
//                            .navigationBarHidden(true)
//                    }
//                }
//                .onChange(of: mpc.lastCommandTick) { _, _ in
//                    router.goToTranscribe()
//                }
//                .onChange(of: mpc.receivedInitialQuestionImage) { _, newImage in
//                    mainText = "iPad sedang memulai sesi game, tunggu hingga selesai"
//                }
//                .onChange(of: mpc.connectedPeers) {
//                    if !mpc.connectedPeers.isEmpty {
//                        mainText = "Pastikan iPad-mu telah memulai sesi game"
//                    } else {
//                        mainText = "Pastikan iPhone Terhubung dengan iPad-mu"
//                    }
//                }
//                .onAppear {
//                    if mpc.connectedPeers.isEmpty {
//                        mainText = "Pastikan iPhone Terhubung dengan iPad-mu"
//                    } else {
//                        mainText = "Pastikan iPad-mu telah memulai sesi game"
//                    }
//                }
//        }
//        .environment(router)
//    }
//}
