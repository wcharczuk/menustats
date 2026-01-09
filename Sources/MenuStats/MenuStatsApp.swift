import SwiftUI

@main
struct MenuStatsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            PreferencesWindow()
                .environment(appDelegate.settings)
                .environment(appDelegate.systemMonitor)
        }
    }
}
