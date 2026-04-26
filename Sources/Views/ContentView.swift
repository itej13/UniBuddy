import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case dashboard
    case subjects
    case timetable
    case submissions
    case attendance
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: "Dashboard"
        case .subjects: "Subjects"
        case .timetable: "Timetable"
        case .submissions: "Submissions"
        case .attendance: "Attendance"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: "rectangle.3.group"
        case .subjects: "books.vertical"
        case .timetable: "tablecells"
        case .submissions: "tray.full"
        case .attendance: "calendar.badge.checkmark"
        case .settings: "gearshape"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var authService: GoogleAuthService
    @EnvironmentObject private var syncCoordinator: SyncCoordinator
    @EnvironmentObject private var notificationService: NotificationService
    @EnvironmentObject private var store: UniBuddyStore

    @SceneStorage("selectedSidebarItem") private var selectedRawValue = SidebarItem.dashboard.rawValue

    private var selection: Binding<SidebarItem> {
        Binding {
            SidebarItem(rawValue: selectedRawValue) ?? .dashboard
        } set: {
            selectedRawValue = $0.rawValue
        }
    }

    var body: some View {
        Group {
            if store.profile == nil || store.subjects.isEmpty {
                OnboardingView()
            } else {
                NavigationSplitView {
                    List(selection: selection) {
                        ForEach(SidebarItem.allCases) { item in
                            Label(item.title, systemImage: item.systemImage)
                                .tag(item)
                        }
                    }
                    .listStyle(.sidebar)
                    .navigationTitle("UniBuddy")
                } detail: {
                    detailView
                }
                .toolbar {
                    ToolbarItemGroup {
                        Button {
                            Task { await sync() }
                        } label: {
                            Label("Sync", systemImage: syncCoordinator.isSyncing ? "arrow.triangle.2.circlepath.circle" : "arrow.triangle.2.circlepath")
                        }
                        .disabled(syncCoordinator.isSyncing)
                    }
                }
                .task {
                    syncCoordinator.startDailySync(
                        accessTokenProvider: { authService.accessToken },
                        storeProvider: { store }
                    )
                    await sync()
                    await notificationService.scheduleAttendancePrompts(slots: store.timetableSlots, subjects: store.subjects)
                }
                .onReceive(NotificationCenter.default.publisher(for: .syncClassroomRequested)) { _ in
                    Task { await sync() }
                }
            }
        }
        .frame(minWidth: 980, minHeight: 680)
    }

    @ViewBuilder
    private var detailView: some View {
        switch selection.wrappedValue {
        case .dashboard:
            DashboardView()
        case .subjects:
            SubjectsView()
        case .timetable:
            TimetableView()
        case .submissions:
            SubmissionsView()
        case .attendance:
            AttendanceView()
        case .settings:
            SettingsView()
        }
    }

    private func sync() async {
        let token = await authService.refreshedAccessToken()
        await syncCoordinator.sync(accessToken: token, store: store)
        await notificationService.scheduleAssignmentReminders(assignments: store.assignments)
    }
}
