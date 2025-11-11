import Foundation
import UIKit
import Combine

@MainActor
@Observable
final class SpeechTranscriberViewModel: SpeechTranscriberDelegate {
    var urlString: String = "wss://presymphonic-preexclusively-kaylene.ngrok-free.dev/ws/audio"
    var isStreaming: Bool = false
    var status: String = "idle"
    var level: Float = 0
    var bytesSent: Int64 = 0
    var logs: [String] = []
    var partialTranscript: String = ""
    var finalTranscripts: [String] = []
    var suggestions: [String] = []
    var errorMessage: String?
    var isFetchingSuggestion: Bool = false
    var suggestionPoint: Int?
    var isPaused: Bool = false
    var suggested = false

    // New state for initial questions
    var initialQuestion: String = ""
    var isFetchingInitialQuestions: Bool = false
    
    // Use the shared instance so the visualizer (which reads MicStreamer.shared) sees updates.
    private let streamer = SpeechTranscriber.shared

    init() {
        streamer.delegate = self
    }

    func toggle(resume: Bool) {
        print("isStreaming \(isStreaming)")
        if isStreaming {
            stop(resume: resume)
        } else {
            start(resume: resume)
        }
    }
    
    func pauseStream() {
        streamer.pause()
        isPaused = true
    }
    
    func resumeStream() {
        do {
            guard let url = URL(string: urlString) else {
                print("invalid URL")
                return
            }
            try streamer.resume(url: url)
            isPaused = false
            suggested = false
        } catch {
            // Surface the error to UI; keep paused state unchanged on failure
            errorMessage = "Failed to resume: \(error.localizedDescription)"
            status = "error"
        }
    }

    func start(resume: Bool) {
        guard let url = URL(string: urlString) else {
            print("invalid URL")
            return
        }
        isStreaming = true
        if resume {
            resumeStream()
            return
        }

        partialTranscript = ""
        finalTranscripts.removeAll()
        isPaused = false
        suggested = false

        do {
            try streamer.start(url: url)
            // Set streaming true after we successfully kick off start()
            isStreaming = true
        } catch {
            print("start error: \(error.localizedDescription)")
            status = "error"
            isStreaming = false
        }
    }

    func stop(resume: Bool) {
        isStreaming = false
        if resume {
            print("Masuk")
            pauseStream()
            getSuggestions()
            return
        }
        streamer.stop()
    }
    
    func getSuggestions(from urlString: String = "https://presymphonic-preexclusively-kaylene.ngrok-free.dev/suggestions") {
        suggestions.removeAll()
        suggestionPoint = nil
        errorMessage = nil
        
        let transcript = partialTranscript + finalTranscripts.joined(separator: " ")
        
        guard !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Transcript is empty."
            return
        }
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid server URL."
            return
        }
        isFetchingSuggestion = true
        let payload = ["transcript": transcript]
        do {
            let body = try JSONSerialization.data(withJSONObject: payload, options: [])
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = body
            
            Task { [weak self] in
                do {
                    let (data, resp) = try await URLSession.shared.data(for: req)
                    guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                        await MainActor.run { self?.errorMessage = "Server error."; self?.isFetchingSuggestion = false }
                        return
                    }
                    let decoded = try JSONDecoder().decode(SuggestionResponse.self, from: data)
                    await MainActor.run {
                        self?.suggestions = decoded.suggestions
                        self?.isFetchingSuggestion = false
                        self?.suggested = true
                    }
                } catch {
                    await MainActor.run {
                        self?.errorMessage = "Failed to fetch suggestions: \(error.localizedDescription)"
                        self?.isFetchingSuggestion = false
                    }
                }
            }
        } catch {
            self.errorMessage = "Failed to build request: \(error.localizedDescription)"
            self.isFetchingSuggestion = false
        }
    }
    
    func getInitialQuestion(image: UIImage, from urlString: String = "https://presymphonic-preexclusively-kaylene.ngrok-free.dev/initial-questions") {
        // Reset previous state
        initialQuestion.removeAll()
        errorMessage = nil
        
        // Choose encoding dynamically: prefer JPEG for non-alpha images; fall back to PNG
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
            // Preserve transparency with PNG
            imageData = image.pngData()
            mimeType = "image/png"
            filename = "image.png"
        } else {
            // Try JPEG first for better size; fall back to PNG if JPEG fails
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
        
        guard let imageData else {
            errorMessage = "Failed to encode image."
            return
        }
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid server URL."
            return
        }
        
        // Build multipart/form-data body
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        
        // Adjust fieldName to match your FastAPI parameter (e.g., "file" or "image")
        let fieldName = "image"
        
        // --boundary
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        // Content-Disposition with name and filename
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        // Content-Type of the file
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        // file data
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        // --boundary--
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        isFetchingInitialQuestions = true
        
        Task { [weak self] in
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                    await MainActor.run {
                        self?.errorMessage = "Server error."
                        self?.isFetchingInitialQuestions = false
                    }
                    return
                }
                
                // Decode assumed response { "questions": [String] }
                let decoded = try JSONDecoder().decode(InitialQuestionsResponse.self, from: data)
                await MainActor.run {
                    self?.initialQuestion = decoded.question
                    self?.isFetchingInitialQuestions = false
                }
            } catch {
                await MainActor.run {
                    self?.errorMessage = "Failed to fetch initial questions: \(error.localizedDescription)"
                    self?.isFetchingInitialQuestions = false
                }
            }
        }
    }

    // MARK: - Delegate

    func streamerDidUpdateLevel(_ level: Float) {
        Task { @MainActor in
            self.level = level
        }
    }

    func streamerDidReceiveTranscript(_ text: String, isFinal: Bool) {
        Task { @MainActor in
            if isFinal {
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { finalTranscripts.append(trimmed) }
                partialTranscript = ""
            } else {
                partialTranscript = text
            }
        }
    }
}

// MARK: - Response model for /initial-questions
private struct InitialQuestionsResponse: Decodable {
    let question: String
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.question = try c.decodeIfPresent(String.self, forKey: .question) ?? ""
    }
    private enum CodingKeys: String, CodingKey { case question }
}

