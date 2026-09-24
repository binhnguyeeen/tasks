import AppKit

enum ToolbarDisplayModes {
    static func limitToIcons() {
        let center = NotificationCenter.default
        center.addObserver(forName: NSMenu.didAddItemNotification, object: nil, queue: .main) { notification in
            nonisolated(unsafe) let menu = notification.object as? NSMenu
            let index = notification.userInfo?["NSMenuItemIndex"] as? Int
            MainActor.assumeIsolated {
                guard let menu, let index, index < menu.items.count else { return }
                hideIfTextOnly(menu.items[index])
            }
        }
        center.addObserver(forName: NSMenu.didEndTrackingNotification, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated {
                for toolbar in NSApp.windows.compactMap(\.toolbar) where toolbar.displayMode == .labelOnly {
                    toolbar.displayMode = .iconOnly
                }
            }
        }
    }

    private static func hideIfTextOnly(_ item: NSMenuItem) {
        let action = item.action.map(NSStringFromSelector) ?? ""
        if action.localizedCaseInsensitiveContains("displaymode"),
           item.tag == Int(NSToolbar.DisplayMode.labelOnly.rawValue) {
            item.isHidden = true
        }
    }
}
