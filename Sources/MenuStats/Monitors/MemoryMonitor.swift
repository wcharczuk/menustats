import Foundation
import Darwin

actor MemoryMonitor {
    private let maxHistoryCount = 60
    private var history: [Double] = []
    private let pageSize: UInt64

    init() {
        // Get page size at init time - this is effectively constant after boot
        // Use getpagesize() which is the standard POSIX way
        self.pageSize = UInt64(getpagesize())
    }

    func getMetrics() -> MemoryMetrics {
        let totalBytes = ProcessInfo.processInfo.physicalMemory

        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &vmStats) { statsPtr in
            statsPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, intPtr, &count)
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

        let metrics = MemoryMetrics(
            usedBytes: usedBytes,
            totalBytes: totalBytes,
            activeBytes: activeBytes,
            wiredBytes: wiredBytes,
            compressedBytes: compressedBytes,
            freeBytes: freeBytes,
            history: history
        )

        // Update history
        history.append(metrics.usagePercentage)
        if history.count > maxHistoryCount {
            history.removeFirst()
        }

        return metrics
    }
}
