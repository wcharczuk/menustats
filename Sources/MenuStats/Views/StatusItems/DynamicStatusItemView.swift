import SwiftUI

struct DynamicAlertInfo: Identifiable {
    let id = UUID()
    let label: String
    let color: Color
    let value: Double
    let isOutlier: Bool
}

struct DynamicStatusItemView: View {
    let cpuMetrics: CPUMetrics
    let memoryMetrics: MemoryMetrics
    let networkMetrics: NetworkMetrics
    let diskMetrics: DiskMetrics
    let cpuThreshold: ThresholdConfig
    let memoryThreshold: ThresholdConfig
    let networkThreshold: ThresholdConfig
    let diskThreshold: ThresholdConfig
    let outlierDetectionEnabled: Bool
    let stdDevThreshold: Double
    let minHistoryCount: Int

    private static let outlierColor = Color.orange

    private var alerts: [DynamicAlertInfo] {
        var result: [DynamicAlertInfo] = []
        var addedLabels: Set<String> = []

        // Check CPU threshold
        if cpuThreshold.isCritical(cpuMetrics.totalUsage) || cpuThreshold.isWarning(cpuMetrics.totalUsage) {
            result.append(DynamicAlertInfo(
                label: "CPU",
                color: cpuThreshold.color(for: cpuMetrics.totalUsage),
                value: cpuMetrics.totalUsage,
                isOutlier: false
            ))
            addedLabels.insert("CPU")
        }

        // Check CPU outlier (if not already added for threshold)
        if !addedLabels.contains("CPU") && isOutlier(value: cpuMetrics.totalUsage, history: cpuMetrics.history) {
            result.append(DynamicAlertInfo(
                label: "CPU",
                color: Self.outlierColor,
                value: cpuMetrics.totalUsage,
                isOutlier: true,
            ))
            addedLabels.insert("CPU")
        }

        // Check Memory threshold
        if memoryThreshold.isCritical(memoryMetrics.usagePercentage) || memoryThreshold.isWarning(memoryMetrics.usagePercentage) {
            result.append(DynamicAlertInfo(
                label: "MEM",
                color: memoryThreshold.color(for: memoryMetrics.usagePercentage),
                value: memoryMetrics.usagePercentage,
                isOutlier: false
            ))
            addedLabels.insert("MEM")
        }

        // Check Memory outlier
        if !addedLabels.contains("MEM") && isOutlier(value: memoryMetrics.usagePercentage, history: memoryMetrics.history) {
            result.append(DynamicAlertInfo(
                label: "MEM",
                color: Self.outlierColor,
                value: memoryMetrics.usagePercentage,
                isOutlier: true
            ))
            addedLabels.insert("MEM")
        }

        // Check Network threshold
        let maxNetworkMBps = max(
            Double(networkMetrics.bytesSentPerSecond),
            Double(networkMetrics.bytesReceivedPerSecond)
        ) / (1024 * 1024)
        let networkPercent = maxNetworkMBps
        if networkThreshold.isCritical(networkPercent) || networkThreshold.isWarning(networkPercent) {
            result.append(DynamicAlertInfo(
                label: "NET",
                color: networkThreshold.color(for: networkPercent),
                value: networkPercent,
                isOutlier: false
            ))
            addedLabels.insert("NET")
        }

        // Check Network outlier (combine send and receive history)
        if !addedLabels.contains("NET") {
            let combinedHistory = zip(networkMetrics.sendHistory, networkMetrics.receiveHistory)
                .map { Double(max($0, $1)) / (1024 * 1024) }
            let currentNetworkValue = maxNetworkMBps
            if isOutlier(value: currentNetworkValue, history: combinedHistory) {
                result.append(DynamicAlertInfo(
                    label: "NET",
                    color: Self.outlierColor,
                    value: currentNetworkValue,
                    isOutlier: true
                ))
                addedLabels.insert("NET")
            }
        }

        // Check Disk threshold (disk doesn't have history, so no outlier check)
        if diskThreshold.isCritical(diskMetrics.usagePercentage) || diskThreshold.isWarning(diskMetrics.usagePercentage) {
            result.append(DynamicAlertInfo(
                label: "DSK",
                color: diskThreshold.color(for: diskMetrics.usagePercentage),
                value: diskMetrics.usagePercentage,
                isOutlier: false
            ))
        }

        return result
    }

    private func isOutlier(value: Double, history: [Double]) -> Bool {
        guard outlierDetectionEnabled else { return false }
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
            if alerts.isEmpty {
                // No alerts - show monitoring icon
                idleView
            } else {
                // Show alert badges
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
        HStack(spacing: 2) {
            ForEach(alerts) { alert in
                Text(alert.label)
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundStyle(alert.color)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.primary.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(alertBorderColor, lineWidth: 1)
                )
        )
    }

    private var alertBorderColor: Color {
        // Use the most severe alert color for the border
        let hasCritical = alerts.contains { alert in
            switch alert.label {
            case "CPU": return cpuThreshold.isCritical(alert.value)
            case "MEM": return memoryThreshold.isCritical(alert.value)
            case "NET": return networkThreshold.isCritical(alert.value)
            case "DSK": return diskThreshold.isCritical(alert.value)
            default: return false
            }
        }
        return hasCritical ? ColorThresholds.critical : ColorThresholds.warning
    }
}
