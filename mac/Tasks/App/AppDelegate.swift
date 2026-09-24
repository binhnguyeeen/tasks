import AppKit

enum QuitPolicy {
    static var allowQuit = false
}

enum MainWindowRequest {
    static let notification = Notification.Name("com.binhnguyen.tasks.openMainWindow")
    static var isPendingAtLaunch = false
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var systemIsPoweringOff = false

    func applicationWillFinishLaunching(_ notification: Notification) {
        MainWindowRequest.isPendingAtLaunch = !launchedAsLoginItem()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if !hasVisibleWindows {
            NotificationCenter.default.post(name: MainWindowRequest.notification, object: nil)
        }
        return true
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        LoginItem.enableOnFirstLaunch()
        ToolbarDisplayModes.limitToIcons()
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(willPowerOff),
            name: NSWorkspace.willPowerOffNotification,
            object: nil
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if QuitPolicy.allowQuit || systemIsPoweringOff || isSystemQuit() {
            return .terminateNow
        }
        for window in sender.windows where window.isVisible && window.styleMask.contains(.titled) && !(window is NSPanel) {
            window.performClose(nil)
        }
        return .terminateCancel
    }

    @objc private func willPowerOff(_ notification: Notification) {
        systemIsPoweringOff = true
    }

    private func launchedAsLoginItem() -> Bool {
        guard let event = NSAppleEventManager.shared().currentAppleEvent,
              event.eventID == kAEOpenApplication
        else { return false }
        return event.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
    }

    private func isSystemQuit() -> Bool {
        guard let event = NSAppleEventManager.shared().currentAppleEvent,
              event.eventClass == kCoreEventClass,
              event.eventID == kAEQuitApplication,
              let reason = event.attributeDescriptor(forKeyword: kAEQuitReason)?.enumCodeValue
        else { return false }
        let systemReasons: Set<OSType> = [
            kAELogOut, kAEReallyLogOut, kAEShowRestartDialog, kAEShowShutdownDialog, kAERestart, kAEShutDown,
        ].map { OSType($0) }.reduce(into: []) { $0.insert($1) }
        return systemReasons.contains(reason)
    }
}
