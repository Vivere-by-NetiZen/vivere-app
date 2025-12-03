//
//  VideoGenerationService.swift
//  vivere
//
//  Created for video generation integration
//

import Foundation
import UIKit

// Response from generate endpoint
struct VideoJobResponse: Codable {
    let operationId: String
    let prompt: String
    let status: String
    let progress: Int
}

// Response from status endpoint
struct VideoGenerationStatus: Codable {
    let status: String
    let operationId: String
}

enum VideoGenerationError: Error, LocalizedError {
    case invalidImage
    case encodingFailed
    case networkError(String)
    case serverError(Int)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image data"
        case .encodingFailed:
            return "Failed to encode image"
        case .networkError(let message):
            return "Network error: \(message)"
        case .serverError(let code):
            return "Server error: \(code)"
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
}

class VideoGenerationService {
    static let shared = VideoGenerationService()

    private let config = AppConfig.shared

    // Optimized URLSession for uploads
    private lazy var uploadSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 120
        configuration.waitsForConnectivity = false
        configuration.allowsCellularAccess = true
        configuration.httpMaximumConnectionsPerHost = 10
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil // Disable caching for uploads
        return URLSession(configuration: configuration)
    }()

    private init() {}

    /// Upload an image and generate a video job
    /// - Parameters:
    ///   - image: The UIImage to upload
    ///   - context: Optional context/prompt text
    /// - Returns: VideoJobResponse containing operation_id, prompt, status, and progress
    func generateVideo(from image: UIImage, context: String? = nil) async throws -> VideoJobResponse {
        let processStartTime = CFAbsoluteTimeGetCurrent()

        // 1. Prepare Image Data (Do this once, not in loop)
        let resizedImage = image.resized(toMaxDimension: 1536)

        let hasAlpha: Bool = {
            guard let cgImage = resizedImage.cgImage else { return false }
            let alphaInfo = cgImage.alphaInfo
            switch alphaInfo {
            case .first, .last, .premultipliedFirst, .premultipliedLast:
                return true
            default:
                return false
            }
        }()

        var imageData: Data?
        var mimeType: String
        var filename: String

        if hasAlpha {
            imageData = resizedImage.pngData()
            mimeType = "image/png"
            filename = "image.png"
        } else {
            if let jpeg = resizedImage.jpegData(compressionQuality: 0.85) {
                imageData = jpeg
                mimeType = "image/jpeg"
                filename = "image.jpg"
            } else {
                imageData = resizedImage.pngData()
                mimeType = "image/png"
                filename = "image.png"
            }
        }

        guard let finalImageData = imageData else {
            throw VideoGenerationError.invalidImage
        }

        // 2. Upload Loop with AsyncUtils
        return try await AsyncUtils.withRetry(
            timeout: 15 * 60, // Increase total timeout to 15 minutes for better persistence
            retryInterval: 5, // Start faster
            backoffFactor: 2.0, // Exponential backoff (5s, 10s, 20s, 40s...)
            operationDescription: "Video Upload",
            shouldRetry: { error in
                // Don't retry invalid image errors
                if let genError = error as? VideoGenerationError, case .invalidImage = genError {
                    return false
                }
                return true
            }
        ) {
            try await self.performUpload(
                imageData: finalImageData,
                mimeType: mimeType,
                filename: filename,
                context: context
            )
        }
    }

    private func performUpload(imageData: Data, mimeType: String, filename: String, context: String?) async throws -> VideoJobResponse {
        let startTime = CFAbsoluteTimeGetCurrent()
        let endpointURL = config.api("video/generate")

        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        let fieldName = "image"

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)

        // Add duration field (5 seconds)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"duration\"\r\n\r\n".data(using: .utf8)!)
        body.append("5\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        request.timeoutInterval = 60 // Increase timeout per request
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpShouldHandleCookies = false
        request.httpShouldUsePipelining = true

        let (data, response) = try await uploadSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw VideoGenerationError.invalidResponse
        }

        guard !data.isEmpty else {
            throw VideoGenerationError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            #if DEBUG
            print("❌ Video Generation Server Error: \(httpResponse.statusCode)")
            if let errorString = String(data: data, encoding: .utf8) {
                print("   Response Body: \(errorString)")
            }
            #endif
            throw VideoGenerationError.serverError(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            let statusResponse = try decoder.decode(VideoGenerationStatus.self, from: data)
            return VideoJobResponse(
                operationId: statusResponse.operationId,
                prompt: context ?? "",
                status: statusResponse.status,
                progress: 0
            )
        } catch {
            #if DEBUG
            print("Failed to decode response: \(error)")
            #endif
            throw VideoGenerationError.invalidResponse
        }
    }

    /// Check status of a video generation job
    func checkStatus(operationId: String) async throws -> VideoGenerationStatus {
        // Endpoint: /video/status/{operation_id}
        let url = config.api("video/status/\(operationId)")

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
            // Print server error details to console
            print("❌ Video Status Check Server Error:")
            print("   Status Code: \(statusCode)")
            print("   Operation ID: \(operationId)")
            print("   URL: \(url.absoluteString)")
            if let errorString = String(data: data, encoding: .utf8) {
                print("   Response Body: \(errorString)")
            } else {
                print("   Response Body: (unable to decode as UTF-8, \(data.count) bytes)")
            }
            if let httpURLResponse = response as? HTTPURLResponse,
               let allHeaders = httpURLResponse.allHeaderFields as? [String: Any] {
                print("   Response Headers: \(allHeaders)")
            }
            throw VideoGenerationError.serverError(statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(VideoGenerationStatus.self, from: data)
    }

    /// Get download URL for a video job
    func getVideoDownloadURL(operationId: String) -> URL {
        // Endpoint: /video/file/{operation_id}
        return config.api("video/file/\(operationId)")
    }
}

