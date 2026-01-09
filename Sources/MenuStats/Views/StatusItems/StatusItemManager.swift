import AppKit
import SwiftUI

@MainActor
final class StatusItemManager: NSObject, NSMenuDelegate {
    private let settings: AppSettings
    private let systemMonitor: SystemMonitor

    // Consistent small font for all menu bar text
    private let menuBarFont = NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .medium)

    private var cpuStatusItem: NSStatusItem?
    private var memoryStatusItem: NSStatusItem?
    private var networkStatusItem: NSStatusItem?
    private var diskStatusItem: NSStatusItem?
    private var dynamicStatusItem: NSStatusItem?

    private var observationTask: Task<Void, Never>?
    private var preferencesWindow: NSWindow?

    private enum MenuType {
        case cpu, memory, network, disk, dynamic
    }
    private var menuTypeMap: [NSMenu: MenuType] = [:]

    init(settings: AppSettings, systemMonitor: SystemMonitor) {
        self.settings = settings
        self.systemMonitor = systemMonitor
        super.init()
        setupStatusItems()
        startObserving()
    }

    private func setupStatusItems() {
        updateStatusItemVisibility()
    }

    private func startObserving() {
        observationTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.updateStatusItemVisibility()
                self?.updateAllStatusItems()
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }

    private func updateStatusItemVisibility() {
        // Order: NET, MEM, CPU, DSK (left to right)
        // Create in reverse order since newer items appear to the left

        // Disk (rightmost)
        if settings.diskEnabled && settings.diskDisplayMode != .hidden {
            if diskStatusItem == nil {
                diskStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
                setupStatusItemMenu(diskStatusItem, type: .disk)
            }
        } else {
            if let item = diskStatusItem {
                if let menu = item.menu { menuTypeMap.removeValue(forKey: menu) }
                NSStatusBar.system.removeStatusItem(item)
                diskStatusItem = nil
            }
        }

        // CPU
        if settings.cpuEnabled && settings.cpuDisplayMode != .hidden {
            if cpuStatusItem == nil {
                cpuStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
                setupStatusItemMenu(cpuStatusItem, type: .cpu)
            }
        } else {
            if let item = cpuStatusItem {
                if let menu = item.menu { menuTypeMap.removeValue(forKey: menu) }
                NSStatusBar.system.removeStatusItem(item)
                cpuStatusItem = nil
            }
        }

        // Memory
        if settings.memoryEnabled && settings.memoryDisplayMode != .hidden {
            if memoryStatusItem == nil {
                memoryStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
                setupStatusItemMenu(memoryStatusItem, type: .memory)
            }
        } else {
            if let item = memoryStatusItem {
                if let menu = item.menu { menuTypeMap.removeValue(forKey: menu) }
                NSStatusBar.system.removeStatusItem(item)
                memoryStatusItem = nil
            }
        }

        // Network
        if settings.networkEnabled && settings.networkDisplayMode != .hidden {
            if networkStatusItem == nil {
                networkStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
                setupStatusItemMenu(networkStatusItem, type: .network)
            }
        } else {
            if let item = networkStatusItem {
                if let menu = item.menu { menuTypeMap.removeValue(forKey: menu) }
                NSStatusBar.system.removeStatusItem(item)
                networkStatusItem = nil
            }
        }

        // Dynamic (leftmost)
        if settings.dynamicEnabled {
            if dynamicStatusItem == nil {
                dynamicStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
                setupStatusItemMenu(dynamicStatusItem, type: .dynamic)
            }
        } else {
            if let item = dynamicStatusItem {
                if let menu = item.menu { menuTypeMap.removeValue(forKey: menu) }
                NSStatusBar.system.removeStatusItem(item)
                dynamicStatusItem = nil
            }
        }
    }

    private func setupStatusItemMenu(_ statusItem: NSStatusItem?, type: MenuType) {
        guard let statusItem = statusItem else { return }
        let menu = NSMenu()
        menu.delegate = self
        menuTypeMap[menu] = type
        statusItem.menu = menu
    }

    // MARK: - NSMenuDelegate

    func menuWillOpen(_ menu: NSMenu) {
        guard let type = menuTypeMap[menu] else { return }
        menu.removeAllItems()

        switch type {
        case .cpu: populateCPUMenu(menu)
        case .memory: populateMemoryMenu(menu)
        case .network: populateNetworkMenu(menu)
        case .disk: populateDiskMenu(menu)
        case .dynamic: populateDynamicMenu(menu)
        }
    }

    private func updateAllStatusItems() {
        updateCPUStatusItem()
        updateMemoryStatusItem()
        updateNetworkStatusItem()
        updateDiskStatusItem()
        updateDynamicStatusItem()
    }

    private func updateCPUStatusItem() {
        guard let statusItem = cpuStatusItem else { return }

        let metrics = systemMonitor.cpuMetrics

        switch settings.cpuDisplayMode {
        case .text:
            let view = NSHostingView(rootView: CPUTextItemView(
                metrics: metrics,
                threshold: settings.cpuThreshold
            ))
            view.frame = NSRect(x: 0, y: 0, width: 38, height: 22)
            statusItem.button?.subviews.forEach { $0.removeFromSuperview() }
            statusItem.button?.addSubview(view)
            statusItem.button?.title = ""
            statusItem.length = 38

        case .graph:
            let view = NSHostingView(rootView: CPUStatusItemView(
                metrics: metrics,
                threshold: settings.cpuThreshold
            ))
            view.frame = NSRect(x: 0, y: 0, width: 36, height: 22)
            statusItem.button?.subviews.forEach { $0.removeFromSuperview() }
            statusItem.button?.addSubview(view)
            statusItem.button?.title = ""
            statusItem.length = 36

        case .hidden:
            break
        }
    }

    private func updateMemoryStatusItem() {
        guard let statusItem = memoryStatusItem else { return }

        let metrics = systemMonitor.memoryMetrics

        switch settings.memoryDisplayMode {
        case .text:
            let view = NSHostingView(rootView: MemoryTextItemView(
                metrics: metrics,
                threshold: settings.memoryThreshold
            ))
            view.frame = NSRect(x: 0, y: 0, width: 38, height: 22)
            statusItem.button?.subviews.forEach { $0.removeFromSuperview() }
            statusItem.button?.addSubview(view)
            statusItem.button?.title = ""
            statusItem.length = 38

        case .graph:
            let view = NSHostingView(rootView: MemoryStatusItemView(
                metrics: metrics,
                threshold: settings.memoryThreshold
            ))
            view.frame = NSRect(x: 0, y: 0, width: 18, height: 22)
            statusItem.button?.subviews.forEach { $0.removeFromSuperview() }
            statusItem.button?.addSubview(view)
            statusItem.button?.title = ""
            statusItem.length = 18

        case .hidden:
            break
        }
    }

    private func updateNetworkStatusItem() {
        guard let statusItem = networkStatusItem else { return }

        let metrics = systemMonitor.networkMetrics

        switch settings.networkDisplayMode {
        case .text:
            let view = NSHostingView(rootView: NetworkTextItemView(
                metrics: metrics
            ))
            view.frame = NSRect(x: 0, y: 0, width: 48, height: 22)
            statusItem.button?.subviews.forEach { $0.removeFromSuperview() }
            statusItem.button?.addSubview(view)
            statusItem.button?.title = ""
            statusItem.length = 48

        case .graph:
            let view = NSHostingView(rootView: NetworkStatusItemView(
                metrics: metrics,
                threshold: settings.networkThreshold
            ))
            view.frame = NSRect(x: 0, y: 0, width: 42, height: 22)
            statusItem.button?.subviews.forEach { $0.removeFromSuperview() }
            statusItem.button?.addSubview(view)
            statusItem.button?.title = ""
            statusItem.length = 42

        case .hidden:
            break
        }
    }

    private func updateDiskStatusItem() {
        guard let statusItem = diskStatusItem else { return }

        let metrics = systemMonitor.diskMetrics

        switch settings.diskDisplayMode {
        case .text:
            let view = NSHostingView(rootView: DiskTextItemView(
                metrics: metrics,
                threshold: settings.diskThreshold
            ))
            view.frame = NSRect(x: 0, y: 0, width: 38, height: 22)
            statusItem.button?.subviews.forEach { $0.removeFromSuperview() }
            statusItem.button?.addSubview(view)
            statusItem.button?.title = ""
            statusItem.length = 38

        case .graph:
            let view = NSHostingView(rootView: DiskStatusItemView(
                metrics: metrics,
                threshold: settings.diskThreshold
            ))
            view.frame = NSRect(x: 0, y: 0, width: 18, height: 22)
            statusItem.button?.subviews.forEach { $0.removeFromSuperview() }
            statusItem.button?.addSubview(view)
            statusItem.button?.title = ""
            statusItem.length = 18

        case .hidden:
            break
        }
    }

    private func updateDynamicStatusItem() {
        guard let statusItem = dynamicStatusItem else { return }

        let rootView = DynamicStatusItemView(
            cpuMetrics: systemMonitor.cpuMetrics,
            memoryMetrics: systemMonitor.memoryMetrics,
            networkMetrics: systemMonitor.networkMetrics,
            diskMetrics: systemMonitor.diskMetrics,
            cpuThreshold: settings.cpuThreshold,
            memoryThreshold: settings.memoryThreshold,
            networkThreshold: settings.networkThreshold,
            diskThreshold: settings.diskThreshold
        )
        let view = NSHostingView(rootView: rootView)
        let fittingSize = view.fittingSize
        view.frame = NSRect(x: 0, y: 0, width: max(fittingSize.width, 22), height: 22)
        statusItem.button?.subviews.forEach { $0.removeFromSuperview() }
        statusItem.button?.addSubview(view)
        statusItem.button?.title = ""
        statusItem.length = max(fittingSize.width, 22)
    }

    // MARK: - Menu Population

    private func populateCPUMenu(_ menu: NSMenu) {
        let metrics = systemMonitor.cpuMetrics

        // Header
        let headerItem = NSMenuItem(title: "CPU Usage", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        // Current value
        let valueItem = NSMenuItem(
            title: String(format: "Total: %.1f%%", metrics.totalUsage),
            action: nil,
            keyEquivalent: ""
        )
        valueItem.isEnabled = false
        menu.addItem(valueItem)

        // Per-core summary
        let pCores = metrics.coreUsages.filter { $0.coreType == .performance }
        let eCores = metrics.coreUsages.filter { $0.coreType == .efficiency }

        if !pCores.isEmpty {
            let pAvg = pCores.map(\.usage).reduce(0, +) / Double(pCores.count)
            let pItem = NSMenuItem(
                title: String(format: "P-Cores (%d): %.1f%% avg", pCores.count, pAvg),
                action: nil,
                keyEquivalent: ""
            )
            pItem.isEnabled = false
            menu.addItem(pItem)
        }

        if !eCores.isEmpty {
            let eAvg = eCores.map(\.usage).reduce(0, +) / Double(eCores.count)
            let eItem = NSMenuItem(
                title: String(format: "E-Cores (%d): %.1f%% avg", eCores.count, eAvg),
                action: nil,
                keyEquivalent: ""
            )
            eItem.isEnabled = false
            menu.addItem(eItem)
        }

        addCommonMenuItems(to: menu)
    }

    private func populateMemoryMenu(_ menu: NSMenu) {
        let metrics = systemMonitor.memoryMetrics

        // Header
        let headerItem = NSMenuItem(title: "Memory Usage", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        // Current values
        let percentItem = NSMenuItem(
            title: String(format: "Used: %.1f%%", metrics.usagePercentage),
            action: nil,
            keyEquivalent: ""
        )
        percentItem.isEnabled = false
        menu.addItem(percentItem)

        let absItem = NSMenuItem(
            title: String(format: "%.2f / %.2f GiB", metrics.usedGiB, metrics.totalGiB),
            action: nil,
            keyEquivalent: ""
        )
        absItem.isEnabled = false
        menu.addItem(absItem)

        menu.addItem(NSMenuItem.separator())

        // Breakdown
        let activeItem = NSMenuItem(
            title: String(format: "Active: %@", ByteFormatter.format(metrics.activeBytes)),
            action: nil,
            keyEquivalent: ""
        )
        activeItem.isEnabled = false
        menu.addItem(activeItem)

        let wiredItem = NSMenuItem(
            title: String(format: "Wired: %@", ByteFormatter.format(metrics.wiredBytes)),
            action: nil,
            keyEquivalent: ""
        )
        wiredItem.isEnabled = false
        menu.addItem(wiredItem)

        let compressedItem = NSMenuItem(
            title: String(format: "Compressed: %@", ByteFormatter.format(metrics.compressedBytes)),
            action: nil,
            keyEquivalent: ""
        )
        compressedItem.isEnabled = false
        menu.addItem(compressedItem)

        addCommonMenuItems(to: menu)
    }

    private func populateNetworkMenu(_ menu: NSMenu) {
        let metrics = systemMonitor.networkMetrics

        // Header
        let headerItem = NSMenuItem(title: "Network Activity", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        // Current rates
        let uploadItem = NSMenuItem(
            title: String(format: "↑ Upload: %@/s", ByteFormatter.format(metrics.bytesSentPerSecond)),
            action: nil,
            keyEquivalent: ""
        )
        uploadItem.isEnabled = false
        menu.addItem(uploadItem)

        let downloadItem = NSMenuItem(
            title: String(format: "↓ Download: %@/s", ByteFormatter.format(metrics.bytesReceivedPerSecond)),
            action: nil,
            keyEquivalent: ""
        )
        downloadItem.isEnabled = false
        menu.addItem(downloadItem)

        menu.addItem(NSMenuItem.separator())

        // Totals
        let totalUpItem = NSMenuItem(
            title: String(format: "Total Sent: %@", ByteFormatter.format(metrics.totalBytesSent)),
            action: nil,
            keyEquivalent: ""
        )
        totalUpItem.isEnabled = false
        menu.addItem(totalUpItem)

        let totalDownItem = NSMenuItem(
            title: String(format: "Total Received: %@", ByteFormatter.format(metrics.totalBytesReceived)),
            action: nil,
            keyEquivalent: ""
        )
        totalDownItem.isEnabled = false
        menu.addItem(totalDownItem)

        addCommonMenuItems(to: menu)
    }

    private func populateDiskMenu(_ menu: NSMenu) {
        let metrics = systemMonitor.diskMetrics

        // Header
        let headerItem = NSMenuItem(title: "Disk Usage", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        // Current values
        let percentItem = NSMenuItem(
            title: String(format: "Used: %.1f%%", metrics.usagePercentage),
            action: nil,
            keyEquivalent: ""
        )
        percentItem.isEnabled = false
        menu.addItem(percentItem)

        menu.addItem(NSMenuItem.separator())

        let usedItem = NSMenuItem(
            title: String(format: "Used: %.2f GiB", metrics.usedGiB),
            action: nil,
            keyEquivalent: ""
        )
        usedItem.isEnabled = false
        menu.addItem(usedItem)

        let freeItem = NSMenuItem(
            title: String(format: "Free: %.2f GiB", metrics.freeGiB),
            action: nil,
            keyEquivalent: ""
        )
        freeItem.isEnabled = false
        menu.addItem(freeItem)

        let totalItem = NSMenuItem(
            title: String(format: "Total: %.2f GiB", metrics.totalGiB),
            action: nil,
            keyEquivalent: ""
        )
        totalItem.isEnabled = false
        menu.addItem(totalItem)

        addCommonMenuItems(to: menu)
    }

    private func populateDynamicMenu(_ menu: NSMenu) {
        // Header
        let headerItem = NSMenuItem(title: "System Status", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        menu.addItem(NSMenuItem.separator())

        // Check each metric and add status
        let cpuMetrics = systemMonitor.cpuMetrics
        let memoryMetrics = systemMonitor.memoryMetrics
        let networkMetrics = systemMonitor.networkMetrics
        let diskMetrics = systemMonitor.diskMetrics

        var hasIssues = false

        // CPU status
        if settings.cpuThreshold.isCritical(cpuMetrics.totalUsage) {
            let item = NSMenuItem(
                title: String(format: "⚠ CPU Critical: %.1f%%", cpuMetrics.totalUsage),
                action: nil,
                keyEquivalent: ""
            )
            item.isEnabled = false
            menu.addItem(item)
            hasIssues = true
        } else if settings.cpuThreshold.isWarning(cpuMetrics.totalUsage) {
            let item = NSMenuItem(
                title: String(format: "● CPU Warning: %.1f%%", cpuMetrics.totalUsage),
                action: nil,
                keyEquivalent: ""
            )
            item.isEnabled = false
            menu.addItem(item)
            hasIssues = true
        }

        // Memory status
        if settings.memoryThreshold.isCritical(memoryMetrics.usagePercentage) {
            let item = NSMenuItem(
                title: String(format: "⚠ Memory Critical: %.1f%%", memoryMetrics.usagePercentage),
                action: nil,
                keyEquivalent: ""
            )
            item.isEnabled = false
            menu.addItem(item)
            hasIssues = true
        } else if settings.memoryThreshold.isWarning(memoryMetrics.usagePercentage) {
            let item = NSMenuItem(
                title: String(format: "● Memory Warning: %.1f%%", memoryMetrics.usagePercentage),
                action: nil,
                keyEquivalent: ""
            )
            item.isEnabled = false
            menu.addItem(item)
            hasIssues = true
        }

        // Network status (same logic as in DynamicStatusItemView)
        let maxNetworkMBps = max(
            Double(networkMetrics.bytesSentPerSecond),
            Double(networkMetrics.bytesReceivedPerSecond)
        ) / (1024 * 1024)
        if settings.networkThreshold.isCritical(maxNetworkMBps) {
            let item = NSMenuItem(
                title: String(format: "⚠ Network Critical: %.1f MB/s", maxNetworkMBps),
                action: nil,
                keyEquivalent: ""
            )
            item.isEnabled = false
            menu.addItem(item)
            hasIssues = true
        } else if settings.networkThreshold.isWarning(maxNetworkMBps) {
            let item = NSMenuItem(
                title: String(format: "● Network Warning: %.1f MB/s", maxNetworkMBps),
                action: nil,
                keyEquivalent: ""
            )
            item.isEnabled = false
            menu.addItem(item)
            hasIssues = true
        }

        // Disk status
        if settings.diskThreshold.isCritical(diskMetrics.usagePercentage) {
            let item = NSMenuItem(
                title: String(format: "⚠ Disk Critical: %.1f%%", diskMetrics.usagePercentage),
                action: nil,
                keyEquivalent: ""
            )
            item.isEnabled = false
            menu.addItem(item)
            hasIssues = true
        } else if settings.diskThreshold.isWarning(diskMetrics.usagePercentage) {
            let item = NSMenuItem(
                title: String(format: "● Disk Warning: %.1f%%", diskMetrics.usagePercentage),
                action: nil,
                keyEquivalent: ""
            )
            item.isEnabled = false
            menu.addItem(item)
            hasIssues = true
        }

        if !hasIssues {
            let item = NSMenuItem(title: "✓ All systems normal", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        }

        addCommonMenuItems(to: menu)
    }

    private func addCommonMenuItems(to menu: NSMenu) {
        menu.addItem(NSMenuItem.separator())

        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit MenuStats", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    @objc func openPreferences() {
        if preferencesWindow == nil {
            let preferencesView = PreferencesWindow()
                .environment(settings)
                .environment(systemMonitor)

            let hostingController = NSHostingController(rootView: preferencesView)
            hostingController.sizingOptions = [.preferredContentSize]

            let window = NSWindow(contentViewController: hostingController)
            window.title = "MenuStats Preferences"
            window.styleMask = [.titled, .closable]
            window.center()

            preferencesWindow = window
        }

        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Helper Methods

    private func makeAttributedString(_ text: String, color: NSColor) -> NSAttributedString {
        NSAttributedString(
            string: text,
            attributes: [
                .font: menuBarFont,
                .foregroundColor: color
            ]
        )
    }
}
