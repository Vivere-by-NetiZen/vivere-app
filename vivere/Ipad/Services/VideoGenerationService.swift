//
//  VideoGenerationService.swift
//  vivere
//
//  Created for video generation integration
//

import Foundation
import UIKit

struct VideoJobResponse: Codable {
    let jobId: String
    let prompt: String
    let status: String
    let progress: Int
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
    ///   - context: Optional context/prompt text (currently not used by backend, but may be useful in future)
    /// - Returns: VideoJobResponse containing job_id, prompt, status, and progress
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

        let endpointURL = config.api("generate_video")

        // Create multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        let fieldName = "image"

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
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

            // Try to estimate upload vs backend processing time
            // Note: This is approximate - actual upload time is hard to measure separately
            guard let httpResponse = response as? HTTPURLResponse else {
                throw VideoGenerationError.invalidResponse
            }

            #if DEBUG
            // Estimate: If response is small (<10KB), most time was backend processing
            // If response is large, some time was downloading
            let responseSizeKB = Double(data.count) / 1024
            let estimatedBackendTime = totalNetworkDuration * 0.85 // Rough estimate: ~85% is backend processing
            let estimatedUploadTime = totalNetworkDuration - estimatedBackendTime

            print("  ⏱️ Total network time: \(String(format: "%.3f", totalNetworkDuration))s")
            print("  ⏱️ Estimated upload time: ~\(String(format: "%.3f", estimatedUploadTime))s")
            print("  ⏱️ Estimated backend processing: ~\(String(format: "%.3f", estimatedBackendTime))s")
            print("  📥 Response size: \(String(format: "%.2f", responseSizeKB)) KB")

            if estimatedUploadTime > 0 {
                let uploadSpeedMBps = Double(imageData.count) / (1024 * 1024) / estimatedUploadTime
                print("  📊 Estimated upload speed: \(String(format: "%.2f", uploadSpeedMBps)) MB/s")
            }
            #endif

            // Check if response is empty
            guard !data.isEmpty else {
                #if DEBUG
                print("Empty response from server. Status code: \(httpResponse.statusCode)")
                #endif
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
                let videoJob = try decoder.decode(VideoJobResponse.self, from: data)

                let decodeDuration = CFAbsoluteTimeGetCurrent() - decodeStartTime
                let totalDuration = CFAbsoluteTimeGetCurrent() - startTime
                #if DEBUG
                print("  ⏱️ JSON decoding took \(String(format: "%.3f", decodeDuration))s")
                print("  ⏱️ Total upload time: \(String(format: "%.3f", totalDuration))s")
                #endif

                return videoJob
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
}

