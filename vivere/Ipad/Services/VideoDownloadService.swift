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
    private var webSocketServices: [String: VideoStatusWebSocketService] = [:]

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

    /// Get the local file path for a video by job ID
    func videoFilePath(for jobId: String) -> URL {
        return videosDirectory.appendingPathComponent("\(jobId).mp4")
    }

    /// Check if video is downloaded locally
    func isVideoDownloaded(jobId: String) -> Bool {
        let filePath = videoFilePath(for: jobId)
        return fileManager.fileExists(atPath: filePath.path)
    }

    /// Get local video URL if downloaded
    func getLocalVideoURL(jobId: String) -> URL? {
        guard isVideoDownloaded(jobId: jobId) else { return nil }
        return videoFilePath(for: jobId)
    }

    /// Start monitoring and downloading video for a job ID
    func startMonitoring(jobId: String) {
        // Skip if already monitoring or already downloaded
        guard downloadTasks[jobId] == nil,
              !isVideoDownloaded(jobId: jobId) else {
            return
        }

        let task = Task<Void, Never> { [weak self] in
            guard let self = self else { return }
            await self.monitorAndDownload(jobId: jobId)
        }

        downloadTasks[jobId] = task
    }

    /// Stop monitoring a specific job
    func stopMonitoring(jobId: String) {
        downloadTasks[jobId]?.cancel()
        downloadTasks.removeValue(forKey: jobId)
        webSocketServices[jobId]?.disconnect()
        webSocketServices.removeValue(forKey: jobId)
    }

    /// Monitor video status via WebSocket and download when ready
    private func monitorAndDownload(jobId: String) async {
        // First check if video is already completed
        if await checkAndDownloadIfReady(jobId: jobId) {
            return
        }

        // Set up WebSocket monitoring
        let service = VideoStatusWebSocketService(jobId: jobId)
        let delegate = VideoDownloadDelegate(jobId: jobId, service: self)

        webSocketServices[jobId] = service
        service.connect(delegate: delegate)
    }

    /// Check status and download if ready (polling fallback)
    private func checkAndDownloadIfReady(jobId: String) async -> Bool {
        let url = config.api("generate_video/\(jobId)/status")

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
                return false
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let statusResponse = try decoder.decode(VideoStatusResponse.self, from: data)

            if statusResponse.status == "completed", statusResponse.videoUrl != nil {
                await downloadVideo(jobId: jobId)
                return true
            }

            return false
        } catch {
            #if DEBUG
            print("Failed to check status for \(jobId): \(error)")
            #endif
            return false
        }
    }

    /// Download video from server
    func downloadVideo(jobId: String) async {
        // Skip if already downloaded
        guard !isVideoDownloaded(jobId: jobId) else {
            #if DEBUG
            print("Video already downloaded for job \(jobId)")
            #endif
            return
        }

        let downloadURL = config.api("generate_video/\(jobId)/download")
        let filePath = videoFilePath(for: jobId)

        #if DEBUG
        print("📥 Starting download for job \(jobId)...")
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
            print("✅ Video downloaded successfully for job \(jobId) (\(String(format: "%.2f", fileSizeMB)) MB)")
            #endif

            // Notify that download completed
            NotificationCenter.default.post(
                name: .videoDownloadCompleted,
                object: nil,
                userInfo: ["jobId": jobId]
            )

        } catch {
            #if DEBUG
            print("❌ Failed to download video for job \(jobId): \(error)")
            #endif

            NotificationCenter.default.post(
                name: .videoDownloadFailed,
                object: nil,
                userInfo: ["jobId": jobId, "error": error.localizedDescription]
            )
        }
    }

    /// Start monitoring all videos from ImageModels
    func startMonitoringAll(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<ImageModel>()

        do {
            let images = try modelContext.fetch(descriptor)
            for image in images {
                if let jobId = image.jobId {
                    startMonitoring(jobId: jobId)
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
        webSocketServices.values.forEach { $0.disconnect() }
    }
}

// Delegate for WebSocket status updates
private class VideoDownloadDelegate: VideoStatusWebSocketDelegate {
    let jobId: String
    weak var service: VideoDownloadService?

    init(jobId: String, service: VideoDownloadService) {
        self.jobId = jobId
        self.service = service
    }

    func didReceiveStatus(jobId: String, status: String, progress: Int, videoUrl: String?) {
        if status == "completed", videoUrl != nil {
            Task {
                await service?.downloadVideo(jobId: jobId)
                service?.stopMonitoring(jobId: jobId)
            }
        }
    }

    func didReceiveError(jobId: String, error: String) {
        #if DEBUG
        print("WebSocket error for job \(jobId): \(error)")
        #endif
        service?.stopMonitoring(jobId: jobId)
    }

    func didComplete(jobId: String, status: String) {
        if status == "completed" {
            Task {
                await service?.downloadVideo(jobId: jobId)
            }
        }
        service?.stopMonitoring(jobId: jobId)
    }
}

// Notification names for video download events
extension Notification.Name {
    static let videoDownloadCompleted = Notification.Name("videoDownloadCompleted")
    static let videoDownloadFailed = Notification.Name("videoDownloadFailed")
}

