import Foundation

enum AppConfigError: Error, CustomStringConvertible {
    case missingKey(String)
    case invalidURL(String, String)

    var description: String {
        switch self {
        case .missingKey(let key):
            return "Missing Info.plist key: \(key)"
        case .invalidURL(let key, let value):
            return "Invalid URL for \(key): \(value)"
        }
    }
}

struct AppConfig {
    static let shared = AppConfig()

    let baseURL: URL
    let wsBaseURL: URL

    private init() {
        func read(_ key: String) -> String {
            guard let v = Bundle.main.object(forInfoDictionaryKey: key) as? String, !v.isEmpty else {
                assertionFailure(AppConfigError.missingKey(key).description)
                return ""
            }
            return v
        }

        let apiBase = read("API_BASE_URL")
        let wsBase = read("WS_BASE_URL")

        guard let apiURL = URL(string: apiBase) else {
            assertionFailure(AppConfigError.invalidURL("API_BASE_URL", apiBase).description)
            self.baseURL = URL(string: "https://invalid.local")!
            self.wsBaseURL = URL(string: "wss://invalid.local")!
            return
        }
        guard let wsURL = URL(string: wsBase) else {
            assertionFailure(AppConfigError.invalidURL("WS_BASE_URL", wsBase).description)
            self.baseURL = apiURL
            self.wsBaseURL = URL(string: "wss://invalid.local")!
            return
        }

        self.baseURL = apiURL
        self.wsBaseURL = wsURL
    }

    func api(_ path: String) -> URL {
        baseURL.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
    }

    func ws(_ path: String) -> URL {
        wsBaseURL.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
    }
}
