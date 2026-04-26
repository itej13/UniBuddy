import Combine
import Foundation

@MainActor
final class SyncCoordinator: ObservableObject {
    @Published private(set) var isSyncing = false
    @Published var lastError: String?
    @Published private(set) var lastSummary: String?
    @Published var activationURL: URL?

    private var dailySyncTask: Task<Void, Never>?

    func sync(accessToken: String?, store: UniBuddyStore) async {
        guard let accessToken, !accessToken.isEmpty else {
            lastError = "Sign in with Google before syncing Classroom."
            return
        }

        isSyncing = true
        defer { isSyncing = false }

        do {
            let client = ClassroomAPIClient(accessToken: accessToken)
            let courses = try await client.listCourses()
            let subjects = store.subjects
            var syncedAssignments = 0
            var courseErrors: [String] = []

            store.classroomCourses = courses.map {
                ClassroomCourseInfo(id: $0.id, name: $0.name, section: $0.section, lastSyncedAt: .now)
            }

            for course in courses {
                let courseWork: [ClassroomCourseWork]
                let submissions: [ClassroomStudentSubmission]

                do {
                    courseWork = try await client.listCourseWork(courseID: course.id)
                    submissions = try await client.listSubmissions(courseID: course.id)
                } catch {
                    courseErrors.append("\(course.name): \(error.localizedDescription)")
                    continue
                }

                let submissionsByWorkID = Dictionary(uniqueKeysWithValues: submissions.map { ($0.courseWorkId, $0) })
                let linkedSubject = subjects.first { $0.classroomCourseID == course.id }

                for work in courseWork {
                    let submission = submissionsByWorkID[work.id]
                    let assignmentID = "\(course.id):\(work.id)"
                    let state = SubmissionState.fromClassroom(submission?.state)

                    if let index = store.assignments.firstIndex(where: { $0.id == assignmentID }) {
                        store.assignments[index].courseName = course.name
                        store.assignments[index].subjectID = linkedSubject?.id
                        store.assignments[index].title = work.title
                        store.assignments[index].details = work.description ?? ""
                        store.assignments[index].dueDate = work.resolvedDueDate
                        store.assignments[index].alternateLink = work.alternateLink ?? submission?.alternateLink
                        store.assignments[index].submissionState = state
                        store.assignments[index].maxPoints = work.maxPoints
                        store.assignments[index].lastSyncedAt = .now
                    } else {
                        store.assignments.append(ClassroomAssignment(
                            id: assignmentID,
                            courseID: course.id,
                            courseName: course.name,
                            courseWorkID: work.id,
                            subjectID: linkedSubject?.id,
                            title: work.title,
                            details: work.description ?? "",
                            dueDate: work.resolvedDueDate,
                            alternateLink: work.alternateLink ?? submission?.alternateLink,
                            submissionState: state,
                            maxPoints: work.maxPoints,
                            lastSyncedAt: .now
                        ))
                    }
                    syncedAssignments += 1
                }
            }

            store.profile?.lastSyncAt = .now
            store.save()
            lastSummary = "Synced \(courses.count) Classroom courses and \(syncedAssignments) assignments."
            lastError = courseErrors.isEmpty ? nil : courseErrors.joined(separator: "\n")
            activationURL = nil
        } catch {
            lastError = error.localizedDescription
            if let classroomError = error as? ClassroomAPIError {
                activationURL = classroomError.activationURL
            }
        }
    }

    func startDailySync(accessTokenProvider: @escaping @MainActor () -> String?, storeProvider: @escaping @MainActor () -> UniBuddyStore) {
        dailySyncTask?.cancel()
        dailySyncTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60 * 60 * 24))
                await self?.sync(accessToken: accessTokenProvider(), store: storeProvider())
            }
        }
    }
}
