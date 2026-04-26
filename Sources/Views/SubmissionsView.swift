import AppKit
import SwiftUI

struct SubmissionsView: View {
    @EnvironmentObject private var store: UniBuddyStore

    private var overdue: [ClassroomAssignment] {
        store.assignments.filter { !$0.submissionState.isComplete && ($0.dueDate ?? .distantFuture) < .now }
    }

    private var upcoming: [ClassroomAssignment] {
        store.assignments.filter { !$0.submissionState.isComplete && ($0.dueDate ?? .distantFuture) >= .now }
    }

    private var complete: [ClassroomAssignment] {
        store.assignments.filter { $0.submissionState.isComplete }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SubmissionGroup(title: "Overdue", systemImage: "exclamationmark.triangle", assignments: overdue)
                SubmissionGroup(title: "Upcoming", systemImage: "calendar", assignments: upcoming)
                SubmissionGroup(title: "Completed", systemImage: "checkmark.circle", assignments: complete)
            }
            .padding(24)
        }
        .navigationTitle("Submissions")
    }
}

private struct SubmissionGroup: View {
    var title: String
    var systemImage: String
    var assignments: [ClassroomAssignment]

    var body: some View {
        DashboardSection(title: title, systemImage: systemImage) {
            if assignments.isEmpty {
                EmptyStateText("Nothing here.")
            } else {
                ForEach(assignments) { assignment in
                    HStack(alignment: .top, spacing: 12) {
                        AssignmentRow(assignment: assignment)
                        if let link = assignment.alternateLink, let url = URL(string: link) {
                            Button {
                                NSWorkspace.shared.open(url)
                            } label: {
                                Label("Open", systemImage: "arrow.up.right.square")
                            }
                            .labelStyle(.iconOnly)
                            .help("Open in Google Classroom")
                        }
                    }
                    Divider()
                }
            }
        }
    }
}
