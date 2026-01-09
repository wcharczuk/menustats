import Foundation
import SwiftUI

enum MetricDisplayMode: String, CaseIterable, Codable {
    case text
    case graph
    case hidden
}

@Observable
@MainActor
final class AppSettings {
    // MARK: - General Settings

    var updateInterval: TimeInterval {
        didSet { UserDefaults.standard.set(updateInterval, forKey: "updateInterval") }
    }

    var launchAtLogin: Bool {
        didSet { UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin") }
    }

    // MARK: - Metric Enable/Disable

    var cpuEnabled: Bool {
        didSet { UserDefaults.standard.set(cpuEnabled, forKey: "cpuEnabled") }
    }

    var memoryEnabled: Bool {
        didSet { UserDefaults.standard.set(memoryEnabled, forKey: "memoryEnabled") }
    }

    var networkEnabled: Bool {
        didSet { UserDefaults.standard.set(networkEnabled, forKey: "networkEnabled") }
    }

    var diskEnabled: Bool {
        didSet { UserDefaults.standard.set(diskEnabled, forKey: "diskEnabled") }
    }

    var dynamicEnabled: Bool {
        didSet { UserDefaults.standard.set(dynamicEnabled, forKey: "dynamicEnabled") }
    }

    // MARK: - Display Modes

    var cpuDisplayMode: MetricDisplayMode {
        didSet { UserDefaults.standard.set(cpuDisplayMode.rawValue, forKey: "cpuDisplayMode") }
    }

    var memoryDisplayMode: MetricDisplayMode {
        didSet { UserDefaults.standard.set(memoryDisplayMode.rawValue, forKey: "memoryDisplayMode") }
    }

    var networkDisplayMode: MetricDisplayMode {
        didSet { UserDefaults.standard.set(networkDisplayMode.rawValue, forKey: "networkDisplayMode") }
    }

    var diskDisplayMode: MetricDisplayMode {
        didSet { UserDefaults.standard.set(diskDisplayMode.rawValue, forKey: "diskDisplayMode") }
    }

    // MARK: - Thresholds

    var cpuThreshold: ThresholdConfig {
        didSet { saveThreshold(cpuThreshold, key: "cpuThreshold") }
    }

    var memoryThreshold: ThresholdConfig {
        didSet { saveThreshold(memoryThreshold, key: "memoryThreshold") }
    }

    var networkThreshold: ThresholdConfig {
        didSet { saveThreshold(networkThreshold, key: "networkThreshold") }
    }

    var diskThreshold: ThresholdConfig {
        didSet { saveThreshold(diskThreshold, key: "diskThreshold") }
    }

    // MARK: - Initialization

    init() {
        let defaults = UserDefaults.standard

        self.updateInterval = defaults.object(forKey: "updateInterval") as? TimeInterval ?? 2.0
        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")

        self.cpuEnabled = defaults.object(forKey: "cpuEnabled") as? Bool ?? true
        self.memoryEnabled = defaults.object(forKey: "memoryEnabled") as? Bool ?? true
        self.networkEnabled = defaults.object(forKey: "networkEnabled") as? Bool ?? true
        self.diskEnabled = defaults.object(forKey: "diskEnabled") as? Bool ?? true
        self.dynamicEnabled = defaults.object(forKey: "dynamicEnabled") as? Bool ?? true

        self.cpuDisplayMode = MetricDisplayMode(rawValue: defaults.string(forKey: "cpuDisplayMode") ?? "") ?? .graph
        self.memoryDisplayMode = MetricDisplayMode(rawValue: defaults.string(forKey: "memoryDisplayMode") ?? "") ?? .graph
        self.networkDisplayMode = MetricDisplayMode(rawValue: defaults.string(forKey: "networkDisplayMode") ?? "") ?? .graph
        self.diskDisplayMode = MetricDisplayMode(rawValue: defaults.string(forKey: "diskDisplayMode") ?? "") ?? .text

        self.cpuThreshold = Self.loadThreshold(key: "cpuThreshold") ?? ThresholdConfig(greenMax: 50, yellowMax: 80)
        self.memoryThreshold = Self.loadThreshold(key: "memoryThreshold") ?? ThresholdConfig(greenMax: 60, yellowMax: 85)
        self.networkThreshold = Self.loadThreshold(key: "networkThreshold") ?? ThresholdConfig(greenMax: 50, yellowMax: 80)
        self.diskThreshold = Self.loadThreshold(key: "diskThreshold") ?? ThresholdConfig(greenMax: 70, yellowMax: 90)
    }

    // MARK: - Private Helpers

    private func saveThreshold(_ threshold: ThresholdConfig, key: String) {
        if let data = try? JSONEncoder().encode(threshold) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private static func loadThreshold(key: String) -> ThresholdConfig? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(ThresholdConfig.self, from: data)
    }
}
