import SwiftUI

struct DiskPopover: View {
    let settings: AppSettings
    let systemMonitor: SystemMonitor

    private var metrics: DiskMetrics {
        systemMonitor.diskMetrics
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Disk Usage")
                    .font(.headline)

                Spacer()

                VStack(alignment: .trailing) {
                    Text(String(format: "%.1f%%", metrics.usagePercentage))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(settings.diskThreshold.color(for: metrics.usagePercentage))

                    Text("of \(String(format: "%.0f", metrics.totalGiB)) GiB")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Usage bar
            VStack(alignment: .leading, spacing: 4) {
                GeometryReader { geometry in
                    let usedWidth = geometry.size.width * (metrics.usagePercentage / 100)
                    let color = ColorThresholds.graphColor(for: metrics.usagePercentage, threshold: settings.diskThreshold)

                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .frame(width: usedWidth)
                    }
                }
                .frame(height: 20)
            }

            // Breakdown
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle()
                        .fill(ColorThresholds.graphColor(for: metrics.usagePercentage, threshold: settings.diskThreshold))
                        .frame(width: 10, height: 10)

                    Text("Used")
                        .font(.caption)

                    Spacer()

                    Text(String(format: "%.2f GiB", metrics.usedGiB))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Circle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 10, height: 10)

                    Text("Free")
                        .font(.caption)

                    Spacer()

                    Text(String(format: "%.2f GiB", metrics.freeGiB))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 10, height: 10)

                    Text("Total")
                        .font(.caption)
                        .fontWeight(.medium)

                    Spacer()

                    Text(String(format: "%.2f GiB", metrics.totalGiB))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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
