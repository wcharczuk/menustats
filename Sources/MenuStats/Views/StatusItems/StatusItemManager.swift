import AppKit
import SwiftUI

@MainActor
final class StatusItemManager: NSObject, NSMenuDelegate {
    private let settings: AppSettings
    private let systemMonitor: SystemMonitor

    private var cpuStatusItem: NSStatusItem?
    private var memoryStatusItem: NSStatusItem?
    private var networkStatusItem: NSStatusItem?
    private var diskStatusItem: NSStatusItem?
    private var latencyStatusItem: NSStatusItem?
    private var dynamicStatusItem: NSStatusItem?

    private var observationTask: Task<Void, Never>?
    private var preferencesWindow: NSWindow?

    private enum MenuType {
        case cpu, memory, network, disk, latency, dynamic
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

        // Latency
        if settings.latencyEnabled && settings.latencyDisplayMode != .hidden {
            if latencyStatusItem == nil {
                latencyStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
                setupStatusItemMenu(latencyStatusItem, type: .latency)
            }
        } else {
            if let item = latencyStatusItem {
                if let menu = item.menu { menuTypeMap.removeValue(forKey: menu) }
                NSStatusBar.system.removeStatusItem(item)
                latencyStatusItem = nil
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
        case .latency: populateLatencyMenu(menu)
        case .dynamic: populateDynamicMenu(menu)
        }
    }

