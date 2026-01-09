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
        .frame(width: 300)
    }

    private func openPreferences() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}
