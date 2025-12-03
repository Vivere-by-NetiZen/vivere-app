//
//  VideoDownloadService.swift
//  vivere
//
//  Background service for downloading completed videos
//

import Foundation
import SwiftData
import Photos
import UIKit

enum VideoDownloadError: Error, LocalizedError {
    case invalidJobId
    case downloadFailed(String)
    case fileSystemError(String)
    case videoNotReady

    var errorDescription: String? {
        switch self {
        case .invalidJobId:
            return "Invalid job ID"
        case .downloadFailed(let message):
            return "Download failed: \(message)"
        case .fileSystemError(let message):
            return "File system error: \(message)"
        case .videoNotReady:
            return "Video is not ready for download"
        }
    }
}

class VideoDownloadService {
    static let shared = VideoDownloadService()

    private let config = AppConfig.shared
    private let fileManager = FileManager.default
    private var downloadTasks: [String: Task<Void, Never>] = [:]

    // Directory for storing downloaded videos
    private var videosDirectory: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videosDir = documentsPath.appendingPathComponent("Videos", isDirectory: true)

        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: videosDir.path) {
            try? fileManager.createDirectory(at: videosDir, withIntermediateDirectories: true)
        }

        return videosDir
    }

    private init() {}

    /// Get the local file path for a video by operation ID
    func videoFilePath(for operationId: String) -> URL {
        return videosDirectory.appendingPathComponent("\(operationId).mp4")
    }

    /// Check if video is downloaded locally
    func isVideoDownloaded(operationId: String) -> Bool {
        let filePath = videoFilePath(for: operationId)
        return fileManager.fileExists(atPath: filePath.path)
    }

    /// Get local video URL if downloaded
    func getLocalVideoURL(operationId: String) -> URL? {
        guard isVideoDownloaded(operationId: operationId) else { return nil }
        return videoFilePath(for: operationId)
    }

    /// Start monitoring and downloading video for a operation ID
    func startMonitoring(operationId: String) {
        // Skip if already monitoring or already downloaded
        guard downloadTasks[operationId] == nil,
              !isVideoDownloaded(operationId: operationId) else {
            return
        }

        let task = Task<Void, Never> { [weak self] in
            guard let self = self else { return }
            await self.monitorAndDownload(operationId: operationId)
        }

        downloadTasks[operationId] = task
    }

    /// Stop monitoring a specific job
    func stopMonitoring(operationId: String) {
        downloadTasks[operationId]?.cancel()
        downloadTasks.removeValue(forKey: operationId)
    }

    /// Monitor video status via polling and download when ready
    private func monitorAndDownload(operationId: String) async {
        // Initial fast poll (every 5s) for 3 minutes
        let fastPollInterval: UInt64 = 5
        let fastPollDuration: Int = 3 * 60
        let fastPollMaxRetries = fastPollDuration / Int(fastPollInterval)

        // Slower poll (every 15s) for remaining time up to 15 minutes total
        let slowPollInterval: UInt64 = 15
        let totalTimeout: Int = 15 * 60
        let remainingTime = totalTimeout - fastPollDuration
        let slowPollMaxRetries = remainingTime / Int(slowPollInterval)

        var retryCount = 0
        var currentInterval = fastPollInterval
        var isSlowPhase = false

        while retryCount < (fastPollMaxRetries + slowPollMaxRetries) {
            if Task.isCancelled { return }

            do {
                let status = try await VideoGenerationService.shared.checkStatus(operationId: operationId)
                let statusLower = status.status.lowercased()

                if statusLower == "completed" {
                    await downloadVideo(operationId: operationId)
                    stopMonitoring(operationId: operationId)
                    return
                } else if statusLower == "failed" || statusLower == "error" {
                    #if DEBUG
                    print("Video generation failed for operation \(operationId)")
                    #endif
                    stopMonitoring(operationId: operationId)
                    return
                }

                // Check if we should switch to slow polling
                if !isSlowPhase && retryCount >= fastPollMaxRetries {
                    isSlowPhase = true
                    currentInterval = slowPollInterval
                    #if DEBUG
                    print("Switching to slow polling for operation \(operationId)")
                    #endif
                }

                // Wait before next poll
                try await Task.sleep(nanoseconds: currentInterval * 1_000_000_000)
                retryCount += 1

            } catch {
                #if DEBUG
                print("Error checking status for \(operationId): \(error)")
                #endif
                // Wait a bit longer on error
                try? await Task.sleep(nanoseconds: 10 * 1_000_000_000)
                retryCount += 1
            }
        }

        // Timeout
        stopMonitoring(operationId: operationId)
    }

    /// Download video from server
    func downloadVideo(operationId: String) async {
        // Skip if already downloaded
        guard !isVideoDownloaded(operationId: operationId) else {
            #if DEBUG
            print("Video already downloaded for operation \(operationId)")
            #endif
            return
        }

        let downloadURL = VideoGenerationService.shared.getVideoDownloadURL(operationId: operationId)
        let filePath = videoFilePath(for: operationId)

        #if DEBUG
        print("📥 Starting download for operation \(operationId)...")
        #endif

        do {
            try await AsyncUtils.withRetry(
                timeout: 5 * 60,
                retryInterval: 10,
                operationDescription: "Download Video \(operationId)"
            ) {
                let (data, response) = try await URLSession.shared.data(from: downloadURL)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw VideoDownloadError.downloadFailed("Invalid response")
                }

                guard (200..<300).contains(httpResponse.statusCode) else {
                    throw VideoDownloadError.downloadFailed("HTTP \(httpResponse.statusCode)")
                }

                // Download to a temporary file first to avoid corruption
                let tempURL = self.fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                try data.write(to: tempURL)

                // Move to final destination
                if self.fileManager.fileExists(atPath: filePath.path) {
                    try? self.fileManager.removeItem(at: filePath)
                }
                try self.fileManager.moveItem(at: tempURL, to: filePath)

                #if DEBUG
                let fileSizeMB = Double(data.count) / (1024 * 1024)
                print("✅ Video downloaded successfully for operation \(operationId) (\(String(format: "%.2f", fileSizeMB)) MB)")
                #endif
            }

            // Notify that download completed
            NotificationCenter.default.post(
                name: .videoDownloadCompleted,
                object: nil,
                userInfo: ["operationId": operationId]
            )

        } catch {
            #if DEBUG
            print("❌ Failed to download video for operation \(operationId) after retries: \(error.localizedDescription)")
            #endif

            NotificationCenter.default.post(
                name: .videoDownloadFailed,
                object: nil,
                userInfo: ["operationId": operationId, "error": error.localizedDescription]
            )
        }
    }

    /// Start monitoring all videos from ImageModels
    func startMonitoringAll(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<ImageModel>()

        do {
            let images = try modelContext.fetch(descriptor)
            for image in images {
                if let operationId = image.operationId {
                    // Skip if currently uploading
                    if operationId == "PENDING_UPLOAD" {
                        continue
                    }
                    startMonitoring(operationId: operationId)
                } else {
                    // Case where image exists but upload hasn't started/finished
                    // We'll try to re-upload these in background if needed
                    Task {
                        await reuploadImageIfNeeded(image, modelContext: modelContext)
                    }
                }
            }
        } catch {
            #if DEBUG
            print("Failed to fetch ImageModels: \(error)")
            #endif
        }
    }

    private func reuploadImageIfNeeded(_ imageModel: ImageModel, modelContext: ModelContext) async {
        guard imageModel.operationId == nil else { return }

        // Double check if it's pending (in case it changed since check)
        if imageModel.operationId == "PENDING_UPLOAD" { return }

        // Use PhotosSelectionService to get the image efficiently?
        // Or just re-fetch PHAsset here. Since we are in a background service, simpler is better.

        // We need to be careful not to create retain cycles or thread issues
        let assetId = imageModel.assetId
        let context = imageModel.context

        // Verify asset exists
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
        guard let asset = assets.firstObject else { return }

        // Load UIImage
        let options = PHImageRequestOptions()
        options.version = .original
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false

        let image: UIImage? = await withCheckedContinuation { continuation in
            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                if let data, let img = UIImage(data: data) {
                    continuation.resume(returning: img)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }

        guard let validImage = image else { return }

        #if DEBUG
        print("🔄 Re-uploading missing video job for asset: \(assetId)")
        #endif

        do {
            let response = try await VideoGenerationService.shared.generateVideo(from: validImage, context: context)

            // Safely update SwiftData on MainActor
            // We need to re-fetch the model on MainActor since the passed `imageModel` might be from a different context/thread
            await MainActor.run {
                // Re-fetch the object to ensure thread safety and validity
                let descriptor = FetchDescriptor<ImageModel>(predicate: #Predicate { $0.assetId == assetId })
                if let freshModel = try? modelContext.fetch(descriptor).first {
                    freshModel.operationId = response.operationId
                    try? modelContext.save()

                    // Start monitoring the new job
                    self.startMonitoring(operationId: response.operationId)
                }
            }
        } catch {
            #if DEBUG
            print("❌ Failed to re-upload image for video generation: \(error)")
            #endif
        }
    }

    deinit {
        // Cancel all tasks
        downloadTasks.values.forEach { $0.cancel() }
    }
}

// Notification names for video download events
extension Notification.Name {
    static let videoDownloadCompleted = Notification.Name("videoDownloadCompleted")
    static let videoDownloadFailed = Notification.Name("videoDownloadFailed")
}
