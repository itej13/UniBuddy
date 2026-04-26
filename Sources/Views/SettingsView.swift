import ServiceManagement
import SwiftUI
import AppKit

struct SettingsView: View {
    @EnvironmentObject private var authService: GoogleAuthService
    @EnvironmentObject private var syncCoordinator: SyncCoordinator
    @EnvironmentObject private var notificationService: NotificationService
    @EnvironmentObject private var store: UniBuddyStore
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @State private var launchAtLoginError: String?

    var body: some View {
        Form {
            Section("Google") {
                if let user = authService.currentUser {
                    LabeledContent("Signed in", value: user.profile?.email ?? "Google account")
                    Button("Sign Out") {
                        authService.signOut()
                    }
                } else {
                    Button {
                        Task { await authService.signIn() }
                    } label: {
                        Label("Sign in with Google", systemImage: "person.crop.circle.badge.checkmark")
                    }
                    if !authService.isConfigured {
                        Text("Add GIDClientID and the reversed URL scheme in script/build_and_run.sh to enable real Google login.")
                            .foregroundStyle(.orange)
                    }
                }
                if let error = authService.authError {
                    Text(error).foregroundStyle(.red)
                }
            }

            Section("Notifications") {
                LabeledContent("Permission", value: notificationStatusText)
                Button("Request Notification Permission") {
                    Task { await notificationService.requestAuthorization() }
                }
                if let error = notificationService.lastError {
                    Text(error).foregroundStyle(.red)
                }
            }

            Section("Background") {
                Toggle("Launch at login", isOn: Binding {
                    launchAtLogin
                } set: { newValue in
                    setLaunchAtLogin(newValue)
                })
                if let launchAtLoginError {
                    Text(launchAtLoginError).foregroundStyle(.orange)
                }
                Text("UniBuddy syncs on launch and once per day while running.")
                    .foregroundStyle(.secondary)
            }

            Section("Local Data") {
                if let profile = store.profile {
                    LabeledContent("Profile", value: profile.email)
                    if let lastSyncAt = profile.lastSyncAt {
                        LabeledContent("Last Classroom sync", value: lastSyncAt.formatted(date: .abbreviated, time: .shortened))
                    }
                }
                LabeledContent("Classroom courses", value: "\(store.classroomCourses.count)")
                LabeledContent("Assignments", value: "\(store.assignments.count)")
                if let summary = syncCoordinator.lastSummary {
                    Text(summary).foregroundStyle(.secondary)
                }
                if let error = syncCoordinator.lastError {
                    Text(error)
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                }
                if let activationURL = syncCoordinator.activationURL {
                    Button {
                        NSWorkspace.shared.open(activationURL)
                    } label: {
                        Label("Enable Google Classroom API", systemImage: "arrow.up.right.square")
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding(24)
        .navigationTitle("Settings")
        .task {
            await notificationService.refreshAuthorizationStatus()
        }
    }

    private var notificationStatusText: String {
        switch notificationService.authorizationStatus {
        case .authorized: "Allowed"
        case .denied: "Denied"
        case .notDetermined: "Not requested"
        case .provisional: "Provisional"
        case .ephemeral: "Ephemeral"
        @unknown default: "Unknown"
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLogin = enabled
            launchAtLoginError = nil
        } catch {
            launchAtLogin = false
            launchAtLoginError = "Launch at login may require a signed app bundle: \(error.localizedDescription)"
        }
    }
}
