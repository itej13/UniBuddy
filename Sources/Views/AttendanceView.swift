import SwiftUI

struct AttendanceView: View {
    @EnvironmentObject private var store: UniBuddyStore
    @State private var selectedDate = Date.now

    private var selectedWeekday: Weekday {
        selectedDate.classroomWeekday
    }

    private var daySlots: [TimetableSlot] {
        store.timetableSlots.filter { $0.weekday == selectedWeekday }.sorted { $0.startMinutes < $1.startMinutes }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .frame(maxWidth: 240)

                DashboardSection(title: "Mark Attendance", systemImage: "calendar.badge.checkmark") {
                    if daySlots.isEmpty {
                        EmptyStateText("No timetable slots for \(selectedWeekday.fullName). Add slots during setup or in this screen's timetable section.")
                    } else {
                        ForEach(daySlots) { slot in
                            if let subject = store.subjects.first(where: { $0.id == slot.subjectID }) {
                                AttendanceMarkRow(
                                    subject: subject,
                                    slot: slot,
                                    selectedDate: selectedDate,
                                    existingRecord: existingRecord(subjectID: subject.id)
                                )
                            }
                        }
                    }
                }

                DashboardSection(title: "Timetable", systemImage: "clock") {
                    MultiDayTimetableEditor(subjects: store.subjects.sorted { $0.name < $1.name })
                }

                DashboardSection(title: "History", systemImage: "clock.arrow.circlepath") {
                    ForEach(store.attendanceRecords.sorted { $0.date > $1.date }.prefix(30).map { $0 }) { record in
                        HStack {
                            Text(store.subjects.first(where: { $0.id == record.subjectID })?.name ?? "Unknown")
                            Spacer()
                            Text(record.date.formatted(date: .abbreviated, time: .omitted))
                                .foregroundStyle(.secondary)
                            Label(record.status.title, systemImage: record.status.systemImage)
                                .foregroundStyle(record.status.tint)
                        }
                    }
                }
            }
            .padding(24)
        }
        .navigationTitle("Attendance")
    }

    private func existingRecord(subjectID: UUID) -> AttendanceRecord? {
        store.attendanceRecords.first {
            $0.subjectID == subjectID && Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
        }
    }
}

private struct AttendanceMarkRow: View {
    @EnvironmentObject private var store: UniBuddyStore
    var subject: Subject
    var slot: TimetableSlot
    var selectedDate: Date
    var existingRecord: AttendanceRecord?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(subject.name)
                    .font(.headline)
                Text("\(UniBuddyFormatters.minutesToTime(slot.startMinutes)) - \(UniBuddyFormatters.minutesToTime(slot.endMinutes))")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            ForEach(AttendanceStatus.allCases) { status in
                Button {
                    mark(status)
                } label: {
                    Label(status.title, systemImage: status.systemImage)
                }
                .labelStyle(.iconOnly)
                .foregroundStyle(status.tint)
                .buttonStyle(.bordered)
                .help(status.title)
            }
        }
    }

    private func mark(_ status: AttendanceStatus) {
        store.upsertAttendance(subjectID: subject.id, date: selectedDate, status: status)
    }
}
