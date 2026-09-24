import AppKit

enum DockPolicy {
    static func mainWindowDidOpen() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
    }

    static func mainWindowDidClose() {
        NSApp.setActivationPolicy(.accessory)
    }
}
