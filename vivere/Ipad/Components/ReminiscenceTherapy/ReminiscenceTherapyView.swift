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
    let imageModel: ImageModel?

    private var operationId: String? {
        imageModel?.operationId
    }

    @State private var videoURL: URL?
    @State private var player: AVQueuePlayer?
    @State private var playerLooper: AVPlayerLooper?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var fallbackImage: UIImage?
    @State private var path = NavigationPath()
    @State var viewModel = ReminiscenceTherapyViewModel.shared
    @State var isRecording: Bool = false
    @State var showEndSessionAlert: Bool = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private var debugInfo: String {
        "OperationId: \(operationId ?? "nil")"
    }

    init(imageModel: ImageModel? = nil, fallbackImage: UIImage? = nil) {
        self.imageModel = imageModel
        _fallbackImage = State(initialValue: fallbackImage)
    }

    @State private var showGoodbye = false

    @State private var isPanelOnRight: Bool = true
    @State private var isPanelVisible: Bool = false

    var body: some View {
        ZStack {
            Color.viverePrimary
                .ignoresSafeArea()

            GeometryReader { geo in
                HStack(spacing: 0) {
                    if isPanelOnRight {
                        mainSlot(geo: geo, panelWidth: panelWidth(for: geo))
                        collapsingPanelSlot(geo: geo)
                    } else {
                        collapsingPanelSlot(geo: geo)
                        mainSlot(geo: geo, panelWidth: panelWidth(for: geo))
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: isPanelOnRight)
                .animation(.easeInOut(duration: 0.3), value: isPanelVisible)
            }
            .zIndex(100000)

            panelToggleButton
                .frame(maxWidth: .infinity, maxHeight: .infinity,
                       alignment: isPanelOnRight ? .topTrailing : .topLeading)
                .padding(40)

            DebugMenuView()
                .zIndex(1000)
        }
        .overlay {
            if showEndSessionAlert {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        VStack(spacing: 10){
                            Text("Apakah kamu yakin untuk mengakhiri sesi?")
                                .font(.body)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.primary)

                            Text("Mengakhiri sesi akan menghentikan terapi dan menyimpan hasilnya secara otomatis.")
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.black)
                        }
                        .padding(24)

                        HStack(spacing: 16) {
                            Button {
                                withAnimation(.easeInOut) {
                                    showEndSessionAlert = false
                                }
                            } label: {
                                Text("Batalkan")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 13)
                                    .padding(.horizontal, 16)
                            }
                            .buttonStyle(.bordered)
                            .tint(.gray)
                            .foregroundStyle(.black)

                            Button {
                                withAnimation(.easeInOut) {
                                    showEndSessionAlert = false
                                }
                                viewModel.toggle(resume: false)
                                NotificationCenter.default.post(name: .navigateToHome, object: nil)
                            } label: {
                                Text("Ya")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 13)
                                    .padding(.horizontal, 16)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.accentColor)
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                    .frame(maxWidth: 298)
                    .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
                    .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 8)
                    .padding(.horizontal, 24)
                    .transition(.scale.combined(with: .opacity))
                }
                .animation(.easeInOut, value: showEndSessionAlert)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            loadVideo()
            loadFallbackImage()
        }
        .navigationDestination(isPresented: $showGoodbye) {
            GoodbyeView()
                .navigationBarBackButtonHidden(true)
        }
        .onDisappear {
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
            dismiss()
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToOnboarding)) { _ in
            path.append(Teleporter.onboarding)
        }
        .navigationDestination(for: Teleporter.self) { destination in
            switch destination {
            case .onboarding:
                OnboardingView()
            }
        }
        .task {
            await Task.yield()
            viewModel.toggle(resume: false)
        }
        //        .padding(40)
        //        .background(Color.viverePrimary)
    }

    // MARK: - Layout helpers

    private func panelWidth(for geo: GeometryProxy) -> CGFloat {
        let target = geo.size.width * 0.25
        return isPanelVisible ? target : 0
    }

    private func mainSlot(geo: GeometryProxy, panelWidth: CGFloat) -> some View {
        let mainWidth = geo.size.width - panelWidth
        return mainContent
            .frame(width: max(0, mainWidth), height: geo.size.height)
            .clipped()
    }

    private func collapsingPanelSlot(geo: GeometryProxy) -> some View {
        let width = panelWidth(for: geo)

        return ZStack(alignment: isPanelOnRight ? .trailing : .leading) {
            Color.clear

            if isPanelVisible {
                VStack {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading) {
                            Label("Saran Tanggapan", systemImage: "sparkles.2")
                                .font(.footnote.weight(.medium))
                            Label("Mendengarkan", systemImage: "circle.fill")
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(.red)
                        }

                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isPanelOnRight.toggle()
                            }
                        } label: {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.title3)
                                .foregroundStyle(.black)
                        }

                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isPanelVisible.toggle()
                            }
                        } label: {
                            Image(systemName: isPanelOnRight ? "sidebar.trailing" : "sidebar.leading")
                                .font(.title3)
                                .foregroundStyle(.black)
                        }
                    }

                    Divider().opacity(0.15)

                    SidePanel(showEndSessionAlert: $showEndSessionAlert, viewModel: viewModel)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.thinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .padding()
                .transition(.move(edge: isPanelOnRight ? .trailing : .leading).combined(with: .opacity))
            }
        }
        .frame(width: width, height: geo.size.height)
        .clipped()
    }

    private var panelToggleButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                isPanelVisible.toggle()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(.systemGray6),
                                Color(.systemGray3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 73, height: 70)
                    .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 4)

                Image(systemName: "questionmark.bubble")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.black)
                    .frame(width: 48, height: 48)
            }
        }
    }

    // MARK: - Subviews
    private var mainContent: some View {
                GeometryReader { proxy in
                    let maxW = min(proxy.size.width, 944)
                    let maxH = min(proxy.size.height, 531)
                    let aspect: CGFloat = 16.0 / 9.0

                    let widthIfMaxWidth = maxW
                    let heightIfMaxWidth = widthIfMaxWidth / aspect

                    let heightIfMaxHeight = maxH
                    let widthIfMaxHeight = heightIfMaxHeight * aspect

                    let useWidth = heightIfMaxWidth <= maxH
                    let fittedWidth: CGFloat = useWidth ? widthIfMaxWidth : widthIfMaxHeight
                    let fittedHeight: CGFloat = useWidth ? heightIfMaxWidth : heightIfMaxHeight

                    let border: CGFloat = 16

                    VStack {
                Spacer(minLength: 0)

                        Text(viewModel.initialQuestion)
                            .font(.largeTitle.bold())
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color(.white))
                    .opacity(viewModel.initialQuestion.isEmpty ? 0 : 1)

                        ZStack {
                    // Card Background
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.2), radius: 14, x: 0, y: 8)
                                .frame(width: fittedWidth + border, height: fittedHeight + border)

                    // Content Area
                    ZStack {
                        Color.black // Background

                        if let fallbackImage {
                            Image(uiImage: fallbackImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: fittedWidth, height: fittedHeight)
                        }

                        if let player = player {
                            VideoPlayer(player: player)
                        }

                        // Overlays
                        if isLoading {
                            ZStack {
                                Color.black.opacity(0.4)
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
                        } else if let error = errorMessage {
                            ZStack {
                                Color.black.opacity(0.6)
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
                                .padding(20)
                            }
                        } else if player == nil {
                            ZStack {
                                Color.black.opacity(0.2)
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
                        }
                    }
                    .frame(width: fittedWidth, height: fittedHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                // Buttons
                        HStack {
                            HStack(spacing: 17) {
                                Button {
                                    Task {
                                        try? await MoodProcessingService.updateFeaturedModelEmotion(to: "happy", in: modelContext)
                                    }
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 45, height: 44)
                                        Image(systemName: "hand.thumbsup")
                                            .resizable()
                                            .foregroundStyle(.black)
                                            .scaledToFill()
                                            .frame(width: 26, height: 28)
                                    }
                                }
                                Button{
                                    Task {
                                        try? await MoodProcessingService.updateFeaturedModelEmotion(to: "sad", in: modelContext)
                                    }
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 45, height: 44)
                                        Image(systemName: "hand.thumbsdown")
                                            .resizable()
                                            .foregroundStyle(.black)
                                            .scaledToFill()
                                            .frame(width: 26, height: 28)
                                    }
                                }
                            }

                            Spacer()

                            Button(action: {
                                showEndSessionAlert = true
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 45, height: 44)
                                        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 4)

                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(red: 241/255, green: 113/255, blue: 113/255))
                                        .frame(width: 23, height: 23)
                                }
                            }
                            .disabled(viewModel.isFetchingSuggestion)
                        }
                        .padding(.horizontal, 170)
                        .padding(.top, 32)
                .opacity(isLoading ? 0.5 : 1.0)
                .disabled(isLoading)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Video loading/fallback

    private func loadVideo() {
        print("DEBUG: loadVideo called for operationId: \(operationId ?? "nil")")
        guard let operationId = operationId else {
            isLoading = false
            errorMessage = "No operation ID provided"
            loadFallbackImage()
            return
        }

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
        if fallbackImage != nil { return }

        guard let imageModel = imageModel else {
            print("DEBUG: No image model provided for fallback")
            return
        }

        Task {
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: [imageModel.assetId], options: nil)
            guard let asset = assets.firstObject else {
                print("DEBUG: Could not find asset for assetId: \(imageModel.assetId)")
                return
            }

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
                    print("DEBUG: Fallback image loaded successfully")
                }
            }
        }
    }

    private func setupLoopingPlayer(url: URL) {
        playerLooper?.disableLooping()
        playerLooper = nil

        let playerItem = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        let looper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)

        player = queuePlayer
        playerLooper = looper
        queuePlayer.play()
    }
}

#Preview {
    let sample = ImageModel(
        assetId: "LOCAL_IDENTIFIER_DOES_NOT_EXIST",
        context: "Preview context",
        operationId: "preview-op-id",
        emotion: .neutral
    )

    return ReminiscenceTherapyView(imageModel: sample)
        .modelContainer(for: [ImageModel.self], inMemory: true)
}
