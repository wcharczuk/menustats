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

            DynamicSettingsView()
                .tabItem {
                    Label("Dynamic", systemImage: "waveform.path.ecg")
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
                Toggle("Enable Latency Monitoring", isOn: $settings.latencyEnabled)
                if settings.latencyEnabled {
                    Picker("Display Mode", selection: $settings.latencyDisplayMode) {
                        Text("Text").tag(MetricDisplayMode.text)
                        Text("Graph").tag(MetricDisplayMode.graph)
                    }
                }
                Text("Measures round-trip time to google.com")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Latency")
            }
        }
        .formStyle(.grouped)
    }
}

struct DynamicSettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section {
                Toggle("Enable Dynamic Indicator", isOn: $settings.dynamicEnabled)
                Text("Shows which metrics need attention based on the selected detection method")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Dynamic Indicator")
            }

            if settings.dynamicEnabled {
                Section {
                    Picker("Detection Method", selection: $settings.dynamicDetectionMethod) {
                        ForEach(DynamicDetectionMethod.allCases, id: \.self) { method in
                            Text(method.displayName).tag(method)
                        }
                    }
                    .pickerStyle(.radioGroup)

                    Text(settings.dynamicDetectionMethod.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Detection Method")
                }

                if settings.dynamicDetectionMethod == .outliers || settings.dynamicDetectionMethod == .both {
                    Section {
                        HStack {
                            Text("Sensitivity")
                            Spacer()
                            Text(sensitivityLabel(for: settings.dynamicStdDevThreshold))
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Spacer()
                            VStack(spacing: 4) {
                                HStack {
                                    Text("More")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    TickSlider(
                                        value: $settings.dynamicStdDevThreshold,
                                        range: 2.0...6.0,
                                        tickMarks: 5,
                                        tickLabels: ["2σ", "3σ", "4σ", "5σ", "6σ"]
                                    )
                                    .frame(width: 200)
                                    Text("Less")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Text("Standard deviations from mean required to trigger")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }

                        Divider()
                            .padding(.vertical, 4)

                        Stepper(
                            "Minimum Samples: \(settings.dynamicMinHistoryCount)",
                            value: $settings.dynamicMinHistoryCount,
                            in: 5...30
                        )
                        Text("Number of samples required before outlier detection activates")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } header: {
                        Text("Outlier Detection Settings")
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private func sensitivityLabel(for stdDev: Double) -> String {
        switch stdDev {
        case ..<2.5: return "Very High"
        case 2.5..<3.5: return "High"
        case 3.5..<4.5: return "Medium"
        case 4.5..<5.5: return "Low"
        default: return "Very Low"
        }
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
                unit: "%"
            )

            ThresholdSection(
                title: "Disk",
                threshold: $settings.diskThreshold,
                unit: "%"
            )

            LatencyThresholdSection(
                title: "Latency",
                threshold: $settings.latencyThreshold
            )
        }
        .formStyle(.grouped)
    }
}

struct LatencyThresholdSection: View {
    let title: String
    @Binding var threshold: ThresholdConfig

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                // Current values display
                HStack {
                    HStack(spacing: 4) {
                        Circle().fill(Color.primary.opacity(0.5)).frame(width: 8, height: 8)
                        Text("Normal: <\(Int(threshold.greenMax))ms")
                            .font(.caption)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Circle().fill(Color.blue).frame(width: 8, height: 8)
                        Text("Warning: \(Int(threshold.greenMax))-\(Int(threshold.yellowMax))ms")
                            .font(.caption)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Circle().fill(Color.purple).frame(width: 8, height: 8)
                        Text("Critical: >\(Int(threshold.yellowMax))ms")
                            .font(.caption)
                    }
                }

                // Dual thumb slider for latency (0-500ms range)
                LatencyDualThumbSlider(
                    warningValue: $threshold.greenMax,
                    criticalValue: $threshold.yellowMax,
                    range: 0...500
                )
                .frame(height: 44)
            }
        } header: {
            Text(title)
        }
    }
}

struct LatencyDualThumbSlider: View {
    @Binding var warningValue: Double
    @Binding var criticalValue: Double
    let range: ClosedRange<Double>

    private let trackHeight: CGFloat = 6
    private let thumbSize: CGFloat = 18

