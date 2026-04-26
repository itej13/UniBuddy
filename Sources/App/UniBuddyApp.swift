import AppKit
import GoogleSignIn
import SwiftUI

@main
struct UniBuddyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var authService = GoogleAuthService()
    @StateObject private var syncCoordinator = SyncCoordinator()
    @StateObject private var notificationService = NotificationService()
    @StateObject private var store = UniBuddyStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(syncCoordinator)
                .environmentObject(notificationService)
                .environmentObject(store)
                .task {
                    await authService.restorePreviousSignIn()
                }
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Sync Classroom") {
                    NotificationCenter.default.post(name: .syncClassroomRequested, object: nil)
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
        }

        Settings {
            SettingsView()
                .environmentObject(authService)
                .environmentObject(syncCoordinator)
                .environmentObject(notificationService)
                .environmentObject(store)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension Notification.Name {
    static let syncClassroomRequested = Notification.Name("syncClassroomRequested")
}
