import Foundation

// MARK: - CPU Metrics

enum CoreType: String, Sendable {
    case performance = "P"
    case efficiency = "E"
    case unknown = "?"
}

struct CPUCoreUsage: Sendable, Identifiable {
    let id: Int
    let coreType: CoreType
    var usage: Double // 0-100
}

struct CPUMetrics: Sendable {
    var totalUsage: Double // 0-100
    var coreUsages: [CPUCoreUsage]
    var history: [Double] // Recent total usage values for sparkline

    static let empty = CPUMetrics(totalUsage: 0, coreUsages: [], history: [])
}

// MARK: - Memory Metrics

struct MemoryMetrics: Sendable {
    var usedBytes: UInt64
    var totalBytes: UInt64
    var activeBytes: UInt64
    var wiredBytes: UInt64
    var compressedBytes: UInt64
    var freeBytes: UInt64
    var history: [Double] // Recent usage percentages for sparkline

    var usagePercentage: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(usedBytes) / Double(totalBytes) * 100
    }

    var usedGiB: Double {
        Double(usedBytes) / (1024 * 1024 * 1024)
    }

    var totalGiB: Double {
        Double(totalBytes) / (1024 * 1024 * 1024)
    }

    static let empty = MemoryMetrics(
        usedBytes: 0,
        totalBytes: 0,
        activeBytes: 0,
        wiredBytes: 0,
        compressedBytes: 0,
        freeBytes: 0,
        history: []
    )
}

// MARK: - Network Metrics

struct NetworkMetrics: Sendable {
    var bytesSentPerSecond: UInt64
    var bytesReceivedPerSecond: UInt64
    var totalBytesSent: UInt64
    var totalBytesReceived: UInt64
    var sendHistory: [UInt64] // Recent bytes/sec for sparkline
    var receiveHistory: [UInt64]
    var linkSpeedBitsPerSecond: UInt64 // Interface link speed in bits/sec

    /// Link speed in bytes per second (divide bits by 8)
    var linkSpeedBytesPerSecond: UInt64 {
        linkSpeedBitsPerSecond / 8
    }

    /// Current send rate as percentage of link speed (0-100)
    var sendPercentage: Double {
        guard linkSpeedBytesPerSecond > 0 else { return 0 }
        return min(Double(bytesSentPerSecond) / Double(linkSpeedBytesPerSecond) * 100, 100)
    }

    /// Current receive rate as percentage of link speed (0-100)
    var receivePercentage: Double {
        guard linkSpeedBytesPerSecond > 0 else { return 0 }
        return min(Double(bytesReceivedPerSecond) / Double(linkSpeedBytesPerSecond) * 100, 100)
    }

    /// Combined send+receive as percentage of link speed (0-100)
    var combinedPercentage: Double {
        guard linkSpeedBytesPerSecond > 0 else { return 0 }
        let combined = bytesSentPerSecond + bytesReceivedPerSecond
        return min(Double(combined) / Double(linkSpeedBytesPerSecond) * 100, 100)
    }

    /// Convert send history to percentages of link speed
    func sendHistoryPercentages() -> [Double] {
        guard linkSpeedBytesPerSecond > 0 else {
            return sendHistory.map { _ in 0.0 }
        }
        return sendHistory.map { min(Double($0) / Double(linkSpeedBytesPerSecond) * 100, 100) }
    }

    /// Convert receive history to percentages of link speed
    func receiveHistoryPercentages() -> [Double] {
        guard linkSpeedBytesPerSecond > 0 else {
            return receiveHistory.map { _ in 0.0 }
        }
        return receiveHistory.map { min(Double($0) / Double(linkSpeedBytesPerSecond) * 100, 100) }
    }

    static let empty = NetworkMetrics(
        bytesSentPerSecond: 0,
        bytesReceivedPerSecond: 0,
        totalBytesSent: 0,
        totalBytesReceived: 0,
        sendHistory: [],
        receiveHistory: [],
        linkSpeedBitsPerSecond: 0
    )
}

// MARK: - Disk Metrics

struct DiskMetrics: Sendable {
    var usedBytes: UInt64
    var totalBytes: UInt64
    var freeBytes: UInt64

    var usagePercentage: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(usedBytes) / Double(totalBytes) * 100
    }

    var usedGiB: Double {
        Double(usedBytes) / (1024 * 1024 * 1024)
    }

    var totalGiB: Double {
        Double(totalBytes) / (1024 * 1024 * 1024)
    }

    var freeGiB: Double {
        Double(freeBytes) / (1024 * 1024 * 1024)
    }

    static let empty = DiskMetrics(usedBytes: 0, totalBytes: 0, freeBytes: 0)
}

// MARK: - Latency Metrics

struct LatencyMetrics: Sendable {
    var latencyMs: Double? // nil if ping failed
    var history: [Double] // Recent latency values in ms for sparkline

    /// Returns the current latency as a formatted string
    var formattedLatency: String {
        if let latency = latencyMs {
            if latency < 1 {
                return String(format: "%.1fms", latency)
            } else {
                return String(format: "%.0fms", latency)
            }
        }
        return "—"
    }

    /// Returns the max value for the sparkline (minimum 10ms, but scales up based on history)
    var sparklineMaxValue: Double {
        let historyMax = history.max() ?? 0
        return max(10.0, historyMax)
    }

    static let empty = LatencyMetrics(latencyMs: nil, history: [])
}
