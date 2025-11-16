//
//  VideoGenerationService.swift
//  vivere
//
//  Created for video generation integration
//

import Foundation
import UIKit

struct VideoJobResponse: Codable {
    let job_id: String
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

    private init() {}

    /// Upload an image and generate a video job
    /// - Parameters:
    ///   - image: The UIImage to upload
    ///   - context: Optional context/prompt text (currently not used by backend, but may be useful in future)
    /// - Returns: VideoJobResponse containing job_id, prompt, status, and progress
    func generateVideo(from image: UIImage, context: String? = nil) async throws -> VideoJobResponse {
        // Determine image format and encode
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

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw VideoGenerationError.invalidResponse
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                throw VideoGenerationError.serverError(httpResponse.statusCode)
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let videoJob = try decoder.decode(VideoJobResponse.self, from: data)

            return videoJob
        } catch let error as VideoGenerationError {
            throw error
        } catch {
            throw VideoGenerationError.networkError(error.localizedDescription)
        }
    }
}

