import Foundation
import UIKit
import Combine
import AVFoundation

@MainActor
@Observable
final class SpeechTranscriberViewModel: SpeechTranscriberDelegate {
    static let shared = SpeechTranscriberViewModel()

    private let config = AppConfig.shared
    var urlString: String
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
    
    private let streamer = SpeechTranscriber.shared

    private init() {
        self.urlString = config.ws("ws/audio").absoluteString
        streamer.delegate = self
    }

    static func requestMicrophonePermissionIfNeeded() {
        let av = AVAudioSession.sharedInstance()
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                print("Mic permission (iOS 17+): \(granted)")
            }
        } else {
            av.requestRecordPermission { granted in
                print("Mic permission (< iOS 17): \(granted)")
            }
        }
    }

    func toggle(resume: Bool) {
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
        Task.detached { [urlString] in
            do {
                guard let url = URL(string: urlString) else {
                    print("invalid URL")
                    return
                }
                try await SpeechTranscriber.shared.resume(url: url)
                await MainActor.run {
                    self.isPaused = false
                    self.suggested = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to resume: \(error.localizedDescription)"
                    self.status = "error"
                }
            }
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

        Task.detached {
            do {
                try await SpeechTranscriber.shared.start(url: url)
                await MainActor.run {
                    self.isStreaming = true
                }
            } catch {
                print("start error: \(error.localizedDescription)")
                await MainActor.run {
                    self.status = "error"
                    self.isStreaming = false
                }
            }
        }
    }

    func stop(resume: Bool) {
        isStreaming = false
        if resume {
            pauseStream()
            getSuggestions()
            return
        }
        SpeechTranscriber.shared.stop()
    }
    
    func getSuggestions(from urlString: String? = nil) {
        suggestions.removeAll()
        suggestionPoint = nil
        errorMessage = nil
        
        let transcript = partialTranscript + finalTranscripts.joined(separator: " ")
        
        guard !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Transcript is empty."
            return
        }
        let suggestionsURL = urlString.flatMap(URL.init(string:)) ?? config.api("suggestions")
        isFetchingSuggestion = true
        let payload = ["transcript": transcript]
        do {
            let body = try JSONSerialization.data(withJSONObject: payload, options: [])
            var req = URLRequest(url: suggestionsURL)
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
    
    func getInitialQuestion(image: UIImage, from urlString: String? = nil) {
        initialQuestion.removeAll()
        errorMessage = nil
        
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
        
        guard let imageData else {
            errorMessage = "Failed to encode image."
            return
        }
        let endpointURL = urlString.flatMap(URL.init(string:)) ?? config.api("initial-questions")
        
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
