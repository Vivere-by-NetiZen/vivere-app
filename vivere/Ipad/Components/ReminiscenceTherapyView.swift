//
//  ReminiscenceTherapyView.swift
//  vivere
//
//  Created by Imo Madjid on 11/12/25.
//

import AVKit
import Foundation
import SwiftData
import SwiftUI
import Photos

struct ReminiscenceTherapyView: View {
    let operationId: String?

    @State private var videoURL: URL?
    @State private var player: AVQueuePlayer?
    @State private var playerLooper: AVPlayerLooper?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var fallbackImage: UIImage?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var images: [ImageModel]

    // Add debugging info
    private var debugInfo: String {
        "OperationId: \(operationId ?? "nil")"
    }

    init(operationId: String? = nil) {
        self.operationId = operationId
    }

    var body: some View {
        ZStack {
            Color.viverePrimary
                .ignoresSafeArea()

            if let player = player {
                // ZStack to center video and frame together
                ZStack {
                    // Frame image on top of video (centered together)
                    Image("frame")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea(.container, edges: .top)
                        .padding(.horizontal)
                        .padding(.bottom)
                        .shadow(radius: 10, y: 10)
                        .allowsHitTesting(false) // Allow taps to pass through to video controls if needed
                    // Video player with infinite loop (behind frame)
                    // Video dimensions are always 640 × 400 (aspect ratio: 1.6)
                    GeometryReader { proxy in
                        Color.clear
                            .overlay(
                                VideoPlayer(player: player)
                                    .aspectRatio(640 / 400, contentMode: .fit)
                                    .frame(width: proxy.size.width * 0.6)
                                    .offset(y: 40)
                            )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if isLoading {
                // Loading state with fallback image
                ZStack {
                    if let fallbackImage {
                        ZStack {
                            Image("frame")
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .ignoresSafeArea(.container, edges: .top)
                                .padding(.horizontal)
                                .padding(.bottom)
                                .shadow(radius: 10, y: 10)

                            GeometryReader { proxy in
                                Color.clear
                                    .overlay(
                                        Image(uiImage: fallbackImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: proxy.size.width * 0.6)
                                            .offset(y: 40)
                                    )
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                        // Overlay loading indicator
                        VStack(spacing: 24) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                                .padding()
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(16)

                            Text("Preparing video...")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(8)
                        }
                    } else {
                        VStack(spacing: 24) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)

                            Text("Preparing video...")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                    }
                }
            } else if let error = errorMessage {
                // Error state
                VStack(spacing: 24) {
                    Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(.white)

                    Text("Unable to load video")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.white)

                    if !error.isEmpty {
                        Text(error)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
            } else {
                // No video available
                VStack(spacing: 24) {
                    Image(systemName: "video.slash")
                        .font(.largeTitle)
                        .foregroundColor(.white)

                    Text("No video available")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
            }

            // Debug menu - always visible
            DebugMenuView()
                .zIndex(1000)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            loadVideo()
            loadFallbackImage()
        }
        .onDisappear {
            // Clean up player looper when view disappears
            playerLooper?.disableLooping()
            playerLooper = nil
            player?.pause()
            player = nil
        }
        .onReceive(NotificationCenter.default.publisher(for: .videoDownloadCompleted)) { notification in
            print("DEBUG: Received videoDownloadCompleted notification for operation: \(notification.userInfo?["operationId"] ?? "nil")")
            if let completedOpId = notification.userInfo?["operationId"] as? String,
               completedOpId == operationId
            {
                print("DEBUG: Operation ID matches, loading video")
                loadVideo()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .videoDownloadFailed)) { notification in
            print("DEBUG: Received videoDownloadFailed notification for operation: \(notification.userInfo?["operationId"] ?? "nil")")
            if let failedOpId = notification.userInfo?["operationId"] as? String,
               failedOpId == operationId
            {
                isLoading = false
                errorMessage = notification.userInfo?["error"] as? String ?? "Video generation failed"
                print("DEBUG: Error message set: \(errorMessage ?? "nil")")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToHome)) { _ in
            // Dismiss this view to go back
            dismiss()
        }
    }

    private func loadVideo() {
        print("DEBUG: loadVideo called for operationId: \(operationId ?? "nil")")
        guard let operationId = operationId else {
            isLoading = false
            errorMessage = "No operation ID provided"
            return
        }

        // Check if video is already downloaded
        if let localURL = VideoDownloadService.shared.getLocalVideoURL(operationId: operationId) {
            print("DEBUG: Video found locally at \(localURL)")
            videoURL = localURL
            setupLoopingPlayer(url: localURL)
            isLoading = false
            return
        }

        print("DEBUG: Video not found locally, checking status immediately")
        isLoading = true

        Task {
            do {
                let status = try await VideoGenerationService.shared.checkStatus(operationId: operationId)
                print("DEBUG: Status check result: \(status.status)")

                let statusLower = status.status.lowercased()
                if statusLower == "completed" {
                    print("DEBUG: Video is completed, downloading...")
                    await VideoDownloadService.shared.downloadVideo(operationId: operationId)

                    if let localURL = VideoDownloadService.shared.getLocalVideoURL(operationId: operationId) {
                        await MainActor.run {
                            videoURL = localURL
                            setupLoopingPlayer(url: localURL)
                            isLoading = false
                        }
                    } else {
                        await MainActor.run {
                            isLoading = false
                            errorMessage = "Video download failed"
                        }
                    }
                } else if statusLower == "failed" || statusLower == "error" {
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "Video generation failed"
                    }
                } else {
                    print("DEBUG: Video status is \(status.status), starting monitoring")
                    VideoDownloadService.shared.startMonitoring(operationId: operationId)
                }
            } catch {
                print("DEBUG: Error checking status: \(error)")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to check video status: \(error.localizedDescription)"
                }
            }
        }
    }

    private func loadFallbackImage() {
        guard let operationId = operationId else { return }
        guard let imageModel = images.first(where: { $0.operationId == operationId }) else { return }

        Task {
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: [imageModel.assetId], options: nil)
            guard let asset = assets.firstObject else { return }

            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            var hasResumed = false
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 640, height: 400),
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                guard !hasResumed, let image = image else { return }
                hasResumed = true
                Task { @MainActor in
                    self.fallbackImage = image
                }
            }
        }
    }

    /// Setup looping video player using AVPlayerLooper
    private func setupLoopingPlayer(url: URL) {
        // Clean up previous looper if exists
        playerLooper?.disableLooping()
        playerLooper = nil

        // Create player item
        let playerItem = AVPlayerItem(url: url)

        // Create queue player for looping
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)

        // Create looper to enable infinite looping
        let looper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)

        // Store references
        player = queuePlayer
        playerLooper = looper

        // Start playing
        queuePlayer.play()
    }
}

#Preview {
    ReminiscenceTherapyView()
}
