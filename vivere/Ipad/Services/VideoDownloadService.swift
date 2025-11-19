//
//  VideoDownloadService.swift
//  vivere
//
//  Background service for downloading completed videos
//

import Foundation
import SwiftData

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
        let maxRetries = 60 // 5 minutes (assuming 5s interval)
        var retryCount = 0

        while retryCount < maxRetries {
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

                // Wait before next poll
                try await Task.sleep(nanoseconds: 15 * 1_000_000_000)
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
            let (data, response) = try await URLSession.shared.data(from: downloadURL)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw VideoDownloadError.downloadFailed("Invalid response")
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                throw VideoDownloadError.downloadFailed("HTTP \(httpResponse.statusCode)")
            }

            // Save video to file
            try data.write(to: filePath)

            #if DEBUG
            let fileSizeMB = Double(data.count) / (1024 * 1024)
            print("✅ Video downloaded successfully for operation \(operationId) (\(String(format: "%.2f", fileSizeMB)) MB)")
            #endif

            // Notify that download completed
            NotificationCenter.default.post(
                name: .videoDownloadCompleted,
                object: nil,
                userInfo: ["operationId": operationId]
            )

        } catch {
            #if DEBUG
            print("❌ Failed to download video for operation \(operationId): \(error)")
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
                    startMonitoring(operationId: operationId)
                }
            }
        } catch {
            #if DEBUG
            print("Failed to fetch ImageModels: \(error)")
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
