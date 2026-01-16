import SwiftUI

enum DynamicAlertType: Identifiable, CaseIterable {
    case cpu
    case memory
    case network
    case disk
    case latency

    var id: Self { self }
}

struct DynamicStatusItemView: View {
    let cpuMetrics: CPUMetrics
    let memoryMetrics: MemoryMetrics
    let networkMetrics: NetworkMetrics
    let diskMetrics: DiskMetrics
    let latencyMetrics: LatencyMetrics
    let cpuThreshold: ThresholdConfig
    let memoryThreshold: ThresholdConfig
    let networkThreshold: ThresholdConfig
    let diskThreshold: ThresholdConfig
    let latencyThreshold: ThresholdConfig
    let cpuDisplayMode: MetricDisplayMode
    let memoryDisplayMode: MetricDisplayMode
    let networkDisplayMode: MetricDisplayMode
    let diskDisplayMode: MetricDisplayMode
    let latencyDisplayMode: MetricDisplayMode
    let detectionMethod: DynamicDetectionMethod
    let stdDevThreshold: Double
    let minHistoryCount: Int

    private var useThresholds: Bool {
        detectionMethod == .thresholds || detectionMethod == .both
    }

    private var useOutliers: Bool {
        detectionMethod == .outliers || detectionMethod == .both
    }

    private var activeAlerts: [DynamicAlertType] {
        var result: [DynamicAlertType] = []

        // Check CPU
        let cpuThresholdTriggered = useThresholds && (
            cpuThreshold.isCritical(cpuMetrics.totalUsage) ||
            cpuThreshold.isWarning(cpuMetrics.totalUsage)
        )
        let cpuOutlierTriggered = useOutliers && isOutlier(value: cpuMetrics.totalUsage, history: cpuMetrics.history)
        if cpuThresholdTriggered || cpuOutlierTriggered {
            result.append(.cpu)
        }

        // Check Memory
        let memoryThresholdTriggered = useThresholds && (
            memoryThreshold.isCritical(memoryMetrics.usagePercentage) ||
            memoryThreshold.isWarning(memoryMetrics.usagePercentage)
        )
        let memoryOutlierTriggered = useOutliers && isOutlier(value: memoryMetrics.usagePercentage, history: memoryMetrics.history)
        if memoryThresholdTriggered || memoryOutlierTriggered {
            result.append(.memory)
        }

        // Check Network
        let maxNetworkMBps = max(
            Double(networkMetrics.bytesSentPerSecond),
            Double(networkMetrics.bytesReceivedPerSecond)
        ) / (1024 * 1024)
        let networkThresholdTriggered = useThresholds && (
            networkThreshold.isCritical(maxNetworkMBps) ||
            networkThreshold.isWarning(maxNetworkMBps)
        )
        let combinedHistory = zip(networkMetrics.sendHistory, networkMetrics.receiveHistory)
            .map { Double(max($0, $1)) / (1024 * 1024) }
        let networkOutlierTriggered = useOutliers && isOutlier(value: maxNetworkMBps, history: combinedHistory)
        if networkThresholdTriggered || networkOutlierTriggered {
            result.append(.network)
        }

        // Check Disk (disk doesn't have history, so only threshold check)
        let diskThresholdTriggered = useThresholds && (
            diskThreshold.isCritical(diskMetrics.usagePercentage) ||
            diskThreshold.isWarning(diskMetrics.usagePercentage)
        )
        if diskThresholdTriggered {
            result.append(.disk)
        }

        // Check Latency
        if let latencyMs = latencyMetrics.latencyMs {
            let latencyThresholdTriggered = useThresholds && (
                latencyThreshold.isCritical(latencyMs) ||
                latencyThreshold.isWarning(latencyMs)
            )
            let latencyOutlierTriggered = useOutliers && isOutlier(value: latencyMs, history: latencyMetrics.history)
            if latencyThresholdTriggered || latencyOutlierTriggered {
                result.append(.latency)
            }
        }

        return result
    }

    private func isOutlier(value: Double, history: [Double]) -> Bool {
        guard history.count >= minHistoryCount else { return false }

        let mean = history.reduce(0, +) / Double(history.count)
        let variance = history.map { pow($0 - mean, 2) }.reduce(0, +) / Double(history.count)
        let stdDev = sqrt(variance)

        guard stdDev > 0.1 else { return false }

        let deviations = abs(value - mean) / stdDev
        return deviations > stdDevThreshold
    }

    var body: some View {
        Group {
            if activeAlerts.isEmpty {
                idleView
            } else {
                alertsView
            }
        }
        .frame(height: 18)
    }

    private var idleView: some View {
        HStack(spacing: 2) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.primary.opacity(0.08))
        )
    }

    private var alertsView: some View {
        HStack(spacing: 4) {
            ForEach(activeAlerts) { alertType in
                viewForAlertType(alertType)
            }
        }
    }

    @ViewBuilder
    private func viewForAlertType(_ alertType: DynamicAlertType) -> some View {
        switch alertType {
        case .cpu:
            if cpuDisplayMode == .graph {
                CPUStatusItemView(metrics: cpuMetrics, threshold: cpuThreshold)
            } else {
                CPUTextItemView(metrics: cpuMetrics, threshold: cpuThreshold)
            }
        case .memory:
            if memoryDisplayMode == .graph {
                MemoryStatusItemView(metrics: memoryMetrics, threshold: memoryThreshold)
            } else {
                MemoryTextItemView(metrics: memoryMetrics, threshold: memoryThreshold)
            }
        case .network:
            if networkDisplayMode == .graph {
                NetworkStatusItemView(metrics: networkMetrics, threshold: networkThreshold)
            } else {
                NetworkTextItemView(metrics: networkMetrics)
            }
        case .disk:
            if diskDisplayMode == .graph {
                DiskStatusItemView(metrics: diskMetrics, threshold: diskThreshold)
            } else {
                DiskTextItemView(metrics: diskMetrics, threshold: diskThreshold)
            }
        case .latency:
            if latencyDisplayMode == .graph {
                LatencyStatusItemView(metrics: latencyMetrics, threshold: latencyThreshold)
            } else {
                LatencyTextItemView(metrics: latencyMetrics, threshold: latencyThreshold)
            }
        }
    }
}
