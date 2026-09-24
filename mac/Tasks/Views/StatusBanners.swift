import SwiftUI

struct OfflineBanner: View {
    var body: some View {
        Label("You’re offline. Tasks can’t be changed until you reconnect.", systemImage: "wifi.slash")
            .font(.callout)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct NoticeBanner: View {
    let notice: TaskStore.Notice

    var body: some View {
        Label(notice.message, systemImage: "exclamationmark.triangle.fill")
            .font(.callout)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .transition(.opacity)
            .accessibilityAddTraits(.updatesFrequently)
    }
}
