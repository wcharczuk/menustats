import Foundation
import Darwin

actor CPUMonitor {
    private let maxHistoryCount = 60
    private var history: [Double] = []
    private var previousCPUInfo: [processor_cpu_load_info]?
    private var coreTypes: [CoreType] = []

    init() {
        coreTypes = Self.detectCoreTypes()
    }

    func getMetrics() -> CPUMetrics {
        var numCPUs: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var numCPUInfo: mach_msg_type_number_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUs,
            &cpuInfo,
            &numCPUInfo
        )

        guard result == KERN_SUCCESS, let cpuInfo = cpuInfo else {
            return CPUMetrics.empty
        }

        defer {
            vm_deallocate(
                mach_task_self_,
                vm_address_t(bitPattern: cpuInfo),
                vm_size_t(Int(numCPUInfo) * MemoryLayout<integer_t>.size)
            )
        }

        let cpuLoadInfo = UnsafeBufferPointer(
            start: UnsafeRawPointer(cpuInfo).bindMemory(to: processor_cpu_load_info.self, capacity: Int(numCPUs)),
            count: Int(numCPUs)
        )

        var coreUsages: [CPUCoreUsage] = []
        var totalUserTicks: UInt64 = 0
        var totalSystemTicks: UInt64 = 0
        var totalIdleTicks: UInt64 = 0
        var totalNiceTicks: UInt64 = 0

        for i in 0..<Int(numCPUs) {
            let current = cpuLoadInfo[i]
            let coreType = i < coreTypes.count ? coreTypes[i] : .unknown

            if let previous = previousCPUInfo, i < previous.count {
                let prev = previous[i]

                let userDiff = UInt64(current.cpu_ticks.0) - UInt64(prev.cpu_ticks.0)
                let systemDiff = UInt64(current.cpu_ticks.1) - UInt64(prev.cpu_ticks.1)
                let idleDiff = UInt64(current.cpu_ticks.2) - UInt64(prev.cpu_ticks.2)
                let niceDiff = UInt64(current.cpu_ticks.3) - UInt64(prev.cpu_ticks.3)

                let totalDiff = userDiff + systemDiff + idleDiff + niceDiff
                let usage = totalDiff > 0 ? Double(userDiff + systemDiff + niceDiff) / Double(totalDiff) * 100 : 0

                coreUsages.append(CPUCoreUsage(id: i, coreType: coreType, usage: usage))

                totalUserTicks += userDiff
                totalSystemTicks += systemDiff
                totalIdleTicks += idleDiff
                totalNiceTicks += niceDiff
            } else {
                coreUsages.append(CPUCoreUsage(id: i, coreType: coreType, usage: 0))
            }
        }

        // Store current values for next calculation
        previousCPUInfo = Array(cpuLoadInfo)

        let totalTicks = totalUserTicks + totalSystemTicks + totalIdleTicks + totalNiceTicks
        let totalUsage = totalTicks > 0 ? Double(totalUserTicks + totalSystemTicks + totalNiceTicks) / Double(totalTicks) * 100 : 0

        // Update history
        history.append(totalUsage)
        if history.count > maxHistoryCount {
            history.removeFirst()
        }

        return CPUMetrics(
            totalUsage: totalUsage,
            coreUsages: coreUsages,
            history: history
        )
    }

    private static func detectCoreTypes() -> [CoreType] {
        var coreTypes: [CoreType] = []

        // Try to get Apple Silicon core configuration
        var pCoreCount: Int32 = 0
        var eCoreCount: Int32 = 0
        var size = MemoryLayout<Int32>.size

        // Performance cores (perflevel0 on Apple Silicon)
        if sysctlbyname("hw.perflevel0.logicalcpu", &pCoreCount, &size, nil, 0) == 0 {
            // This is Apple Silicon
            size = MemoryLayout<Int32>.size
            _ = sysctlbyname("hw.perflevel1.logicalcpu", &eCoreCount, &size, nil, 0)

            // P-cores come first, then E-cores
            for _ in 0..<pCoreCount {
                coreTypes.append(.performance)
            }
            for _ in 0..<eCoreCount {
                coreTypes.append(.efficiency)
            }
        } else {
            // Intel Mac - all cores are the same
            var logicalCPUs: Int32 = 0
            size = MemoryLayout<Int32>.size
            if sysctlbyname("hw.logicalcpu", &logicalCPUs, &size, nil, 0) == 0 {
                for _ in 0..<logicalCPUs {
                    coreTypes.append(.unknown)
                }
            }
        }

        return coreTypes
    }
}
