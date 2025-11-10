//
//  SpeechTranscriber.swift
//  testing
//
//  Created by Ahmed Nizhan Haikal on 30/10/25.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import AVFoundation
import AVFAudio
import Speech

@MainActor
@Observable
final class SpeechTranscriber {
    var transcript: String = ""
    var isTranscribing: Bool = false
    var errorMessage: String?
    var suggestions: [String] = []
    var suggestionPoint: Int?
    var isFetchingSuggestion: Bool = false

    private let recognizer: SFSpeechRecognizer
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    // Audio engine for live mic capture
    private let audioEngine = AVAudioEngine()
    private var fedFrames: Int64 = 0
    private var lastProcessedSegmentCount: Int = 0

    init(localeIdentifier: String = "id-ID") {
        guard let rec = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier)) else {
            fatalError("Unsupported locale for SFSpeechRecognizer.")
        }
        self.recognizer = rec
    }

    private struct SuggestionResponse: Decodable {
        let suggestions: [String]
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            self.suggestions = try c.decodeIfPresent([String].self, forKey: .suggestions) ?? []
        }
        private enum CodingKeys: String, CodingKey { case suggestions }
    }

    func fetchSuggestions(from urlString: String = "https://server-macro.bunny-kitchen.ts.net/suggestions") {
        suggestions.removeAll()
        suggestionPoint = nil
        errorMessage = nil
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

    func requestAuthorization() async {
        // Request Speech and Microphone permissions
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { _ in
                continuation.resume()
            }
        }
        _ = await withCheckedContinuation { (c: CheckedContinuation<Bool, Never>) in
            if #available(iOS 17.0, macOS 14.0, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    c.resume(returning: granted)
                }
            } else {
                let session = AVAudioSession.sharedInstance()
                session.requestRecordPermission { granted in
                    c.resume(returning: granted)
                }
            }
        }
    }

    private func startNewRecognitionTask() {
        // Create a fresh request and task so recognition can loop continuously
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if #available(iOS 13.0, *) {
            request.taskHint = .dictation
        }
        if #available(iOS 13.0, *) {
            request.requiresOnDeviceRecognition = false
        }
        self.recognitionRequest = request
        self.lastProcessedSegmentCount = 0

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result = result {
                let segments = result.bestTranscription.segments
                if segments.count > self.lastProcessedSegmentCount {
                    let newSlice = segments[self.lastProcessedSegmentCount..<segments.count]
                    let addition = newSlice.map { $0.substring }.joined(separator: " ")
                    if !addition.isEmpty {
                        if !self.transcript.isEmpty && !self.transcript.hasSuffix(" ") {
                            self.transcript += " "
                        }
                        self.transcript += addition
                    }
                    self.lastProcessedSegmentCount = segments.count
                }
            }

            if error != nil || (result?.isFinal ?? false) {
                self.recognitionRequest = nil
                if self.isTranscribing {
                    self.startNewRecognitionTask()
                }
            }
        }
    }

    func startLiveTranscription() {
        stopTranscription(resetTranscript: true)
        transcript = ""
        lastProcessedSegmentCount = 0
        errorMessage = nil

        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            self.errorMessage = "Speech recognition not authorized."
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
            try session.setActive(true, options: [])

            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            fedFrames = 0

            inputNode.removeTap(onBus: 0) // safety on re-run
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                guard let self else { return }
                self.fedFrames += Int64(buffer.frameLength)
                self.recognitionRequest?.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()

            // Start looping recognition tasks
            isTranscribing = true
            startNewRecognitionTask()
        } catch {
            self.errorMessage = "Failed to start live transcription: \(error.localizedDescription)"
            stopTranscription(resetTranscript: false)
        }
    }

    func stopTranscription(resetTranscript: Bool = false) {
        if resetTranscript { transcript = "" }
        finishStream()
    }

    private func finishStream() {
        // End the audio to the recognizer
        recognitionRequest?.endAudio()

        // Tear down engine/tap
        if audioEngine.isRunning {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
        }

        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isTranscribing = false
    }
}
