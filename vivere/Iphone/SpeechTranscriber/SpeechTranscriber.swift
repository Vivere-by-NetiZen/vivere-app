import AVFoundation
import Accelerate
import Charts

enum Constants {
    static let sampleAmount: Int = 200
    static let downSampleFactor = 8
    static let magnitudeLimit: Float = 25
}

final class SpeechTranscriber: NSObject {
    weak var delegate: SpeechTranscriberDelegate?
    
    static let shared = SpeechTranscriber()
    
    private let engine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()
    private var ws: URLSessionWebSocketTask?
    private var session: URLSession?
    
    private let targetSampleRate: Double = 16_000
    private let targetChannels: AVAudioChannelCount = 1
    private var totalBytesSent: Int64 = 0
    
    var fftMagnitudes = [Float](repeating: 0, count: Constants.sampleAmount)
    var downSampledMagnitudes: [Float] {
        fftMagnitudes.lazy.enumerated().compactMap { (index, magnitude) in
            index.isMultiple(of: Constants.downSampleFactor) ? magnitude : nil
        }
    }
    
    private let bufferSize = 8192
    private var fftSetup: OpaquePointer?
    
    // Running state
    private var isRunning = false
    
    // Pause state
    private var isPaused = false
    
    // Graceful stop state
    private var isDraining = false
    private var drainWorkItem: DispatchWorkItem?
    private var lastURL: URL?
    
