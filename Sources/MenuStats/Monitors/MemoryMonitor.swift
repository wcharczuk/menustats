import Foundation
import Darwin

actor MemoryMonitor {
    private let maxHistoryCount = 60
    private var history: [Double] = []
    private let pageSize: UInt64
    private let hostPort: mach_port_t

    init() {
        // Get page size at init time - this is effectively constant after boot
        // Use getpagesize() which is the standard POSIX way
        self.pageSize = UInt64(getpagesize())
        self.hostPort = mach_host_self()
    }

    func getMetrics() -> MemoryMetrics {
        let totalBytes = ProcessInfo.processInfo.physicalMemory

        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &vmStats) { statsPtr in
            statsPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(hostPort, HOST_VM_INFO64, intPtr, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return MemoryMetrics.empty
        }

        let activeBytes = UInt64(vmStats.active_count) * pageSize
        let wiredBytes = UInt64(vmStats.wire_count) * pageSize
        let compressedBytes = UInt64(vmStats.compressor_page_count) * pageSize
        let freeBytes = UInt64(vmStats.free_count) * pageSize

        // Used memory = active + wired + compressed
        let usedBytes = activeBytes + wiredBytes + compressedBytes

        // Update history before constructing metrics so the current value is included
        let usagePercentage = totalBytes > 0 ? Double(usedBytes) / Double(totalBytes) * 100 : 0
        history.append(usagePercentage)
        if history.count > maxHistoryCount {
            history.removeFirst()
        }

        return MemoryMetrics(
            usedBytes: usedBytes,
            totalBytes: totalBytes,
            activeBytes: activeBytes,
            wiredBytes: wiredBytes,
            compressedBytes: compressedBytes,
            freeBytes: freeBytes,
            history: history
        )
    }
}
