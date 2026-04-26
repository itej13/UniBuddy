import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var authService: GoogleAuthService
    @EnvironmentObject private var store: UniBuddyStore

    @State private var name = ""
    @State private var code = ""
    @State private var credits = 3
    @State private var weekday = Weekday.monday
    @State private var startTime = UniBuddyFormatters.date(fromMinutes: 9 * 60)
    @State private var endTime = UniBuddyFormatters.date(fromMinutes: 10 * 60)
    @State private var selectedSubjectID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("UniBuddy")
                        .font(.largeTitle.bold())
                    Text("Set up your personal attendance and Classroom tracker.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                SignInPanel()
            }

            Divider()

            Grid(alignment: .topLeading, horizontalSpacing: 24, verticalSpacing: 16) {
                GridRow {
                    setupCard("Subjects", systemImage: "books.vertical") {
                        SubjectForm(name: $name, code: $code, credits: $credits) {
                            addSubject()
                        }
                        SubjectList(subjects: store.subjects.sorted { $0.name < $1.name }, selection: $selectedSubjectID)
                    }

                    setupCard("Timetable", systemImage: "calendar") {
                        Picker("Subject", selection: $selectedSubjectID) {
                            Text("Choose subject").tag(UUID?.none)
                            ForEach(store.subjects.sorted { $0.name < $1.name }) { subject in
                                Text(subject.name).tag(Optional(subject.id))
                            }
                        }
                        Picker("Day", selection: $weekday) {
                            ForEach(Weekday.classDays) { day in
                                Text(day.fullName).tag(day)
                            }
                        }
                        DatePicker("Starts", selection: $startTime, displayedComponents: .hourAndMinute)
                        DatePicker("Ends", selection: $endTime, displayedComponents: .hourAndMinute)
                        Button {
                            addTimetableSlot()
                        } label: {
                            Label("Add Slot", systemImage: "plus")
                        }
                        .disabled(selectedSubjectID == nil)
                    }
                }
            }

            Text("After adding at least one subject, the main dashboard opens automatically. Link Google Classroom courses from the Subjects screen after your first sync.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .onChange(of: authService.currentUser?.profile?.email) { _, _ in
            upsertProfile()
        }
    }

    private func setupCard<Content: View>(_ title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.title3.bold())
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func addSubject() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let subject = Subject(name: trimmedName, code: code.trimmingCharacters(in: .whitespacesAndNewlines), credits: credits)
        store.subjects.append(subject)
        selectedSubjectID = subject.id
        name = ""
        code = ""
        credits = 3
        upsertProfile()
    }

    private func addTimetableSlot() {
        guard let selectedSubjectID else { return }
        store.timetableSlots.append(TimetableSlot(
            subjectID: selectedSubjectID,
            weekday: weekday,
            startMinutes: UniBuddyFormatters.minutes(from: startTime),
            endMinutes: UniBuddyFormatters.minutes(from: endTime)
        ))
    }

    private func upsertProfile() {
        guard let profile = authService.userProfile,
              store.profile == nil
        else { return }
        store.upsertProfile(from: profile)
    }
}

private struct SignInPanel: View {
    @EnvironmentObject private var authService: GoogleAuthService

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            if let user = authService.currentUser {
                Text(user.profile?.email ?? "Signed in")
                    .font(.headline)
                Button("Sign Out") {
                    authService.signOut()
                }
            } else {
                Button {
                    Task { await authService.signIn() }
                } label: {
                    Label("Sign in with Google", systemImage: "person.crop.circle.badge.checkmark")
                }
                .buttonStyle(.borderedProminent)
            }

            if !authService.isConfigured {
                Text("OAuth client ID not configured yet.")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else if let error = authService.authError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}

struct SubjectForm: View {
    @Binding var name: String
    @Binding var code: String
    @Binding var credits: Int
    var submit: () -> Void

    var body: some View {
        TextField("Subject name", text: $name)
        TextField("Subject code", text: $code)
        Stepper("Credits: \(credits)", value: $credits, in: 0...10)
        Button {
            submit()
        } label: {
            Label("Add Subject", systemImage: "plus")
        }
        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}

struct SubjectList: View {
    var subjects: [Subject]
    @Binding var selection: UUID?

    var body: some View {
        List(subjects, selection: $selection) { subject in
            VStack(alignment: .leading, spacing: 2) {
                Text(subject.name)
                Text(subject.code.isEmpty ? "\(subject.credits) credits" : "\(subject.code) · \(subject.credits) credits")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .tag(subject.id)
        }
        .frame(minHeight: 120)
    }
}
