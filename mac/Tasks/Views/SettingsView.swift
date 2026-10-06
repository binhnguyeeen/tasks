import SwiftUI

struct SettingsView: View {
    @Environment(GoogleAuth.self) private var auth
    @Environment(TaskStore.self) private var store
    @Environment(Reminders.self) private var reminders
    @State private var opensAtLogin = LoginItem.isEnabled
    @State private var isConfirmingSignOut = false

    var body: some View {
        Form {
            Section("Account") {
                HStack(spacing: 10) {
                    Image(systemName: "person.crop.circle")
                        .font(.title)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading) {
                        Text(auth.isSignedIn ? (auth.email ?? "Google Account") : "Not Signed In")
                        Text("Google Tasks")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if auth.isSignedIn {
                        Button("Sign Out…") { isConfirmingSignOut = true }
                    }
                }
            }
            Section("General") {
                Toggle("Open at Login", isOn: $opensAtLogin)
                    .onChange(of: opensAtLogin) { _, enabled in
                        try? LoginItem.setEnabled(enabled)
                        opensAtLogin = LoginItem.isEnabled
                    }
            }
            remindersSection
            Section("About") {
                LabeledContent("Version", value: version)
                Link("Privacy Policy", destination: URL(string: "https://binhnguyeeen.github.io/tasks/privacy.html")!)
                Link("Terms of Service", destination: URL(string: "https://binhnguyeeen.github.io/tasks/terms.html")!)
                Link("Source on GitHub", destination: URL(string: "https://github.com/binhnguyeeen/tasks")!)
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
        .confirmationDialog("Sign out of Google Tasks?", isPresented: $isConfirmingSignOut, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                Task {
                    await auth.signOut()
                    store.reset()
                }
            }
        } message: {
            Text("Tasks will stop showing your tasks until you sign in again.")
        }
    }

    private var remindersSection: some View {
        @Bindable var reminders = reminders
        return Section {
            Toggle("Due Date Reminders", isOn: $reminders.isEnabled)
            DatePicker("Remind At", selection: $reminders.time, displayedComponents: .hourAndMinute)
                .disabled(!reminders.isEnabled)
            if reminders.isEnabled && reminders.authorization == .denied {
                LabeledContent {
                    Button("Open System Settings…") {
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension")!)
                    }
                } label: {
                    Text("Notifications Are Off")
                    Text("Allow notifications for Tasks in System Settings.")
                }
            }
        } header: {
            Text("Reminders")
        } footer: {
            Text("A notification for each task on the day it’s due, with a Mark as Done button.")
                .foregroundStyle(.secondary)
        }
        .task { await reminders.refreshAuthorization() }
    }

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }
}
