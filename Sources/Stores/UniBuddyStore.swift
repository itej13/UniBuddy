import Combine
import Foundation

@MainActor
final class UniBuddyStore: ObservableObject {
    @Published var subjects: [Subject] = [] { didSet { saveSoon() } }
    @Published var timetableSlots: [TimetableSlot] = [] { didSet { saveSoon() } }
    @Published var attendanceRecords: [AttendanceRecord] = [] { didSet { saveSoon() } }
    @Published var classroomCourses: [ClassroomCourseInfo] = [] { didSet { saveSoon() } }
    @Published var assignments: [ClassroomAssignment] = [] { didSet { saveSoon() } }
    @Published var profile: UserProfile? { didSet { saveSoon() } }

    private let fileURL: URL
    private var isLoading = false

    init() {
        let supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("UniBuddy", isDirectory: true)
        try? FileManager.default.createDirectory(at: supportDirectory, withIntermediateDirectories: true)
        fileURL = supportDirectory.appendingPathComponent("UniBuddyData.json")
        load()
    }

    func load() {
        isLoading = true
        defer { isLoading = false }

        guard let data = try? Data(contentsOf: fileURL) else { return }
        do {
            let snapshot = try JSONDecoder.store.decode(StoreSnapshot.self, from: data)
            subjects = snapshot.subjects
            timetableSlots = snapshot.timetableSlots
            attendanceRecords = snapshot.attendanceRecords
            classroomCourses = snapshot.classroomCourses
            assignments = snapshot.assignments
            profile = snapshot.profile
        } catch {
            print("Failed to load UniBuddy data: \(error)")
        }
    }

    func save() {
        guard !isLoading else { return }
        let snapshot = StoreSnapshot(
            subjects: subjects,
            timetableSlots: timetableSlots,
            attendanceRecords: attendanceRecords,
            classroomCourses: classroomCourses,
            assignments: assignments,
            profile: profile
        )
        do {
            let data = try JSONEncoder.store.encode(snapshot)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("Failed to save UniBuddy data: \(error)")
        }
    }

    func upsertProfile(from user: GoogleUserProfile) {
        profile = UserProfile(
            email: user.email,
            displayName: user.name,
            photoURL: user.photoURL,
            lastSyncAt: profile?.lastSyncAt,
            createdAt: profile?.createdAt ?? .now
        )
    }

    func subject(for id: UUID) -> Subject? {
        subjects.first { $0.id == id }
    }

    func addTimetableSlots(subjectID: UUID, weekdays: Set<Weekday>, startMinutes: Int, endMinutes: Int, room: String = "") {
        guard endMinutes > startMinutes else { return }
        for weekday in weekdays.sorted(by: { $0.rawValue < $1.rawValue }) {
            let duplicate = timetableSlots.contains {
                $0.subjectID == subjectID &&
                $0.weekday == weekday &&
                $0.startMinutes == startMinutes &&
                $0.endMinutes == endMinutes
            }
            if !duplicate {
                timetableSlots.append(TimetableSlot(
                    subjectID: subjectID,
                    weekday: weekday,
                    startMinutes: startMinutes,
                    endMinutes: endMinutes,
                    room: room
                ))
            }
        }
    }

    func upsertAttendance(subjectID: UUID, date: Date, status: AttendanceStatus) {
        let normalizedDate = date.startOfDay
        if let index = attendanceRecords.firstIndex(where: { $0.subjectID == subjectID && $0.date.isSameDay(as: normalizedDate) }) {
            attendanceRecords[index].status = status
        } else {
            attendanceRecords.insert(AttendanceRecord(subjectID: subjectID, date: normalizedDate, status: status), at: 0)
        }
    }

    func deleteSubject(_ subject: Subject) {
        subjects.removeAll { $0.id == subject.id }
        timetableSlots.removeAll { $0.subjectID == subject.id }
        attendanceRecords.removeAll { $0.subjectID == subject.id }
        for index in assignments.indices where assignments[index].subjectID == subject.id {
            assignments[index].subjectID = nil
        }
    }

    private func saveSoon() {
        save()
    }
}

struct StoreSnapshot: Codable {
    var subjects: [Subject]
    var timetableSlots: [TimetableSlot]
    var attendanceRecords: [AttendanceRecord]
    var classroomCourses: [ClassroomCourseInfo]
    var assignments: [ClassroomAssignment]
    var profile: UserProfile?

    init(
        subjects: [Subject],
        timetableSlots: [TimetableSlot],
        attendanceRecords: [AttendanceRecord],
        classroomCourses: [ClassroomCourseInfo],
        assignments: [ClassroomAssignment],
        profile: UserProfile?
    ) {
        self.subjects = subjects
        self.timetableSlots = timetableSlots
        self.attendanceRecords = attendanceRecords
        self.classroomCourses = classroomCourses
        self.assignments = assignments
        self.profile = profile
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        subjects = try container.decodeIfPresent([Subject].self, forKey: .subjects) ?? []
        timetableSlots = try container.decodeIfPresent([TimetableSlot].self, forKey: .timetableSlots) ?? []
        attendanceRecords = try container.decodeIfPresent([AttendanceRecord].self, forKey: .attendanceRecords) ?? []
        classroomCourses = try container.decodeIfPresent([ClassroomCourseInfo].self, forKey: .classroomCourses) ?? []
        assignments = try container.decodeIfPresent([ClassroomAssignment].self, forKey: .assignments) ?? []
        profile = try container.decodeIfPresent(UserProfile.self, forKey: .profile)
    }
}

struct GoogleUserProfile {
    var email: String
    var name: String
    var photoURL: String?
}

extension JSONEncoder {
    static var store: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    static var store: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
