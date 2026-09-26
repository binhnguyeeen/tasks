import AuthenticationServices
import SwiftUI

struct SignInView: View {
    enum Size {
        case dropdown
        case window
    }

    let size: Size
    @Environment(GoogleAuth.self) private var auth
    @Environment(TaskStore.self) private var store
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession
    @State private var isSigningIn = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: iconSize, height: iconSize)
                .accessibilityHidden(true)
            VStack(spacing: 6) {
                Text("Connect Google Tasks")
                    .font(size == .window ? .title2.bold() : .headline)
                Text("Sign in with your Google account to see and edit your tasks. Tasks only sees your tasks and your email address.")
                    .font(size == .window ? .body : .callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button("Sign In with Google…", action: signIn)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isSigningIn || !auth.isConfigured)
            if let message = errorMessage ?? (auth.isConfigured ? nil : GoogleAuth.AuthError.notConfigured.errorDescription) {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: size == .window ? 360 : .infinity)
        .padding(.horizontal, size == .window ? 0 : 8)
    }

    private var iconSize: CGFloat {
        size == .window ? 96 : 64
    }

    private func signIn() {
        isSigningIn = true
        errorMessage = nil
        Task {
            defer { isSigningIn = false }
            do {
                try await auth.signIn(with: webAuthenticationSession)
                await store.refresh()
            } catch let error as ASWebAuthenticationSessionError where error.code == .canceledLogin {
            } catch let error as GoogleAuth.AuthError {
                errorMessage = error.errorDescription
            } catch {
                errorMessage = GoogleAuth.AuthError.failed.errorDescription
            }
        }
    }
}
