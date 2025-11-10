protocol SpeechTranscriberDelegate: AnyObject {
//    func streamerDidChangeStatus(_ text: String)
    func streamerDidUpdateLevel(_ level: Float)
//    func streamerDidUpdateBytesSent(_ total: Int64)
//    func streamerDidLog(_ line: String)
    func streamerDidReceiveTranscript(_ text: String, isFinal: Bool)
}
