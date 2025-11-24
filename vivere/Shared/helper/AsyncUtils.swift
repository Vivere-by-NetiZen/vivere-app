//
//  AsyncUtils.swift
//  vivere
//
//  Created for robust async operations
//

import Foundation

enum AsyncError: Error, LocalizedError {
    case timeout(duration: TimeInterval)

    var errorDescription: String? {
        switch self {
        case .timeout(let duration):
            return "Operation timed out after \(Int(duration / 60)) minutes"
        }
    }
}

struct AsyncUtils {

    /// Retry an async operation with a timeout and interval
    /// - Parameters:
    ///   - timeout: Total duration to keep retrying (default 5 minutes)
    ///   - retryInterval: Time to wait between retries (default 10 seconds)
    ///   - operationDescription: Description for logging (e.g. "Upload image")
    ///   - shouldRetry: Optional closure to determine if a specific error should trigger a retry. Returns true by default.
    ///   - operation: The async operation to perform
    static func withRetry<T>(
        timeout: TimeInterval = 300,
        retryInterval: TimeInterval = 10,
        operationDescription: String = "Operation",
        shouldRetry: ((Error) -> Bool)? = nil,
        operation: () async throws -> T
    ) async throws -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        var attempt = 0
        var lastError: Error?

        while (CFAbsoluteTimeGetCurrent() - startTime) < timeout {
            attempt += 1

            if Task.isCancelled { throw CancellationError() }

            do {
                return try await operation()
            } catch {
                lastError = error

                // Check if we should stop retrying based on error type
                if let checker = shouldRetry, !checker(error) {
                    throw error
                }

                #if DEBUG
                let elapsed = CFAbsoluteTimeGetCurrent() - startTime
                let remaining = max(0, timeout - elapsed)
                print("⚠️ \(operationDescription) failed (Attempt \(attempt)): \(error.localizedDescription)")
                print("   Retrying in \(Int(retryInterval))s... (Time remaining: \(Int(remaining))s)")
                #endif

                try? await Task.sleep(nanoseconds: UInt64(retryInterval * 1_000_000_000))
            }
        }

        throw lastError ?? AsyncError.timeout(duration: timeout)
    }
}

