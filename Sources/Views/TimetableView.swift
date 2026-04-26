import SwiftUI

struct TimetableView: View {
    @EnvironmentObject private var store: UniBuddyStore

    private var sortedSlots: [TimetableSlot] {
        store.timetableSlots.sorted {
            ($0.weekdayRaw, $0.startMinutes, store.subject(for: $0.subjectID)?.name ?? "") <
            ($1.weekdayRaw, $1.startMinutes, store.subject(for: $1.subjectID)?.name ?? "")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            DashboardSection(title: "Add Timetable Slots", systemImage: "calendar.badge.plus") {
                MultiDayTimetableEditor(subjects: store.subjects.sorted { $0.name < $1.name })
            }

            DashboardSection(title: "Weekly Table", systemImage: "tablecells") {
                if sortedSlots.isEmpty {
                    EmptyStateText("Add timetable slots to see them here.")
                } else {
                    Table(sortedSlots) {
                        TableColumn("Day") { slot in
                            Text(slot.weekday.fullName)
                        }
                        TableColumn("Time") { slot in
                            Text("\(UniBuddyFormatters.minutesToTime(slot.startMinutes)) - \(UniBuddyFormatters.minutesToTime(slot.endMinutes))")
                        }
                        TableColumn("Subject") { slot in
                            Text(store.subject(for: slot.subjectID)?.name ?? "Unknown")
                        }
                        TableColumn("Code") { slot in
                            Text(store.subject(for: slot.subjectID)?.code ?? "")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(minHeight: 280)
                }
            }
        }
        .padding(24)
        .navigationTitle("Timetable")
    }
}

struct MultiDayTimetableEditor: View {
    @EnvironmentObject private var store: UniBuddyStore
    var subjects: [Subject]
    var defaultSubjectID: UUID?
    var showSubjectPicker = true

    @State private var selectedSubjectID: UUID?
    @State private var selectedDays: Set<Weekday> = [.monday]
    @State private var startTime = UniBuddyFormatters.date(fromMinutes: 9 * 60)
    @State private var endTime = UniBuddyFormatters.date(fromMinutes: 10 * 60)
    @State private var room = ""

    private var effectiveSubjectID: UUID? {
        showSubjectPicker ? selectedSubjectID : defaultSubjectID
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showSubjectPicker {
                Picker("Subject", selection: $selectedSubjectID) {
                    Text("Choose subject").tag(UUID?.none)
                    ForEach(subjects) { subject in
                        Text(subject.name).tag(Optional(subject.id))
                    }
                }
                .frame(maxWidth: 360)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Days")
                    .font(.headline)
                HStack {
                    ForEach(Weekday.classDays) { day in
                        Toggle(day.shortName, isOn: Binding {
                            selectedDays.contains(day)
                        } set: { isSelected in
                            if isSelected {
                                selectedDays.insert(day)
                            } else {
                                selectedDays.remove(day)
                            }
                        })
                        .toggleStyle(.button)
                    }
                }
            }

            HStack {
                DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)
                TextField("Room", text: $room)
                    .frame(width: 120)
                Button {
                    addSlots()
                } label: {
                    Label("Add Slots", systemImage: "plus")
                }
                .disabled(effectiveSubjectID == nil || selectedDays.isEmpty || endMinutes <= startMinutes)
            }

            if let subjectID = effectiveSubjectID {
                let subjectSlots = store.timetableSlots
                    .filter { $0.subjectID == subjectID }
                    .sorted { ($0.weekdayRaw, $0.startMinutes) < ($1.weekdayRaw, $1.startMinutes) }
                if !subjectSlots.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(subjectSlots) { slot in
                            HStack {
                                Text(slot.weekday.shortName)
                                    .frame(width: 42, alignment: .leading)
                                Text("\(UniBuddyFormatters.minutesToTime(slot.startMinutes)) - \(UniBuddyFormatters.minutesToTime(slot.endMinutes))")
                                if !slot.room.isEmpty {
                                    Text(slot.room)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button(role: .destructive) {
                                    store.timetableSlots.removeAll { $0.id == slot.id }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .labelStyle(.iconOnly)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            selectedSubjectID = selectedSubjectID ?? defaultSubjectID ?? subjects.first?.id
        }
    }

    private var startMinutes: Int {
        UniBuddyFormatters.minutes(from: startTime)
    }

    private var endMinutes: Int {
        UniBuddyFormatters.minutes(from: endTime)
    }

    private func addSlots() {
        guard let effectiveSubjectID else { return }
        store.addTimetableSlots(
            subjectID: effectiveSubjectID,
            weekdays: selectedDays,
            startMinutes: startMinutes,
            endMinutes: endMinutes,
            room: room.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}
