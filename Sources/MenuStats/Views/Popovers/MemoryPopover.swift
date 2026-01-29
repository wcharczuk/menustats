import SwiftUI

struct MemoryPopover: View {
    let settings: AppSettings
    let systemMonitor: SystemMonitor

    private var metrics: MemoryMetrics {
        systemMonitor.memoryMetrics
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Memory Usage")
                    .font(.headline)

                Spacer()

                VStack(alignment: .trailing) {
                    Text(String(format: "%.1f%%", metrics.usagePercentage))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(settings.memoryThreshold.color(for: metrics.usagePercentage))

                    Text(String(format: "%.2f / %.2f GiB", metrics.usedGiB, metrics.totalGiB))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // History Graph
            HistoryGraphView(
                values: metrics.history,
                threshold: settings.memoryThreshold,
                maxValue: 100,
                title: "History"
            ) { value in
                String(format: "%.0f%%", value)
            }
            .frame(height: 60)

            // Memory breakdown
            VStack(alignment: .leading, spacing: 8) {
                Text("Breakdown")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                MemoryBreakdownRow(label: "Active", bytes: metrics.activeBytes, total: metrics.totalBytes, color: .blue)
                MemoryBreakdownRow(label: "Wired", bytes: metrics.wiredBytes, total: metrics.totalBytes, color: .red)
                MemoryBreakdownRow(label: "Compressed", bytes: metrics.compressedBytes, total: metrics.totalBytes, color: .orange)
                MemoryBreakdownRow(label: "Free", bytes: metrics.freeBytes, total: metrics.totalBytes, color: .green)
            }

            Divider()

            // Footer with actions
            HStack {
                Button("Preferences...") {
                    openPreferences()
                }
                .buttonStyle(.link)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.link)
            }
            .font(.caption)
        }
        .padding()
        .frame(width: 300)
    }

    private func openPreferences() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}

struct MemoryBreakdownRow: View {
    let label: String
    let bytes: UInt64
    let total: UInt64
    let color: Color

    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(bytes) / Double(total) * 100
    }

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.caption)

            Spacer()

            Text(ByteFormatter.format(bytes))
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(String(format: "%.1f%%", percentage))
                .font(.caption)
                .frame(width: 45, alignment: .trailing)
        }
    }
}
