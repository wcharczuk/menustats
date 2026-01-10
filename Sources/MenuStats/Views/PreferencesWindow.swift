import SwiftUI

struct PreferencesWindow: View {
    @Environment(AppSettings.self) private var settings
    @Environment(SystemMonitor.self) private var systemMonitor

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            MetricsSettingsView()
                .tabItem {
                    Label("Metrics", systemImage: "chart.bar")
                }

            ThresholdsSettingsView()
                .tabItem {
                    Label("Thresholds", systemImage: "slider.horizontal.3")
                }
        }
        .padding(.top, 15)
        .frame(width: 450)
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct GeneralSettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section {
                Picker("Update Interval", selection: $settings.updateInterval) {
                    Text("1 second").tag(1.0 as TimeInterval)
                    Text("2 seconds").tag(2.0 as TimeInterval)
                    Text("5 seconds").tag(5.0 as TimeInterval)
                    Text("10 seconds").tag(10.0 as TimeInterval)
                }
            } header: {
                Text("Display")
            }

            Section {
                Toggle("Launch at Login", isOn: Binding(
                    get: { LaunchAtLogin.isEnabled },
                    set: { LaunchAtLogin.isEnabled = $0 }
                ))
            } header: {
                Text("Startup")
            }

            Section {
                Button("Quit MenuStats") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .formStyle(.grouped)
    }
}

struct MetricsSettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section {
                Toggle("Enable CPU Monitoring", isOn: $settings.cpuEnabled)
                if settings.cpuEnabled {
                    Picker("Display Mode", selection: $settings.cpuDisplayMode) {
                        Text("Text").tag(MetricDisplayMode.text)
                        Text("Graph").tag(MetricDisplayMode.graph)
                    }
                }
            } header: {
                Text("CPU")
            }

            Section {
                Toggle("Enable Memory Monitoring", isOn: $settings.memoryEnabled)
                if settings.memoryEnabled {
                    Picker("Display Mode", selection: $settings.memoryDisplayMode) {
                        Text("Text").tag(MetricDisplayMode.text)
                        Text("Graph").tag(MetricDisplayMode.graph)
                    }
                }
            } header: {
                Text("Memory")
            }

            Section {
                Toggle("Enable Network Monitoring", isOn: $settings.networkEnabled)
                if settings.networkEnabled {
                    Picker("Display Mode", selection: $settings.networkDisplayMode) {
                        Text("Text").tag(MetricDisplayMode.text)
                        Text("Graph").tag(MetricDisplayMode.graph)
                    }
                }
            } header: {
                Text("Network")
            }

            Section {
                Toggle("Enable Disk Monitoring", isOn: $settings.diskEnabled)
                if settings.diskEnabled {
                    Picker("Display Mode", selection: $settings.diskDisplayMode) {
                        Text("Text").tag(MetricDisplayMode.text)
                        Text("Graph").tag(MetricDisplayMode.graph)
                    }
                }
            } header: {
                Text("Disk")
            }

            Section {
                Toggle("Enable Dynamic Indicator", isOn: $settings.dynamicEnabled)
                Text("Shows which metrics are approaching or exceeding thresholds")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Dynamic")
            }
        }
        .formStyle(.grouped)
    }
}

struct ThresholdsSettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        Form {
            ThresholdSection(
                title: "CPU",
                threshold: $settings.cpuThreshold,
                unit: "%"
            )

            ThresholdSection(
                title: "Memory",
                threshold: $settings.memoryThreshold,
                unit: "%"
            )

            ThresholdSection(
                title: "Network",
                threshold: $settings.networkThreshold,
                unit: "% of activity"
            )

            ThresholdSection(
                title: "Disk",
                threshold: $settings.diskThreshold,
                unit: "%"
            )
        }
        .formStyle(.grouped)
    }
}

struct ThresholdSection: View {
    let title: String
    @Binding var threshold: ThresholdConfig
    let unit: String

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Normal")
                    Spacer()
                    Text("< \(Int(threshold.greenMax))\(unit)")
                        .foregroundStyle(.primary)
                }

                Slider(value: $threshold.greenMax, in: 0...100, step: 5)

                HStack {
                    Text("Warning")
                    Spacer()
                    Text("\(Int(threshold.greenMax)) - \(Int(threshold.yellowMax))\(unit)")
                        .foregroundStyle(.blue)
                }

                Slider(value: $threshold.yellowMax, in: threshold.greenMax...100, step: 5)

                HStack {
                    Text("Critical")
                    Spacer()
                    Text("> \(Int(threshold.yellowMax))\(unit)")
                        .foregroundStyle(.purple)
                }
            }

            // Preview bar
            HStack(spacing: 2) {
                Rectangle()
                    .fill(.primary.opacity(0.5))
                    .frame(width: CGFloat(threshold.greenMax) * 2)

                Rectangle()
                    .fill(.blue)
                    .frame(width: CGFloat(threshold.yellowMax - threshold.greenMax) * 2)

                Rectangle()
                    .fill(.purple)
                    .frame(width: CGFloat(100 - threshold.yellowMax) * 2)
            }
            .frame(height: 10)
            .clipShape(RoundedRectangle(cornerRadius: 3))
        } header: {
            Text(title)
        }
    }
}
