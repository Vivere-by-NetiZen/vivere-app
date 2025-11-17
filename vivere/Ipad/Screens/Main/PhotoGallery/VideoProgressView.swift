//
//  VideoProgressView.swift
//  vivere
//
//  View showing video generation progress for all images
//

import SwiftUI
import SwiftData
import Photos
import Observation

struct VideoProgressItem: Identifiable {
    let id: UUID
    let imageModel: ImageModel
    var status: String
    var progress: Int
    var videoUrl: String?
    var error: String?

    init(imageModel: ImageModel) {
        self.id = imageModel.id
        self.imageModel = imageModel
        self.status = "unknown"
        self.progress = 0
        self.videoUrl = nil
        self.error = nil
    }
}

@MainActor
@Observable
final class VideoProgressViewModel {
    var items: [VideoProgressItem] = []
    var isLoading = true

    // WebSocket services can be accessed from nonisolated context for cleanup
    nonisolated(unsafe) private var webSocketServices: [UUID: VideoStatusWebSocketService] = [:]

    init(images: [ImageModel]) {
        self.items = images.map { VideoProgressItem(imageModel: $0) }
        loadInitialStatus()
    }

    func loadInitialStatus() {
        Task {
            isLoading = true

            // Load initial status for all items
            await withTaskGroup(of: Void.self) { group in
                for index in items.indices {
                    guard let jobId = items[index].imageModel.jobId else { continue }

                    group.addTask { [weak self] in
                        await self?.checkStatus(for: index, jobId: jobId)
                    }
                }
            }

            // Connect WebSocket for items that are not completed
            for index in items.indices {
                guard let jobId = items[index].imageModel.jobId else { continue }
                if items[index].status != "completed" && items[index].status != "error" {
                    connectWebSocket(for: index, jobId: jobId)
                }
            }

            isLoading = false
        }
    }

    private func checkStatus(for index: Int, jobId: String) async {
        let config = AppConfig.shared
        let url = config.api("generate_video/\(jobId)/status")

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
                return
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let statusResponse = try decoder.decode(VideoStatusResponse.self, from: data)

            await MainActor.run {
                if index < items.count {
                    items[index].status = statusResponse.status
                    items[index].progress = statusResponse.progress
                    items[index].videoUrl = statusResponse.videoUrl
                    items[index].error = statusResponse.error
                }
            }
        } catch {
            #if DEBUG
            print("Failed to check status for \(jobId): \(error)")
            #endif
        }
    }

    private func connectWebSocket(for index: Int, jobId: String) {
        let itemId = items[index].id

        // Create a new service instance for this job
        let service = VideoStatusWebSocketService(jobId: jobId)

        // Create a delegate wrapper for this specific item
        let delegate = VideoProgressItemDelegate(
            itemId: itemId,
            viewModel: self
        )

        webSocketServices[itemId] = service
        service.connect(delegate: delegate)
    }

    func updateItem(itemId: UUID, status: String, progress: Int, videoUrl: String?) {
        if let index = items.firstIndex(where: { $0.id == itemId }) {
            items[index].status = status
            items[index].progress = progress
            items[index].videoUrl = videoUrl
        }
    }

    func updateItemError(itemId: UUID, error: String) {
        if let index = items.firstIndex(where: { $0.id == itemId }) {
            items[index].status = "error"
            items[index].error = error
        }
    }

    nonisolated func disconnectAll() {
        // WebSocket cleanup doesn't require main actor isolation
        webSocketServices.values.forEach { $0.disconnect() }
        webSocketServices.removeAll()
    }

    deinit {
        disconnectAll()
    }
}

// Helper class to bridge delegate calls to view model
private class VideoProgressItemDelegate: VideoStatusWebSocketDelegate {
    let itemId: UUID
    weak var viewModel: VideoProgressViewModel?

    init(itemId: UUID, viewModel: VideoProgressViewModel) {
        self.itemId = itemId
        self.viewModel = viewModel
    }

    func didReceiveStatus(jobId: String, status: String, progress: Int, videoUrl: String?) {
        viewModel?.updateItem(itemId: itemId, status: status, progress: progress, videoUrl: videoUrl)
    }

    func didReceiveError(jobId: String, error: String) {
        viewModel?.updateItemError(itemId: itemId, error: error)
    }

    func didComplete(jobId: String, status: String) {
        // Status already updated via didReceiveStatus
    }
}

struct VideoStatusResponse: Codable {
    let jobId: String
    let status: String
    let progress: Int
    let videoUrl: String?
    let error: String?
}

struct VideoProgressView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: VideoProgressViewModel

    let images: [ImageModel]

    init(images: [ImageModel]) {
        self.images = images
        _viewModel = State(initialValue: VideoProgressViewModel(images: images))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.viverePrimary.ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else if viewModel.items.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "video.slash")
                            .font(.system(size: 64))
                            .foregroundColor(.white.opacity(0.7))
                        Text("Tidak ada video yang sedang dibuat")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            ForEach(viewModel.items) { item in
                                VideoProgressRow(item: item)
                            }
                        }
                        .padding(.vertical, 32)
                        .padding(.horizontal, 40)
                    }
                }
            }
            .navigationTitle("Progress Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Tutup") {
                        viewModel.disconnectAll()
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onDisappear {
                viewModel.disconnectAll()
            }
        }
    }
}

struct VideoProgressRow: View {
    let item: VideoProgressItem
    @State private var thumbnail: UIImage?

    var statusColor: Color {
        switch item.status {
        case "completed":
            return .green
        case "error":
            return .red
        case "running", "queued":
            return .blue
        default:
            return .gray
        }
    }

    var statusText: String {
        switch item.status {
        case "completed":
            return "Selesai"
        case "error":
            return "Error"
        case "running":
            return "Sedang dibuat"
        case "queued":
            return "Menunggu"
        default:
            return "Tidak diketahui"
        }
    }

    var body: some View {
        HStack(spacing: 24) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 120, height: 120)

                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipped()
                        .cornerRadius(16)
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 12) {
                Text(item.imageModel.context?.isEmpty == false ? item.imageModel.context! : "Foto tanpa konteks")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)

                HStack {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 12, height: 12)

                    Text(statusText)
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.9))
                }

                if item.status == "running" || item.status == "queued" {
                    ProgressView(value: Double(item.progress), total: 100)
                        .tint(.white)

                    Text("\(item.progress)%")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                }

                if let error = item.error {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.red.opacity(0.9))
                        .lineLimit(2)
                }

                if item.status == "completed", let videoUrl = item.videoUrl {
                    Button {
                        // Video download functionality can be added here later
                        // Use videoUrl to download video from backend
                    } label: {
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                            Text("Unduh Video")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.accent)
                        .cornerRadius(8)
                    }
                }
            }

            Spacer()
        }
        .padding(24)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
        .task {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        guard thumbnail == nil else { return }
        guard PHPhotoLibrary.authorizationStatus(for: .readWrite) == .authorized ||
              PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited else { return }

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [item.imageModel.assetId], options: nil)
        guard let asset = assets.firstObject else { return }

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true

        let image = await withCheckedContinuation { continuation in
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 240, height: 240),
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }

        await MainActor.run {
            thumbnail = image
        }
    }
}

#Preview {
    VideoProgressView(images: [])
}

