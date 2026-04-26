import AppKit
import Combine
import Foundation
import GoogleSignIn

@MainActor
final class GoogleAuthService: ObservableObject {
    @Published private(set) var currentUser: GIDGoogleUser?
    @Published private(set) var isRestoring = false
    @Published var authError: String?

    let classroomScopes = [
        "https://www.googleapis.com/auth/classroom.courses.readonly",
        "https://www.googleapis.com/auth/classroom.coursework.me.readonly"
    ]

    var isConfigured: Bool {
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String else {
            return false
        }
        return !clientID.isEmpty && !clientID.contains("YOUR_GOOGLE_CLIENT_ID")
    }

    var accessToken: String? {
        currentUser?.accessToken.tokenString
    }

    var userProfile: GoogleUserProfile? {
        guard let currentUser else { return nil }
        return GoogleUserProfile(
            email: currentUser.profile?.email ?? "unknown",
            name: currentUser.profile?.name ?? "Student",
            photoURL: currentUser.profile?.imageURL(withDimension: 128)?.absoluteString
        )
    }

    init() {
        configureIfPossible()
    }

    func configureIfPossible() {
        guard isConfigured,
              let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String
        else { return }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
    }

    func restorePreviousSignIn() async {
        configureIfPossible()
        guard isConfigured else { return }
        isRestoring = true
        defer { isRestoring = false }

        do {
            currentUser = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
            authError = nil
        } catch {
            currentUser = nil
        }
    }

    func signIn() async {
        configureIfPossible()
        guard isConfigured else {
            authError = "Add your Google OAuth client ID to script/build_and_run.sh before signing in."
            return
        }

        guard let presentingWindow = NSApp.keyWindow ?? NSApp.windows.first else {
            authError = "Open the main UniBuddy window before signing in."
            return
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: presentingWindow,
                hint: nil,
                additionalScopes: classroomScopes
            )
            currentUser = result.user
            authError = nil
        } catch {
            authError = error.localizedDescription
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        currentUser = nil
    }

    func refreshedAccessToken() async -> String? {
        guard let currentUser else {
            authError = "Sign in with Google before syncing Classroom."
            return nil
        }

        return await withCheckedContinuation { continuation in
            currentUser.refreshTokensIfNeeded { [weak self] user, error in
                let token = user?.accessToken.tokenString
                let message = error?.localizedDescription
                Task { @MainActor in
                    if let message {
                        self?.authError = message
                        continuation.resume(returning: nil)
                        return
                    }

                    if let token {
                        self?.authError = nil
                        continuation.resume(returning: token)
                    } else {
                        self?.authError = "Google did not return a refreshed access token."
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
    }
}
