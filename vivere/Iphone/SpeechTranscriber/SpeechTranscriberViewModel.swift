import Foundation
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
    
    // Use the shared instance so the visualizer (which reads MicStreamer.shared) sees updates.
    private let streamer = SpeechTranscriber.shared

    init() {
        streamer.delegate = self
    }

    func toggle(resume: Bool) {
        if isStreaming {
            stop()
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

    func stop() {
        streamer.stop()
        isStreaming = false
    }
    
    func getSuggestion(from urlString: String = "https://presymphonic-preexclusively-kaylene.ngrok-free.dev/suggestions") {
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
                        suggested = true
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