    var body: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width - thumbSize
            let warningPosition = thumbSize / 2 + (warningValue - range.lowerBound) / (range.upperBound - range.lowerBound) * trackWidth
            let criticalPosition = thumbSize / 2 + (criticalValue - range.lowerBound) / (range.upperBound - range.lowerBound) * trackWidth

            VStack(spacing: 4) {
                ZStack(alignment: .leading) {
                    // Track background segments
                    HStack(spacing: 0) {
                        // Normal segment (0 to warning)
                        Rectangle()
                            .fill(Color.primary.opacity(0.3))
                            .frame(width: max(0, warningPosition - thumbSize / 2))

                        // Warning segment (warning to critical)
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: max(0, criticalPosition - warningPosition))

                        // Critical segment (critical to max)
                        Rectangle()
                            .fill(Color.purple)
                    }
                    .frame(height: trackHeight)
                    .clipShape(RoundedRectangle(cornerRadius: trackHeight / 2))
                    .padding(.horizontal, thumbSize / 2)

                    // Warning thumb
                    Circle()
                        .fill(Color.white)
                        .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                        .frame(width: thumbSize, height: thumbSize)
                        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                        .position(x: warningPosition, y: geometry.size.height / 2 - 10)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let newValue = valueFromPosition(value.location.x, trackWidth: trackWidth)
                                    warningValue = min(newValue, criticalValue - 10)
                                }
                        )

                    // Critical thumb
                    Circle()
                        .fill(Color.white)
                        .overlay(Circle().stroke(Color.purple, lineWidth: 2))
                        .frame(width: thumbSize, height: thumbSize)
                        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                        .position(x: criticalPosition, y: geometry.size.height / 2 - 10)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let newValue = valueFromPosition(value.location.x, trackWidth: trackWidth)
                                    criticalValue = max(newValue, warningValue + 10)
                                }
                        )
                }
                .frame(height: thumbSize + 4)

                // Min/max labels
                HStack {
                    Text("0ms")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("500ms")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func valueFromPosition(_ x: CGFloat, trackWidth: CGFloat) -> Double {
        let clampedX = max(thumbSize / 2, min(x, trackWidth + thumbSize / 2))
        let percentage = (clampedX - thumbSize / 2) / trackWidth
        let value = range.lowerBound + percentage * (range.upperBound - range.lowerBound)
        return (value / 10).rounded() * 10 // Snap to 10ms increments
    }
}

struct ThresholdSection: View {
    let title: String
    @Binding var threshold: ThresholdConfig
    let unit: String

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                // Current values display
                HStack {
                    HStack(spacing: 4) {
                        Circle().fill(Color.primary.opacity(0.5)).frame(width: 8, height: 8)
                        Text("Normal: <\(Int(threshold.greenMax))\(unit)")
                            .font(.caption)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Circle().fill(Color.blue).frame(width: 8, height: 8)
                        Text("Warning: \(Int(threshold.greenMax))-\(Int(threshold.yellowMax))\(unit)")
                            .font(.caption)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Circle().fill(Color.purple).frame(width: 8, height: 8)
                        Text("Critical: >\(Int(threshold.yellowMax))\(unit)")
                            .font(.caption)
                    }
                }

                // Dual thumb slider
                DualThumbSlider(
                    warningValue: $threshold.greenMax,
                    criticalValue: $threshold.yellowMax,
                    range: 0...100
                )
                .frame(height: 44)
            }
        } header: {
            Text(title)
        }
    }
}

struct DualThumbSlider: View {
    @Binding var warningValue: Double
    @Binding var criticalValue: Double
    let range: ClosedRange<Double>

    private let trackHeight: CGFloat = 6
    private let thumbSize: CGFloat = 18

    var body: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width - thumbSize
            let warningPosition = thumbSize / 2 + (warningValue - range.lowerBound) / (range.upperBound - range.lowerBound) * trackWidth
            let criticalPosition = thumbSize / 2 + (criticalValue - range.lowerBound) / (range.upperBound - range.lowerBound) * trackWidth

