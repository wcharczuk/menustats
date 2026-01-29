import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let settings = AppSettings()
    let systemMonitor = SystemMonitor()
    private var statusItemManager: StatusItemManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItemManager = StatusItemManager(
            settings: settings,
            systemMonitor: systemMonitor
        )

        systemMonitor.startMonitoring()
    }

    func applicationWillTerminate(_ notification: Notification) {
        systemMonitor.stopMonitoring()
    }
}
