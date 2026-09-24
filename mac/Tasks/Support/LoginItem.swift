import Foundation
import ServiceManagement

enum LoginItem {
    private static let setUpKey = "didSetUpLoginItem"

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }

    static func enableOnFirstLaunch() {
        #if DEBUG
        return
        #else
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: setUpKey) else { return }
        try? setEnabled(true)
        defaults.set(true, forKey: setUpKey)
        #endif
    }
}