            VStack(spacing: 4) {
                ZStack(alignment: .leading) {
                    // Track background segments
                    HStack(spacing: 0) {
                        // Normal segment (0 to warning)
                        Rectangle()
                            .fill(Color.primary.opacity(0.3))
                            .frame(width: max(0, warningPosition - thumbSize / 2))

                        // Warning segment (warning to critical)
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: max(0, criticalPosition - warningPosition))

                        // Critical segment (critical to 100)
                        Rectangle()
                            .fill(Color.purple)
                    }
                    .frame(height: trackHeight)
                    .clipShape(RoundedRectangle(cornerRadius: trackHeight / 2))
                    .padding(.horizontal, thumbSize / 2)

                    // Warning thumb
                    Circle()
                        .fill(Color.white)
                        .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                        .frame(width: thumbSize, height: thumbSize)
                        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                        .position(x: warningPosition, y: geometry.size.height / 2 - 10)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let newValue = valueFromPosition(value.location.x, trackWidth: trackWidth)
                                    warningValue = min(newValue, criticalValue - 1)
                                }
                        )

                    // Critical thumb
                    Circle()
                        .fill(Color.white)
                        .overlay(Circle().stroke(Color.purple, lineWidth: 2))
                        .frame(width: thumbSize, height: thumbSize)
                        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                        .position(x: criticalPosition, y: geometry.size.height / 2 - 10)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let newValue = valueFromPosition(value.location.x, trackWidth: trackWidth)
                                    criticalValue = max(newValue, warningValue + 1)
                                }
                        )
                }
                .frame(height: thumbSize + 4)

                // Min/max labels
                HStack {
                    Text("0%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("100%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func valueFromPosition(_ x: CGFloat, trackWidth: CGFloat) -> Double {
        let clampedX = max(thumbSize / 2, min(x, trackWidth + thumbSize / 2))
        let percentage = (clampedX - thumbSize / 2) / trackWidth
        let value = range.lowerBound + percentage * (range.upperBound - range.lowerBound)
        return value.rounded() // Snap to 1% increments
    }
}

struct TickSlider: NSViewRepresentable {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let tickMarks: Int
    let tickLabels: [String]

    func makeNSView(context: Context) -> NSView {
        let container = TickSliderContainer(
            value: value,
            range: range,
            tickMarks: tickMarks,
            tickLabels: tickLabels,
            coordinator: context.coordinator
        )
        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let container = nsView as? TickSliderContainer {
            container.slider.doubleValue = value
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    @MainActor
    class Coordinator: NSObject {
        var parent: TickSlider

        init(_ parent: TickSlider) {
            self.parent = parent
        }

        @objc func valueChanged(_ sender: NSSlider) {
            parent.value = sender.doubleValue
        }
    }
}

class TickSliderContainer: NSView {
    let slider: NSSlider
    let tickLabels: [String]
    let tickMarks: Int
    private var labelViews: [NSTextField] = []

    init(value: Double, range: ClosedRange<Double>, tickMarks: Int, tickLabels: [String], coordinator: TickSlider.Coordinator) {
        self.tickLabels = tickLabels
        self.tickMarks = tickMarks
        self.slider = NSSlider(value: value, minValue: range.lowerBound, maxValue: range.upperBound, target: coordinator, action: #selector(TickSlider.Coordinator.valueChanged(_:)))

        super.init(frame: .zero)

        slider.numberOfTickMarks = tickMarks
        slider.allowsTickMarkValuesOnly = true
        slider.tickMarkPosition = .below
        slider.translatesAutoresizingMaskIntoConstraints = false
        addSubview(slider)

        NSLayoutConstraint.activate([
            slider.topAnchor.constraint(equalTo: topAnchor),
            slider.leadingAnchor.constraint(equalTo: leadingAnchor),
            slider.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        // Create labels
        for labelText in tickLabels {
            let label = NSTextField(labelWithString: labelText)
            label.font = NSFont.systemFont(ofSize: 9)
            label.textColor = NSColor.tertiaryLabelColor
            label.alignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            addSubview(label)
            labelViews.append(label)

            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 2)
            ])
        }

        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()

        // Position labels based on actual slider frame
        let sliderFrame = slider.frame
        let knobInset: CGFloat = 4  // Approximate inset for the slider knob

        for (index, label) in labelViews.enumerated() {
            let fraction = CGFloat(index) / CGFloat(max(tickMarks - 1, 1))
            let trackWidth = sliderFrame.width - (knobInset * 2)
            let xPosition = sliderFrame.minX + knobInset + (fraction * trackWidth)
            label.sizeToFit()
            label.frame.origin.x = xPosition - (label.frame.width / 2)
        }
    }
}