    func start(url: URL) throws {
        if isDraining {
            cancelDrainTimer()
            ws?.cancel(with: .goingAway, reason: nil)
            completeStop()
        }
        
        if isRunning && !isPaused { return }
        
        if isRunning && isPaused {
            try resume(url: url)
            return
        }
        
        isRunning = true
        isPaused = false
        isDraining = false
        cancelDrainTimer()
        lastURL = url
        totalBytesSent = 0
        
        // Audio session setup can be slow; keep off main thread.
        let av = AVAudioSession.sharedInstance()
        do {
            try av.setCategory(.playAndRecord, options: [.duckOthers])
            try av.setActive(true, options: [])
        } catch let error as NSError {
            print("ERROR:", error)
        }
        
        if let builtIn = av.availableInputs?.first(where: { $0.portType == .builtInMic }) {
            try? av.setPreferredInput(builtIn)
        }
        try? av.setPreferredIOBufferDuration(0.02) // ~20ms chunks
        
        let handlePermissionResult: (Bool) -> Void = { [weak self] granted in
            guard let self = self else { return }
            if !granted {
                self.isRunning = false
                return
            }
            
            // Do not force main queue here; setup can run off-main.
            self.openWebSocket(url: url)
            do { try self.startEngine() } catch {
                print("Engine error: \(error.localizedDescription)")
                self.isRunning = false
            }
        }
        
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                handlePermissionResult(granted)
            }
        } else {
            av.requestRecordPermission { granted in
                handlePermissionResult(granted)
            }
        }
    }
    
    func stop() {
        if !isRunning && !isDraining {
            return
        }
        
        isPaused = false
        
        mixer.removeTap(onBus: 0)
        engine.stop()
        fftMagnitudes = [Float](repeating: 0, count: Constants.sampleAmount)
        if let setup = fftSetup {
            vDSP_DFT_DestroySetup(setup)
            fftSetup = nil
        }
        
        guard ws != nil else {
            completeStop()
            return
        }
        
        let stopMessage: [String: Any] = ["type": "stop"]
        if let jsonData = try? JSONSerialization.data(withJSONObject: stopMessage),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            ws?.send(.string(jsonString)) { error in
                if let error {
                    print("ws stop send error: \(error.localizedDescription)")
                }
            }
        }
        
        if isDraining {
            return
        }
        
        isDraining = true
        
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.ws?.cancel(with: .goingAway, reason: nil)
            self.completeStop()
        }
        drainWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: work)
    }
    
    func pause() {
        guard isRunning, !isPaused else { return }
        isPaused = true
        
        let stopMessage: [String: Any] = ["type": "stop"]
        if let jsonData = try? JSONSerialization.data(withJSONObject: stopMessage),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            ws?.send(.string(jsonString)) { error in
                if let error {
                    print("ws stop send error: \(error.localizedDescription)")
                }
            }
        }
        
        mixer.removeTap(onBus: 0)
        engine.stop()
        
        fftMagnitudes = [Float](repeating: 0, count: Constants.sampleAmount)
    }
    
    func resume(url: URL) throws {
        guard isRunning, isPaused else { return }
        isPaused = false
        
        if ws == nil || ws?.closeCode != nil {
            openWebSocket(url: url)
        }
        
        try startEngine()
    }
    
    private func completeStop() {
        cancelDrainTimer()
        
        isRunning = false
        isPaused = false
        isDraining = false
        
        ws?.cancel(with: .goingAway, reason: nil)
        ws = nil
        session?.invalidateAndCancel()
        session = nil
        
        let av = AVAudioSession.sharedInstance()
        try? av.setActive(false, options: [.notifyOthersOnDeactivation])
    }
    
    private func cancelDrainTimer() {
        drainWorkItem?.cancel()
        drainWorkItem = nil
    }
    
    private func openWebSocket(url: URL) {
        let config = URLSessionConfiguration.default
        // Use a background delegate queue instead of .main to avoid blocking UI.
        let delegateQueue = OperationQueue()
        delegateQueue.qualityOfService = .userInitiated
        session = URLSession(configuration: config, delegate: self, delegateQueue: delegateQueue)
        ws = session?.webSocketTask(with: url)
        ws?.resume()
        receiveLoop()
        sendPingLoop()
    }
    
    private func startEngine() throws {
        let input = engine.inputNode
        let inputFormat = input.inputFormat(forBus: 0)
        if fftSetup == nil {
            fftSetup = vDSP_DFT_zop_CreateSetup(nil, UInt(self.bufferSize), .FORWARD)
        }
        
        guard let mixerFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                              sampleRate: targetSampleRate,
                                              channels: targetChannels,
                                              interleaved: false) else {
            throw NSError(domain: "MicStreamer", code: -2, userInfo: [NSLocalizedDescriptionKey: "failed to create mixer format"])
        }
        
        if engine.attachedNodes.contains(mixer) == false {
            engine.attach(mixer)
        }
        if engine.isRunning == false {
            engine.disconnectNodeInput(mixer)
            engine.disconnectNodeOutput(mixer)
            engine.connect(input, to: mixer, format: inputFormat)
            engine.connect(mixer, to: engine.mainMixerNode, format: mixerFormat)
            engine.mainMixerNode.outputVolume = 0
        }
        
        let framesPerChunk = AVAudioFrameCount(targetSampleRate * 0.02)
        
        mixer.removeTap(onBus: 0)
        mixer.installTap(onBus: 0, bufferSize: framesPerChunk, format: mixerFormat) { [weak self] buffer, _ in
            guard let self = self,
                  self.isRunning,
                  !self.isPaused,
                  !self.isDraining else { return }
            
            let level = self.rmsLevel(from: buffer)
            self.delegate?.streamerDidUpdateLevel(level)
            
            if let channel = buffer.floatChannelData?.pointee {
                let frameCount = Int(buffer.frameLength)
                var floatData = [Float](repeating: 0, count: self.bufferSize)
                let copyCount = min(frameCount, self.bufferSize)
                floatData.replaceSubrange(0..<copyCount, with: UnsafeBufferPointer(start: channel, count: copyCount))
                Task { @MainActor in
                    self.fftMagnitudes = await self.performFFT(data: floatData)
                }
            }
            
            guard let src = buffer.floatChannelData?.pointee else { return }
            let n = Int(buffer.frameLength)
            if n == 0 { return }
            
            var out = [Int16](repeating: 0, count: n)
            for i in 0..<n {
                let s = max(-1.0, min(1.0, src[i]))
                out[i] = Int16(s * 32767.0)
            }
            
            let byteCount = n * MemoryLayout<Int16>.size
            let data = out.withUnsafeBytes { Data($0) }
            
            self.ws?.send(.data(data)) { [weak self] err in
                guard let self = self else { return }
                if let err = err {
                    print("ws send error: \(err.localizedDescription)")
                } else {
                    self.totalBytesSent += Int64(byteCount)
                }
            }
        }
        
        if engine.isRunning == false {
            try engine.start()
        }
    }
    
    private func receiveLoop() {
        ws?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let err):
                print("ws receive error: \(err.localizedDescription)")
                if self.isDraining {
                    self.completeStop()
                    return
                }
            case .success(let message):
                switch message {
                case .string(let text):
                    if let data = text.data(using: .utf8) {
                        do {
                            let message = try JSONDecoder().decode(SpeechToTextResponse.self, from: data)
                            // Ensure delegate updates happen on main for UI consistency.
                            DispatchQueue.main.async {
                                self.delegate?.streamerDidReceiveTranscript(message.text, isFinal: message.final)
                            }
                            if self.isDraining && message.final {
                                self.ws?.cancel(with: .goingAway, reason: nil)
                                self.completeStop()
                                return
                            }
                        } catch {
                            print("Decoding error:", error)
                        }
                    }
                case .data(let d):
                    print("server binary: \(d.count) bytes")
                @unknown default:
                    print("server: unknown message")
                }
            }
            if self.isRunning || self.isDraining {
                self.receiveLoop()
            }
        }
    }
    
    private func sendPingLoop() {
        ws?.sendPing { [weak self] error in
            if let error = error {
                print("ping error: \(error.localizedDescription)")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
                if let self, self.isRunning || self.isDraining {
                    self.sendPingLoop()
                }
            }
        }
    }
    
    private func rmsLevel(from buffer: AVAudioPCMBuffer) -> Float {
        guard let floatData = buffer.floatChannelData?.pointee else { return 0 }
        let n = Int(buffer.frameLength)
        if n == 0 { return 0 }
        var sum: Float = 0
        for i in 0..<n { sum += floatData[i] * floatData[i] }
        let rms = sqrt(sum / Float(n))
        return min(max(rms * 4.0, 0), 1)
    }
    
    // MARK: - FFT
    func performFFT(data: [Float]) async -> [Float] {
        guard let setup = fftSetup else {
            return [Float](repeating: 0, count: Constants.sampleAmount)
        }
        
        var realIn = data
        if realIn.count < bufferSize {
            realIn += [Float](repeating: 0, count: bufferSize - realIn.count)
        } else if realIn.count > bufferSize {
            realIn = Array(realIn.prefix(bufferSize))
        }
        
        var imagIn = [Float](repeating: 0, count: bufferSize)
        var realOut = [Float](repeating: 0, count: bufferSize)
        var imagOut = [Float](repeating: 0, count: bufferSize)
        var magnitudes = [Float](repeating: 0, count: Constants.sampleAmount)
        
        realIn.withUnsafeMutableBufferPointer { realInPtr in
            imagIn.withUnsafeMutableBufferPointer { imagInPtr in
                realOut.withUnsafeMutableBufferPointer { realOutPtr in
                    imagOut.withUnsafeMutableBufferPointer { imagOutPtr in
                        vDSP_DFT_Execute(setup,
                                         realInPtr.baseAddress!, imagInPtr.baseAddress!,
                                         realOutPtr.baseAddress!, imagOutPtr.baseAddress!)
                        var complex = DSPSplitComplex(realp: realOutPtr.baseAddress!,
                                                      imagp: imagOutPtr.baseAddress!)
                        vDSP_zvabs(&complex, 1, &magnitudes, 1, UInt(Constants.sampleAmount))
                    }
                }
            }
        }
        
        return magnitudes.map { min($0, Constants.magnitudeLimit) }
    }
}

extension SpeechTranscriber: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol `protocol`: String?) {
        if isDraining {
            isDraining = false
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        if isDraining {
            completeStop()
        }
    }
}
