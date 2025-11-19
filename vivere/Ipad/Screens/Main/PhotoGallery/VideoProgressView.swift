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

    private var monitoringTasks: [Task<Void, Never>] = []

    init(images: [ImageModel]) {
        self.items = images.map { VideoProgressItem(imageModel: $0) }
        startMonitoring()
    }

    func startMonitoring() {
        cancelMonitoring()

        let task = Task {
            isLoading = true

            await withTaskGroup(of: Void.self) { group in
                for index in items.indices {
                    // Check operationId first, fallback to jobId
                    let opId = items[index].imageModel.operationId ?? items[index].imageModel.jobId
                    guard let operationId = opId else { continue }

                    group.addTask { [weak self] in
                        await self?.monitorJob(index: index, operationId: operationId)
                    }
                }
            }

            isLoading = false
        }
        monitoringTasks.append(task)
    }

    private func monitorJob(index: Int, operationId: String) async {
        while !Task.isCancelled {
            do {
                let status = try await VideoGenerationService.shared.checkStatus(operationId: operationId)
                let statusLower = status.status.lowercased()

                await MainActor.run {
                    if index < items.count {
                        items[index].status = status.status

                        if statusLower == "completed" {
                            items[index].progress = 100
                            items[index].videoUrl = VideoGenerationService.shared.getVideoDownloadURL(operationId: operationId).absoluteString
                        } else if statusLower == "failed" || statusLower == "error" {
                            items[index].error = "Video generation failed"
                        }
                    }
                }

                if statusLower == "completed" || statusLower == "failed" || statusLower == "error" {
                    return
                }

                try await Task.sleep(nanoseconds: 5 * 1_000_000_000)

            } catch {
                #if DEBUG
                print("Failed to check status for \(operationId): \(error)")
                #endif
                try? await Task.sleep(nanoseconds: 10 * 1_000_000_000)
            }
        }
    }

    func cancelMonitoring() {
        monitoringTasks.forEach { $0.cancel() }
        monitoringTasks.removeAll()
    }

    deinit {
        // Tasks are cancelled automatically when self is deallocated due to [weak self]
    }
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

                if viewModel.isLoading && viewModel.items.isEmpty {
                    ProgressView()
                        .tint(.white)
                } else if viewModel.items.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "video.slash")
                            .font(.largeTitle)
                            .imageScale(.large)
                            .foregroundColor(.white.opacity(0.7))
                        Text("Tidak ada video yang sedang dibuat")
                            .font(.title3)
                            .fontWeight(.semibold)
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
                        viewModel.cancelMonitoring()
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onDisappear {
                viewModel.cancelMonitoring()
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
        case "error", "failed":
            return .red
        case "running", "queued", "processing":
            return .blue
        default:
            return .gray
        }
    }

    var statusText: String {
        switch item.status {
        case "completed":
            return "Selesai"
        case "error", "failed":
            return "Error"
        case "running", "processing":
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
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)

                HStack {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 12, height: 12)

                    Text(statusText)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                }

                if item.status == "running" || item.status == "queued" || item.status == "processing" {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)

                    Text("Mohon tunggu...")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }

                if let error = item.error {
                    Text(error)
                        .font(.callout)
                        .foregroundColor(.red.opacity(0.9))
                        .lineLimit(2)
                }

                if item.status == "completed" {
                    Button {
                        Task {
                            let opId = item.imageModel.operationId ?? item.imageModel.jobId
                            guard let operationId = opId else { return }
                            await VideoDownloadService.shared.downloadVideo(operationId: operationId)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                            Text("Unduh Video")
                        }
                        .font(.body)
                        .fontWeight(.semibold)
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
