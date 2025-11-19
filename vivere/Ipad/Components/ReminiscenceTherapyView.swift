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

struct ReminiscenceTherapyView: View {
    let jobId: String?

    @State private var videoURL: URL?
    @State private var player: AVQueuePlayer?
    @State private var playerLooper: AVPlayerLooper?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    init(jobId: String? = nil) {
        self.jobId = jobId
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
                // Loading state
                VStack(spacing: 24) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)

                    Text("Preparing video...")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
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
        }
        .onDisappear {
            // Clean up player looper when view disappears
            playerLooper?.disableLooping()
            playerLooper = nil
            player?.pause()
            player = nil
        }
        .onReceive(NotificationCenter.default.publisher(for: .videoDownloadCompleted)) { notification in
            if let completedJobId = notification.userInfo?["jobId"] as? String,
               completedJobId == jobId
            {
                loadVideo()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .videoDownloadFailed)) { notification in
            if let failedJobId = notification.userInfo?["jobId"] as? String,
               failedJobId == jobId
            {
                isLoading = false
                errorMessage = notification.userInfo?["error"] as? String ?? "Video generation failed"
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToHome)) { _ in
            // Dismiss this view to go back
            dismiss()
        }
    }

    private func loadVideo() {
        guard let jobId = jobId else {
            isLoading = false
            errorMessage = "No job ID provided"
            return
        }

        // Check if video is already downloaded
        if let localURL = VideoDownloadService.shared.getLocalVideoURL(jobId: jobId) {
            videoURL = localURL
            setupLoopingPlayer(url: localURL)
            isLoading = false
            return
        }

        // Start monitoring and downloading
        isLoading = true
        VideoDownloadService.shared.startMonitoring(jobId: jobId)
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
