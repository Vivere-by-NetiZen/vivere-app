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
        let startTime = CFAbsoluteTimeGetCurrent()

        // Determine image format and encode
        let encodeStartTime = CFAbsoluteTimeGetCurrent()
        let hasAlpha: Bool = {
            guard let cgImage = image.cgImage else { return false }
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
            imageData = image.pngData()
            mimeType = "image/png"
            filename = "image.png"
        } else {
            if let jpeg = image.jpegData(compressionQuality: 0.8) {
                imageData = jpeg
                mimeType = "image/jpeg"
                filename = "image.jpg"
            } else {
                imageData = image.pngData()
                mimeType = "image/png"
                filename = "image.png"
            }
        }

        guard let imageData = imageData else {
            throw VideoGenerationError.invalidImage
        }

        let encodeDuration = CFAbsoluteTimeGetCurrent() - encodeStartTime
        let imageSizeMB = Double(imageData.count) / (1024 * 1024)
        #if DEBUG
        print("  ⏱️ Image encoding took \(String(format: "%.3f", encodeDuration))s")
        print("  📦 Image size: \(String(format: "%.2f", imageSizeMB)) MB (\(imageData.count) bytes)")
        #endif

        // New endpoint: /video/generate
        let endpointURL = config.api("video/generate")

        // Create multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        let fieldName = "image"

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)

        // Add duration field (4 seconds)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"duration\"\r\n\r\n".data(using: .utf8)!)
        body.append("4\r\n".data(using: .utf8)!)

        // Add prompt field if context is provided
        if let context = context, !context.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(context)\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        request.timeoutInterval = 60
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpShouldHandleCookies = false
        request.httpShouldUsePipelining = true

        let networkStartTime = CFAbsoluteTimeGetCurrent()
        #if DEBUG
        print("  📤 Uploading \(String(format: "%.2f", Double(imageData.count) / (1024 * 1024))) MB image...")
        #endif
        do {
            let (data, response) = try await uploadSession.data(for: request)
            let totalNetworkDuration = CFAbsoluteTimeGetCurrent() - networkStartTime

            guard let httpResponse = response as? HTTPURLResponse else {
                throw VideoGenerationError.invalidResponse
            }

            #if DEBUG
            print("  ⏱️ Total network time: \(String(format: "%.3f", totalNetworkDuration))s")
            print("  📥 Response status: \(httpResponse.statusCode)")
            #endif

            guard !data.isEmpty else {
                throw VideoGenerationError.invalidResponse
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                #if DEBUG
                if let errorString = String(data: data, encoding: .utf8) {
                    print("Server error response: \(errorString)")
                }
                #endif
                throw VideoGenerationError.serverError(httpResponse.statusCode)
            }

            let decodeStartTime = CFAbsoluteTimeGetCurrent()
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            do {
                // Decode new response format
                let statusResponse = try decoder.decode(VideoGenerationStatus.self, from: data)

                let decodeDuration = CFAbsoluteTimeGetCurrent() - decodeStartTime
                let totalDuration = CFAbsoluteTimeGetCurrent() - startTime
                #if DEBUG
                print("  ⏱️ JSON decoding took \(String(format: "%.3f", decodeDuration))s")
                print("  ⏱️ Total upload time: \(String(format: "%.3f", totalDuration))s")
                #endif

                // Map to VideoJobResponse for compatibility
                return VideoJobResponse(
                    operationId: statusResponse.operationId,
                    prompt: context ?? "",
                    status: statusResponse.status,
                    progress: 0
                )
            } catch let decodingError {
                #if DEBUG
                print("Failed to decode response: \(decodingError)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response body: \(responseString)")
                }
                #endif
                throw VideoGenerationError.invalidResponse
            }
        } catch let error as VideoGenerationError {
            throw error
        } catch {
            #if DEBUG
            print("Network request error: \(error)")
            #endif
            throw VideoGenerationError.networkError(error.localizedDescription)
        }
    }

    /// Check status of a video generation job
    func checkStatus(operationId: String) async throws -> VideoGenerationStatus {
        // Endpoint: /video/status/{operation_id}
        let url = config.api("video/status/\(operationId)")

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw VideoGenerationError.serverError((response as? HTTPURLResponse)?.statusCode ?? 500)
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
