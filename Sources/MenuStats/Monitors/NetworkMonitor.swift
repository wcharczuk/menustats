import Foundation
import Darwin

actor NetworkMonitor {
    private let maxHistoryCount = 60
    private var sendHistory: [UInt64] = []
    private var receiveHistory: [UInt64] = []
    private var previousBytesSent: UInt64 = 0
    private var previousBytesReceived: UInt64 = 0
    private var previousTimestamp: Date?

    func getMetrics() -> NetworkMetrics {
        let (totalSent, totalReceived, linkSpeed) = getNetworkStats()
        let now = Date()

        var bytesSentPerSecond: UInt64 = 0
        var bytesReceivedPerSecond: UInt64 = 0

        if let previousTime = previousTimestamp {
            let elapsed = now.timeIntervalSince(previousTime)
            if elapsed > 0 {
                let sentDiff = totalSent > previousBytesSent ? totalSent - previousBytesSent : 0
                let receivedDiff = totalReceived > previousBytesReceived ? totalReceived - previousBytesReceived : 0

                bytesSentPerSecond = UInt64(Double(sentDiff) / elapsed)
                bytesReceivedPerSecond = UInt64(Double(receivedDiff) / elapsed)
            }
        }

        previousBytesSent = totalSent
        previousBytesReceived = totalReceived
        previousTimestamp = now

        // Update history
        sendHistory.append(bytesSentPerSecond)
        receiveHistory.append(bytesReceivedPerSecond)

        if sendHistory.count > maxHistoryCount {
            sendHistory.removeFirst()
        }
        if receiveHistory.count > maxHistoryCount {
            receiveHistory.removeFirst()
        }

        return NetworkMetrics(
            bytesSentPerSecond: bytesSentPerSecond,
            bytesReceivedPerSecond: bytesReceivedPerSecond,
            totalBytesSent: totalSent,
            totalBytesReceived: totalReceived,
            sendHistory: sendHistory,
            receiveHistory: receiveHistory,
            linkSpeedBitsPerSecond: linkSpeed
        )
    }

    private func getNetworkStats() -> (sent: UInt64, received: UInt64, linkSpeed: UInt64) {
        var totalSent: UInt64 = 0
        var totalReceived: UInt64 = 0
        var maxLinkSpeed: UInt64 = 0

        var ifaddrsPtr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrsPtr) == 0, let firstAddr = ifaddrsPtr else {
            return (0, 0, 0)
        }
        defer { freeifaddrs(ifaddrsPtr) }

        var currentAddr: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let addr = currentAddr {
            let interface = addr.pointee

            // Only count AF_LINK (data link layer) interfaces
            if interface.ifa_addr.pointee.sa_family == UInt8(AF_LINK) {
                // Skip loopback interface
                let name = String(cString: interface.ifa_name)
                if name != "lo0" {
                    if let data = interface.ifa_data {
                        let networkData = data.assumingMemoryBound(to: if_data.self).pointee
                        totalSent += UInt64(networkData.ifi_obytes)
                        totalReceived += UInt64(networkData.ifi_ibytes)
                        // Track the highest link speed among active interfaces
                        let speed = UInt64(networkData.ifi_baudrate)
                        if speed > maxLinkSpeed {
                            maxLinkSpeed = speed
                        }
                    }
                }
            }

            currentAddr = interface.ifa_next
        }

        return (totalSent, totalReceived, maxLinkSpeed)
    }

    func getRollingMean() -> (send: Double, receive: Double) {
        let sendMean = sendHistory.isEmpty ? 0 : Double(sendHistory.reduce(0, +)) / Double(sendHistory.count)
        let receiveMean = receiveHistory.isEmpty ? 0 : Double(receiveHistory.reduce(0, +)) / Double(receiveHistory.count)
        return (sendMean, receiveMean)
    }

    func isAboveRollingMean() async -> Bool {
        let (sendMean, receiveMean) = getRollingMean()
        guard let lastSend = sendHistory.last, let lastReceive = receiveHistory.last else {
            return false
        }
        // Consider "active" if current rate is at least 2x the mean and above a minimum threshold
        let minThreshold: UInt64 = 10_000 // 10 KB/s
        let sendActive = Double(lastSend) > sendMean * 2 && lastSend > minThreshold
        let receiveActive = Double(lastReceive) > receiveMean * 2 && lastReceive > minThreshold
        return sendActive || receiveActive
    }
}
