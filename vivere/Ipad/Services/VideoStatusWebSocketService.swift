//
//  VideoStatusWebSocketService.swift
//  vivere
//
//  WebSocket service for monitoring video generation status
//

import Foundation
import Combine

struct VideoStatusMessage: Codable {
    let type: String
    let job_id: String?
    let status: String?
    let progress: Int?
    let video_url: String?
    let error: String?
    let message: String?
}

protocol VideoStatusWebSocketDelegate: AnyObject {
    func didReceiveStatus(jobId: String, status: String, progress: Int, videoUrl: String?)
    func didReceiveError(jobId: String, error: String)
    func didComplete(jobId: String, status: String)
}

class VideoStatusWebSocketService {
    private let config = AppConfig.shared
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    private weak var delegate: VideoStatusWebSocketDelegate?
    private var isConnected = false
    private let jobId: String

    init(jobId: String) {
        self.jobId = jobId
    }

    func connect(delegate: VideoStatusWebSocketDelegate) {
        self.delegate = delegate

        let wsURL = config.ws("ws/video/\(jobId)")
        let sessionConfig = URLSessionConfiguration.default
        let delegateQueue = OperationQueue()
        delegateQueue.qualityOfService = .userInitiated

        session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: delegateQueue)
        webSocketTask = session?.webSocketTask(with: wsURL)
        webSocketTask?.resume()

        isConnected = true
        receiveMessage()
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        session?.invalidateAndCancel()
        session = nil
        isConnected = false
        delegate = nil
    }

    private func receiveMessage() {
        guard isConnected else { return }

        webSocketTask?.receive { [weak self] result in
            guard let self = self, self.isConnected else { return }

            switch result {
            case .failure(let error):
                print("WebSocket receive error: \(error.localizedDescription)")
                // Try to reconnect or notify delegate
                DispatchQueue.main.async {
                    if let jobId = self.delegate as? VideoProgressItem {
                        // Handle error
                    }
                }

            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleMessage(text)
                    }
                @unknown default:
                    print("Unknown WebSocket message type")
                }
            }

            // Continue receiving messages
            if self.isConnected {
                self.receiveMessage()
            }
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }

        do {
            let message = try JSONDecoder().decode(VideoStatusMessage.self, from: data)

            DispatchQueue.main.async { [weak self] in
                guard let self = self, let delegate = self.delegate else { return }

                guard let jobId = message.job_id else { return }

                switch message.type {
                case "status":
                    if let status = message.status,
                       let progress = message.progress {
                        delegate.didReceiveStatus(
                            jobId: jobId,
                            status: status,
                            progress: progress,
                            videoUrl: message.video_url
                        )
                    }

                case "done":
                    if let status = message.status {
                        delegate.didComplete(jobId: jobId, status: status)
                        self.disconnect()
                    }

                case "error":
                    let errorMessage = message.error ?? message.message ?? "Unknown error"
                    delegate.didReceiveError(jobId: jobId, error: errorMessage)
                    self.disconnect()

                default:
                    break
                }
            }
        } catch {
            print("Failed to decode WebSocket message: \(error)")
        }
    }
}

