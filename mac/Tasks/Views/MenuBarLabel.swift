import SwiftUI

struct MenuBarLabel: View {
    let count: Int
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle")
            if count > 0 {
                Text(count, format: .number)
                    .monospacedDigit()
            }
        }
        .accessibilityLabel(count > 0 ? "Tasks, \(count) due" : "Tasks")
        .task {
            guard MainWindowRequest.isPendingAtLaunch else { return }
            MainWindowRequest.isPendingAtLaunch = false
            openMainWindow()
        }
        .onReceive(NotificationCenter.default.publisher(for: MainWindowRequest.notification)) { _ in
            openMainWindow()
        }
    }

    private func openMainWindow() {
        openWindow(id: WindowModel.mainWindowID)
        NSApp.activate()
    }
}
