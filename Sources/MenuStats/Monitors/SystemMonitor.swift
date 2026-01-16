import Foundation

@Observable
@MainActor
final class SystemMonitor {
    private(set) var cpuMetrics = CPUMetrics.empty
    private(set) var memoryMetrics = MemoryMetrics.empty
    private(set) var networkMetrics = NetworkMetrics.empty
    private(set) var diskMetrics = DiskMetrics.empty
    private(set) var latencyMetrics = LatencyMetrics.empty

    private let cpuMonitor = CPUMonitor()
    private let memoryMonitor = MemoryMonitor()
    private let networkMonitor = NetworkMonitor()
    private let diskMonitor = DiskMonitor()
    private let latencyMonitor = LatencyMonitor()

    private var monitoringTask: Task<Void, Never>?
    private var updateInterval: TimeInterval = 2.0

    func startMonitoring() {
        stopMonitoring()

        monitoringTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.updateMetrics()
                try? await Task.sleep(for: .seconds(self?.updateInterval ?? 2.0))
            }
        }
    }

    func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
    }

    func setUpdateInterval(_ interval: TimeInterval) {
        updateInterval = interval
    }

    private func updateMetrics() async {
        async let cpu = cpuMonitor.getMetrics()
        async let memory = memoryMonitor.getMetrics()
        async let network = networkMonitor.getMetrics()
        async let disk = diskMonitor.getMetrics()
        async let latency = latencyMonitor.getMetrics()

        let (cpuResult, memoryResult, networkResult, diskResult, latencyResult) = await (cpu, memory, network, disk, latency)

        cpuMetrics = cpuResult
        memoryMetrics = memoryResult
        networkMetrics = networkResult
        diskMetrics = diskResult
        latencyMetrics = latencyResult
    }

    func isNetworkActive() async -> Bool {
        await networkMonitor.isAboveRollingMean()
    }
}