    private func updateAllStatusItems() {
        updateCPUStatusItem()
        updateMemoryStatusItem()
        updateNetworkStatusItem()
        updateDiskStatusItem()
        updateLatencyStatusItem()
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
            let fittingWidth = max(view.fittingSize.width, 38)
            view.frame = NSRect(x: 0, y: 0, width: fittingWidth, height: 22)
            statusItem.button?.subviews.forEach { $0.removeFromSuperview() }
            statusItem.button?.addSubview(view)
            statusItem.button?.title = ""
            statusItem.length = fittingWidth

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
            let fittingWidth = max(view.fittingSize.width, 38)
            view.frame = NSRect(x: 0, y: 0, width: fittingWidth, height: 22)
            statusItem.button?.subviews.forEach { $0.removeFromSuperview() }
            statusItem.button?.addSubview(view)
            statusItem.button?.title = ""
            statusItem.length = fittingWidth

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
            let fittingWidth = max(view.fittingSize.width, 38)
            view.frame = NSRect(x: 0, y: 0, width: fittingWidth, height: 22)
            statusItem.button?.subviews.forEach { $0.removeFromSuperview() }
            statusItem.button?.addSubview(view)
            statusItem.button?.title = ""
            statusItem.length = fittingWidth

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
            let fittingWidth = max(view.fittingSize.width, 38)
            view.frame = NSRect(x: 0, y: 0, width: fittingWidth, height: 22)
            statusItem.button?.subviews.forEach { $0.removeFromSuperview() }
            statusItem.button?.addSubview(view)
            statusItem.button?.title = ""
            statusItem.length = fittingWidth

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

    private func updateLatencyStatusItem() {
        guard let statusItem = latencyStatusItem else { return }

        let metrics = systemMonitor.latencyMetrics

        switch settings.latencyDisplayMode {
        case .text:
            let view = NSHostingView(rootView: LatencyTextItemView(
                metrics: metrics,
                threshold: settings.latencyThreshold
            ))
            let fittingWidth = max(view.fittingSize.width, 38)
            view.frame = NSRect(x: 0, y: 0, width: fittingWidth, height: 22)
            statusItem.button?.subviews.forEach { $0.removeFromSuperview() }
            statusItem.button?.addSubview(view)
            statusItem.button?.title = ""
            statusItem.length = fittingWidth

        case .graph:
            let view = NSHostingView(rootView: LatencyStatusItemView(
                metrics: metrics,
                threshold: settings.latencyThreshold
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

    private func updateDynamicStatusItem() {
        guard let statusItem = dynamicStatusItem else { return }

        let rootView = DynamicStatusItemView(
            cpuMetrics: systemMonitor.cpuMetrics,
            memoryMetrics: systemMonitor.memoryMetrics,
            networkMetrics: systemMonitor.networkMetrics,
            diskMetrics: systemMonitor.diskMetrics,
            latencyMetrics: systemMonitor.latencyMetrics,
            cpuThreshold: settings.cpuThreshold,
            memoryThreshold: settings.memoryThreshold,
            networkThreshold: settings.networkThreshold,
            diskThreshold: settings.diskThreshold,
            latencyThreshold: settings.latencyThreshold,
            cpuDisplayMode: settings.cpuDisplayMode,
            memoryDisplayMode: settings.memoryDisplayMode,
            networkDisplayMode: settings.networkDisplayMode,
            diskDisplayMode: settings.diskDisplayMode,
            latencyDisplayMode: settings.latencyDisplayMode,
            detectionMethod: settings.dynamicDetectionMethod,
            stdDevThreshold: settings.dynamicStdDevThreshold,
            minHistoryCount: settings.dynamicMinHistoryCount
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

        // Link speed
        let linkSpeedText = metrics.linkSpeedBitsPerSecond > 0
            ? formatLinkSpeed(metrics.linkSpeedBitsPerSecond)
            : "Unknown"
        let linkSpeedItem = NSMenuItem(
            title: "Link Speed: \(linkSpeedText)",
            action: nil,
            keyEquivalent: ""
        )
        linkSpeedItem.isEnabled = false
        menu.addItem(linkSpeedItem)

        menu.addItem(NSMenuItem.separator())

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

    private func populateLatencyMenu(_ menu: NSMenu) {
        let metrics = systemMonitor.latencyMetrics

        // Header
        let headerItem = NSMenuItem(title: "Network Latency", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        // Current value
        let valueItem = NSMenuItem(
            title: "Ping: \(metrics.formattedLatency)",
            action: nil,
            keyEquivalent: ""
        )
        valueItem.isEnabled = false
        menu.addItem(valueItem)

        // Host
        let hostItem = NSMenuItem(
            title: "Host: google.com",
            action: nil,
            keyEquivalent: ""
        )
        hostItem.isEnabled = false
        menu.addItem(hostItem)

        // Stats from history
        if !metrics.history.isEmpty {
            menu.addItem(NSMenuItem.separator())

            let minLatency = metrics.history.min() ?? 0
            let maxLatency = metrics.history.max() ?? 0
            let avgLatency = metrics.history.reduce(0, +) / Double(metrics.history.count)

            let minItem = NSMenuItem(
                title: String(format: "Min: %.1fms", minLatency),
                action: nil,
                keyEquivalent: ""
            )
            minItem.isEnabled = false
            menu.addItem(minItem)

            let maxItem = NSMenuItem(
                title: String(format: "Max: %.1fms", maxLatency),
                action: nil,
                keyEquivalent: ""
            )
            maxItem.isEnabled = false
            menu.addItem(maxItem)

            let avgItem = NSMenuItem(
                title: String(format: "Avg: %.1fms", avgLatency),
                action: nil,
                keyEquivalent: ""
            )
            avgItem.isEnabled = false
            menu.addItem(avgItem)
        }

        addCommonMenuItems(to: menu)
    }

    private func populateDynamicMenu(_ menu: NSMenu) {
        let cpuMetrics = systemMonitor.cpuMetrics
        let memoryMetrics = systemMonitor.memoryMetrics
        let networkMetrics = systemMonitor.networkMetrics
        let diskMetrics = systemMonitor.diskMetrics
        let latencyMetrics = systemMonitor.latencyMetrics

        // CPU Section
        let cpuHeader = NSMenuItem(title: "CPU Usage", action: nil, keyEquivalent: "")
        cpuHeader.isEnabled = false
        menu.addItem(cpuHeader)

        let cpuValue = NSMenuItem(
            title: String(format: "Total: %.1f%%", cpuMetrics.totalUsage),
            action: nil,
            keyEquivalent: ""
        )
        cpuValue.isEnabled = false
        menu.addItem(cpuValue)

        let pCores = cpuMetrics.coreUsages.filter { $0.coreType == .performance }
        let eCores = cpuMetrics.coreUsages.filter { $0.coreType == .efficiency }

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

        menu.addItem(NSMenuItem.separator())

        // Memory Section
        let memHeader = NSMenuItem(title: "Memory Usage", action: nil, keyEquivalent: "")
        memHeader.isEnabled = false
        menu.addItem(memHeader)

        let memPercent = NSMenuItem(
            title: String(format: "Used: %.1f%%", memoryMetrics.usagePercentage),
            action: nil,
            keyEquivalent: ""
        )
        memPercent.isEnabled = false
        menu.addItem(memPercent)

        let memAbs = NSMenuItem(
            title: String(format: "%.2f / %.2f GiB", memoryMetrics.usedGiB, memoryMetrics.totalGiB),
            action: nil,
            keyEquivalent: ""
        )
        memAbs.isEnabled = false
        menu.addItem(memAbs)

        let activeItem = NSMenuItem(
            title: String(format: "Active: %@", ByteFormatter.format(memoryMetrics.activeBytes)),
            action: nil,
            keyEquivalent: ""
        )
        activeItem.isEnabled = false
        menu.addItem(activeItem)

        let wiredItem = NSMenuItem(
            title: String(format: "Wired: %@", ByteFormatter.format(memoryMetrics.wiredBytes)),
            action: nil,
            keyEquivalent: ""
        )
        wiredItem.isEnabled = false
        menu.addItem(wiredItem)

        let compressedItem = NSMenuItem(
            title: String(format: "Compressed: %@", ByteFormatter.format(memoryMetrics.compressedBytes)),
            action: nil,
            keyEquivalent: ""
        )
        compressedItem.isEnabled = false
        menu.addItem(compressedItem)

        menu.addItem(NSMenuItem.separator())

        // Network Section
        let netHeader = NSMenuItem(title: "Network Activity", action: nil, keyEquivalent: "")
        netHeader.isEnabled = false
        menu.addItem(netHeader)

        let linkSpeedText = networkMetrics.linkSpeedBitsPerSecond > 0
            ? formatLinkSpeed(networkMetrics.linkSpeedBitsPerSecond)
            : "Unknown"
        let linkSpeedItem = NSMenuItem(
            title: "Link Speed: \(linkSpeedText)",
            action: nil,
            keyEquivalent: ""
        )
        linkSpeedItem.isEnabled = false
        menu.addItem(linkSpeedItem)

        let uploadItem = NSMenuItem(
            title: String(format: "↑ Upload: %@/s", ByteFormatter.format(networkMetrics.bytesSentPerSecond)),
            action: nil,
            keyEquivalent: ""
        )
        uploadItem.isEnabled = false
        menu.addItem(uploadItem)

        let downloadItem = NSMenuItem(
            title: String(format: "↓ Download: %@/s", ByteFormatter.format(networkMetrics.bytesReceivedPerSecond)),
            action: nil,
            keyEquivalent: ""
        )
        downloadItem.isEnabled = false
        menu.addItem(downloadItem)

        let totalUpItem = NSMenuItem(
            title: String(format: "Total Sent: %@", ByteFormatter.format(networkMetrics.totalBytesSent)),
            action: nil,
            keyEquivalent: ""
        )
        totalUpItem.isEnabled = false
        menu.addItem(totalUpItem)

        let totalDownItem = NSMenuItem(
            title: String(format: "Total Received: %@", ByteFormatter.format(networkMetrics.totalBytesReceived)),
            action: nil,
            keyEquivalent: ""
        )
        totalDownItem.isEnabled = false
        menu.addItem(totalDownItem)

        menu.addItem(NSMenuItem.separator())

        // Disk Section
        let diskHeader = NSMenuItem(title: "Disk Usage", action: nil, keyEquivalent: "")
        diskHeader.isEnabled = false
        menu.addItem(diskHeader)

        let diskPercent = NSMenuItem(
            title: String(format: "Used: %.1f%%", diskMetrics.usagePercentage),
            action: nil,
            keyEquivalent: ""
        )
        diskPercent.isEnabled = false
        menu.addItem(diskPercent)

        let usedItem = NSMenuItem(
            title: String(format: "Used: %.2f GiB", diskMetrics.usedGiB),
            action: nil,
            keyEquivalent: ""
        )
        usedItem.isEnabled = false
        menu.addItem(usedItem)

        let freeItem = NSMenuItem(
            title: String(format: "Free: %.2f GiB", diskMetrics.freeGiB),
            action: nil,
            keyEquivalent: ""
        )
        freeItem.isEnabled = false
        menu.addItem(freeItem)

        let totalItem = NSMenuItem(
            title: String(format: "Total: %.2f GiB", diskMetrics.totalGiB),
            action: nil,
            keyEquivalent: ""
        )
        totalItem.isEnabled = false
        menu.addItem(totalItem)

        menu.addItem(NSMenuItem.separator())

        // Latency Section
        let latencyHeader = NSMenuItem(title: "Network Latency", action: nil, keyEquivalent: "")
        latencyHeader.isEnabled = false
        menu.addItem(latencyHeader)

        let latencyValue = NSMenuItem(
            title: "Ping: \(latencyMetrics.formattedLatency)",
            action: nil,
            keyEquivalent: ""
        )
        latencyValue.isEnabled = false
        menu.addItem(latencyValue)

        if !latencyMetrics.history.isEmpty {
            let minLatency = latencyMetrics.history.min() ?? 0
            let maxLatency = latencyMetrics.history.max() ?? 0
            let avgLatency = latencyMetrics.history.reduce(0, +) / Double(latencyMetrics.history.count)

            let latencyStats = NSMenuItem(
                title: String(format: "Min/Avg/Max: %.0f/%.0f/%.0fms", minLatency, avgLatency, maxLatency),
                action: nil,
                keyEquivalent: ""
            )
            latencyStats.isEnabled = false
            menu.addItem(latencyStats)
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

            // Calculate the natural size of the content
            let fittingSize = hostingController.view.fittingSize

            let window = NSWindow(contentViewController: hostingController)
            window.title = "MenuStats Preferences"
            window.styleMask = [.titled, .closable]
            window.setContentSize(fittingSize)
            window.center()

            preferencesWindow = window
        }

        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
