import Foundation

nonisolated
struct SpeechToTextResponse: Codable {
    let type: String
    let final: Bool
    let text: String
}
