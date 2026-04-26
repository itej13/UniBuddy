import SwiftUI
import AppKit

struct DashboardView: View {
    @EnvironmentObject private var store: UniBuddyStore
    @EnvironmentObject private var syncCoordinator: SyncCoordinator

    private var todaySlots: [TimetableSlot] {
        store.timetableSlots.filter { $0.weekday == Date.now.classroomWeekday }.sorted { $0.startMinutes < $1.startMinutes }
    }

    private var pendingAssignments: [ClassroomAssignment] {
        store.assignments
            .filter { !$0.submissionState.isComplete }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
            .prefix(6)
            .map { $0 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 14)], spacing: 14) {
                    MetricCard(title: "Subjects", value: "\(store.subjects.count)", systemImage: "books.vertical")
                    MetricCard(title: "Classroom", value: "\(store.classroomCourses.count) courses", systemImage: "graduationcap")
                    MetricCard(title: "Today", value: "\(todaySlots.count) classes", systemImage: "calendar")
                    MetricCard(title: "Pending", value: "\(store.assignments.filter { !$0.submissionState.isComplete }.count)", systemImage: "tray.full")
                    MetricCard(title: "Attendance", value: averageAttendance, systemImage: "chart.line.uptrend.xyaxis")
                }

                if let lastSummary = syncCoordinator.lastSummary {
                    Label(lastSummary, systemImage: "checkmark.circle")
                        .foregroundStyle(.secondary)
                }

                if let lastError = syncCoordinator.lastError {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(lastError)
                            .font(.callout)
                            .foregroundStyle(.red)
                            .textSelection(.enabled)
                        if let activationURL = syncCoordinator.activationURL {
                            Button {
                                NSWorkspace.shared.open(activationURL)
                            } label: {
                                Label("Enable Google Classroom API", systemImage: "arrow.up.right.square")
                            }
                        }
                    }
                }

                HStack(alignment: .top, spacing: 16) {
                    DashboardSection(title: "Today's Classes", systemImage: "clock") {
                        if todaySlots.isEmpty {
                            EmptyStateText("No timetable slots for today.")
                        } else {
                            ForEach(todaySlots) { slot in
                                SlotRow(slot: slot, subject: store.subjects.first { $0.id == slot.subjectID })
                            }
                        }
                    }

                    DashboardSection(title: "Upcoming Submissions", systemImage: "tray.full") {
                        if pendingAssignments.isEmpty {
                            EmptyStateText("No pending submissions from the last sync.")
                        } else {
                            ForEach(pendingAssignments) { assignment in
                                AssignmentRow(assignment: assignment)
                            }
                        }
                    }
                }

                DashboardSection(title: "Subject Analytics", systemImage: "chart.bar") {
                    ForEach(store.subjects.sorted { $0.name < $1.name }) { subject in
                        SubjectAnalyticsRow(subject: subject, records: store.attendanceRecords)
                    }
                }
            }
            .padding(24)
        }
        .navigationTitle("Dashboard")
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back\(store.profile.map { ", \($0.displayName)" } ?? "")")
                    .font(.largeTitle.bold())
                if let lastSync = store.profile?.lastSyncAt {
                    Text("Last synced \(lastSync.formatted(date: .abbreviated, time: .shortened))")
                        .foregroundStyle(.secondary)
                } else {
                    Text("Sync Classroom to pull your current coursework.")
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if syncCoordinator.isSyncing {
                ProgressView()
            }
        }
    }

    private var averageAttendance: String {
        guard !store.subjects.isEmpty else { return "0%" }
        let total = store.subjects.map { AttendanceAnalytics.percentage(for: $0, records: store.attendanceRecords) }.reduce(0, +)
        return (total / Double(store.subjects.count)).formatted(.percent.precision(.fractionLength(0)))
    }
}

struct MetricCard: View {
    var title: String
    var value: String
    var systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct DashboardSection<Content: View>: View {
    var title: String
    var systemImage: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.title2.bold())
            VStack(alignment: .leading, spacing: 10) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

struct EmptyStateText: View {
    var text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SlotRow: View {
    var slot: TimetableSlot
    var subject: Subject?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(subject?.name ?? "Unknown Subject")
                    .font(.headline)
                Text("\(UniBuddyFormatters.minutesToTime(slot.startMinutes)) - \(UniBuddyFormatters.minutesToTime(slot.endMinutes))")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(slot.weekday.shortName)
                .font(.caption.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary)
                .clipShape(Capsule())
        }
    }
}

struct AssignmentRow: View {
    var assignment: ClassroomAssignment

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(assignment.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(assignment.courseName)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if let dueDate = assignment.dueDate {
                    Text("Due \(dueDate.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(dueDate < .now && !assignment.submissionState.isComplete ? .red : .secondary)
                }
            }
            Spacer()
            Text(assignment.submissionState.title)
                .font(.caption.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary)
                .clipShape(Capsule())
        }
    }
}

struct SubjectAnalyticsRow: View {
    var subject: Subject
    var records: [AttendanceRecord]

    var body: some View {
        let percentage = AttendanceAnalytics.percentage(for: subject, records: records)
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(subject.name)
                    .font(.headline)
                Spacer()
                Text(percentage.formatted(.percent.precision(.fractionLength(0))))
                    .font(.headline)
            }
            ProgressView(value: percentage)
        }
    }
}
