protocol SpeechTranscriberDelegate: AnyObject {
    func streamerDidReceiveTranscript(_ text: String, isFinal: Bool)
}

