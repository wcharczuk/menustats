import Foundation
import Network

actor LatencyMonitor {
    private let maxHistoryCount = 60
    private var history: [Double] = []
    private let host = "google.com"

    func getMetrics() async -> LatencyMetrics {
        let latency = await measureLatency()

        // Only add to history if we got a valid measurement
        if let latency = latency {
            history.append(latency)
            if history.count > maxHistoryCount {
                history.removeFirst()
            }
        }

        return LatencyMetrics(
            latencyMs: latency,
            history: history
        )
    }

    private func measureLatency() async -> Double? {
        let startTime = CFAbsoluteTimeGetCurrent()

        // Use NWConnection to measure TCP connection time to port 80
        // This is a reliable way to measure network latency without requiring raw sockets
        return await withTaskGroup(of: Double?.self) { group in
            group.addTask {
                await self.performPing(startTime: startTime)
            }

            group.addTask {
                // Timeout after 5 seconds
                try? await Task.sleep(for: .seconds(5))
                return nil
            }

            // Return the first result (either the ping result or nil from timeout)
            if let result = await group.next() {
                group.cancelAll()
                return result
            }
            return nil
        }
    }

    private nonisolated func performPing(startTime: CFAbsoluteTime) async -> Double? {
        await withCheckedContinuation { (continuation: CheckedContinuation<Double?, Never>) in
            let connection = NWConnection(
                host: NWEndpoint.Host(host),
                port: .http,
                using: .tcp
            )

            // Use a class to track if we've already resumed, ensuring thread safety
            final class ResumeTracker: @unchecked Sendable {
                private var resumed = false
                private let lock = NSLock()

                func tryResume(_ continuation: CheckedContinuation<Double?, Never>, with value: Double?) -> Bool {
                    lock.lock()
                    defer { lock.unlock() }
                    guard !resumed else { return false }
                    resumed = true
                    continuation.resume(returning: value)
                    return true
                }
            }

            let tracker = ResumeTracker()

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    let endTime = CFAbsoluteTimeGetCurrent()
                    let latencyMs = (endTime - startTime) * 1000.0
                    if tracker.tryResume(continuation, with: latencyMs) {
                        connection.cancel()
                    }

                case .failed, .cancelled:
                    _ = tracker.tryResume(continuation, with: nil)

                default:
                    break
                }
            }

            connection.start(queue: .global())
        }
    }
}
