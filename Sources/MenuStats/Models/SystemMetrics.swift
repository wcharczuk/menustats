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

    static let empty = NetworkMetrics(
        bytesSentPerSecond: 0,
        bytesReceivedPerSecond: 0,
        totalBytesSent: 0,
        totalBytesReceived: 0,
        sendHistory: [],
        receiveHistory: []
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
