import SwiftUI

struct CPUPopover: View {
    let settings: AppSettings
    let systemMonitor: SystemMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("CPU Usage")
                    .font(.headline)

                Spacer()

                Text(String(format: "%.1f%%", systemMonitor.cpuMetrics.totalUsage))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(settings.cpuThreshold.color(for: systemMonitor.cpuMetrics.totalUsage))
            }

            // History Graph
            HistoryGraphView(
                values: systemMonitor.cpuMetrics.history,
                threshold: settings.cpuThreshold,
                maxValue: 100,
                title: "History"
            ) { value in
                String(format: "%.0f%%", value)
            }
            .frame(height: 60)

            // Core breakdown
            VStack(alignment: .leading, spacing: 4) {
                Text("Cores")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                CoreGridView(
                    coreUsages: systemMonitor.cpuMetrics.coreUsages,
                    threshold: settings.cpuThreshold
                )
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
