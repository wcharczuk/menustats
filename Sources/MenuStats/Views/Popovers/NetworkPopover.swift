import SwiftUI

struct NetworkPopover: View {
    let settings: AppSettings
    let systemMonitor: SystemMonitor

    private var metrics: NetworkMetrics {
        systemMonitor.networkMetrics
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Network Activity")
                    .font(.headline)

                Spacer()
            }

            // Link speed
            HStack {
                Text("Link Speed:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(metrics.linkSpeedBitsPerSecond > 0
                    ? formatLinkSpeed(metrics.linkSpeedBitsPerSecond)
                    : "Unknown")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Current rates
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "arrow.up")
                            .foregroundStyle(.blue)
                        Text("Upload")
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)

                    Text(ByteFormatter.formatRate(metrics.bytesSentPerSecond))
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "arrow.down")
                            .foregroundStyle(.green)
                        Text("Download")
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)

                    Text(ByteFormatter.formatRate(metrics.bytesReceivedPerSecond))
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }

            // Upload history graph
            HistoryGraphView(
                values: metrics.sendHistory.map { Double($0) },
                threshold: settings.networkThreshold,
                title: "Upload"
            ) { value in
                ByteFormatter.formatRate(UInt64(value))
            }
            .frame(height: 50)

            // Download history graph
            HistoryGraphView(
                values: metrics.receiveHistory.map { Double($0) },
                threshold: settings.networkThreshold,
                title: "Download"
            ) { value in
                ByteFormatter.formatRate(UInt64(value))
            }
            .frame(height: 50)

            // Totals
            VStack(alignment: .leading, spacing: 4) {
                Text("Session Totals")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Text("Uploaded:")
                        .font(.caption)
                    Spacer()
                    Text(ByteFormatter.format(metrics.totalBytesSent))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Downloaded:")
                        .font(.caption)
                    Spacer()
                    Text(ByteFormatter.format(metrics.totalBytesReceived))
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
        .frame(width: 200)
    }

    private func openPreferences() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    private func formatLinkSpeed(_ bitsPerSecond: UInt64) -> String {
        let bits = Double(bitsPerSecond)
        if bits >= 1_000_000_000 {
            return String(format: "%.0f Gbps", bits / 1_000_000_000)
        } else if bits >= 1_000_000 {
            return String(format: "%.0f Mbps", bits / 1_000_000)
        } else if bits >= 1_000 {
            return String(format: "%.0f Kbps", bits / 1_000)
        } else {
            return String(format: "%.0f bps", bits)
        }
    }
}
