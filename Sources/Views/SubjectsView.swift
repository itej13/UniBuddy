import SwiftUI

struct SubjectsView: View {
    @EnvironmentObject private var store: UniBuddyStore

    @State private var name = ""
    @State private var code = ""
    @State private var credits = 3

    private var classroomCourses: [(id: String, name: String)] {
        store.classroomCourses
            .sorted { $0.name < $1.name }
            .map { course in
                (course.id, course.section.map { "\(course.name) · \($0)" } ?? course.name)
            }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                DashboardSection(title: "Add Subject", systemImage: "plus.circle") {
                    SubjectForm(name: $name, code: $code, credits: $credits) {
                        addSubject()
                    }
                    .frame(maxWidth: 420)
                }

                DashboardSection(title: "Subjects", systemImage: "books.vertical") {
                    if store.classroomCourses.isEmpty {
                        Text("No Classroom courses synced yet. Use the Sync button after signing in.")
                            .foregroundStyle(.secondary)
                    }
                    if store.subjects.isEmpty {
                        EmptyStateText("Add your first subject to start tracking attendance.")
                    } else {
                        ForEach(store.subjects.sorted { $0.name < $1.name }) { subject in
                            SubjectDetailCard(subjectID: subject.id, courses: classroomCourses)
                            Divider()
                        }
                    }
                }
            }
            .padding(24)
        }
        .navigationTitle("Subjects")
    }

    private func addSubject() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.subjects.append(Subject(name: trimmed, code: code, credits: credits))
        name = ""
        code = ""
        credits = 3
    }
}

private struct SubjectDetailCard: View {
    @EnvironmentObject private var store: UniBuddyStore
    var subjectID: UUID
    var courses: [(id: String, name: String)]

    var body: some View {
        if let index = store.subjects.firstIndex(where: { $0.id == subjectID }) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Subject name", text: $store.subjects[index].name)
                            .font(.title3.bold())
                        TextField("Subject code", text: $store.subjects[index].code)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 220)
                    }
                    Spacer()
                    Stepper("Credits: \(store.subjects[index].credits)", value: $store.subjects[index].credits, in: 0...10)
                        .frame(width: 160)
                }

                Picker("Classroom Course", selection: Binding {
                    store.subjects[index].classroomCourseID ?? ""
                } set: { newValue in
                    if newValue.isEmpty {
                        store.subjects[index].classroomCourseID = nil
                        store.subjects[index].classroomCourseName = nil
                    } else {
                        store.subjects[index].classroomCourseID = newValue
                        store.subjects[index].classroomCourseName = courses.first(where: { $0.id == newValue })?.name
                    }
                    store.save()
                }) {
                    Text("Not linked").tag("")
                    ForEach(courses, id: \.id) { course in
                        Text(course.name).tag(course.id)
                    }
                }

                let subject = store.subjects[index]
                let summary = AttendanceAnalytics.summary(for: subject, records: store.attendanceRecords)
                HStack {
                    Label("\(summary.present) present", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    Label("\(summary.absent) absent", systemImage: "xmark.circle.fill").foregroundStyle(.red)
                    Label("\(summary.cancelled) cancelled", systemImage: "minus.circle.fill").foregroundStyle(.orange)
                    Spacer()
                    Button(role: .destructive) {
                        store.deleteSubject(subject)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .font(.callout)

                DisclosureGroup("Schedule") {
                    MultiDayTimetableEditor(
                        subjects: [subject],
                        defaultSubjectID: subject.id,
                        showSubjectPicker: false
                    )
                    .padding(.top, 6)
                }
            }
        }
    }
}
