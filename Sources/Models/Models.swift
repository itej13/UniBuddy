import Foundation
import SwiftUI

enum AttendanceStatus: String, CaseIterable, Identifiable, Codable {
    case present
    case absent
    case cancelled
    case holiday

    var id: String { rawValue }

    var title: String {
        switch self {
        case .present: "Present"
        case .absent: "Absent"
        case .cancelled: "Cancelled"
        case .holiday: "Holiday"
        }
    }

    var systemImage: String {
        switch self {
        case .present: "checkmark.circle.fill"
        case .absent: "xmark.circle.fill"
        case .cancelled: "minus.circle.fill"
        case .holiday: "sun.max.fill"
        }
    }

    var tint: Color {
        switch self {
        case .present: .green
        case .absent: .red
        case .cancelled: .orange
        case .holiday: .blue
        }
    }
}

enum Weekday: Int, CaseIterable, Identifiable, Codable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var id: Int { rawValue }

    var shortName: String {
        Calendar.current.shortWeekdaySymbols[rawValue - 1]
    }

    var fullName: String {
        Calendar.current.weekdaySymbols[rawValue - 1]
    }

    static var classDays: [Weekday] {
        [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
    }
}

enum SubmissionState: String, CaseIterable, Identifiable, Codable {
    case new
    case created
    case turnedIn
    case returned
    case reclaimedByStudent
    case unknown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .new: "New"
        case .created: "Assigned"
        case .turnedIn: "Turned in"
        case .returned: "Returned"
        case .reclaimedByStudent: "Reclaimed"
        case .unknown: "Unknown"
        }
    }

    var isComplete: Bool {
        self == .turnedIn || self == .returned
    }

    static func fromClassroom(_ value: String?) -> SubmissionState {
        switch value {
        case "NEW": .new
        case "CREATED": .created
        case "TURNED_IN": .turnedIn
        case "RETURNED": .returned
        case "RECLAIMED_BY_STUDENT": .reclaimedByStudent
        default: .unknown
        }
    }
}

struct Subject: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var code: String
    var credits: Int
    var classroomCourseID: String?
    var classroomCourseName: String?
    var colorHex: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        code: String,
        credits: Int,
        classroomCourseID: String? = nil,
        classroomCourseName: String? = nil,
        colorHex: String = "#2563EB",
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.code = code
        self.credits = credits
        self.classroomCourseID = classroomCourseID
        self.classroomCourseName = classroomCourseName
        self.colorHex = colorHex
        self.createdAt = createdAt
    }
}

struct TimetableSlot: Identifiable, Codable, Hashable {
    var id: UUID
    var subjectID: UUID
    var weekdayRaw: Int
    var startMinutes: Int
    var endMinutes: Int
    var room: String

    init(
        id: UUID = UUID(),
        subjectID: UUID,
        weekday: Weekday,
        startMinutes: Int,
        endMinutes: Int,
        room: String = ""
    ) {
        self.id = id
        self.subjectID = subjectID
        self.weekdayRaw = weekday.rawValue
        self.startMinutes = startMinutes
        self.endMinutes = endMinutes
        self.room = room
    }

    var weekday: Weekday {
        Weekday(rawValue: weekdayRaw) ?? .monday
    }
}

struct AttendanceRecord: Identifiable, Codable, Hashable {
    var id: UUID
    var subjectID: UUID
    var date: Date
    var statusRaw: String
    var note: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        subjectID: UUID,
        date: Date,
        status: AttendanceStatus,
        note: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.subjectID = subjectID
        self.date = Calendar.current.startOfDay(for: date)
        self.statusRaw = status.rawValue
        self.note = note
        self.createdAt = createdAt
    }

    var status: AttendanceStatus {
        get { AttendanceStatus(rawValue: statusRaw) ?? .present }
        set { statusRaw = newValue.rawValue }
    }
}

struct ClassroomAssignment: Identifiable, Codable, Hashable {
    var id: String
    var courseID: String
    var courseName: String
    var courseWorkID: String
    var subjectID: UUID?
    var title: String
    var details: String
    var dueDate: Date?
    var alternateLink: String?
    var submissionStateRaw: String
    var maxPoints: Double?
    var lastSyncedAt: Date

    init(
        id: String,
        courseID: String,
        courseName: String,
        courseWorkID: String,
        subjectID: UUID?,
        title: String,
        details: String = "",
        dueDate: Date? = nil,
        alternateLink: String? = nil,
        submissionState: SubmissionState = .unknown,
        maxPoints: Double? = nil,
        lastSyncedAt: Date = .now
    ) {
        self.id = id
        self.courseID = courseID
        self.courseName = courseName
        self.courseWorkID = courseWorkID
        self.subjectID = subjectID
        self.title = title
        self.details = details
        self.dueDate = dueDate
        self.alternateLink = alternateLink
        self.submissionStateRaw = submissionState.rawValue
        self.maxPoints = maxPoints
        self.lastSyncedAt = lastSyncedAt
    }

    var submissionState: SubmissionState {
        get { SubmissionState(rawValue: submissionStateRaw) ?? .unknown }
        set { submissionStateRaw = newValue.rawValue }
    }
}

struct UserProfile: Identifiable, Codable, Hashable {
    var id: String
    var email: String
    var displayName: String
    var photoURL: String?
    var lastSyncAt: Date?
    var createdAt: Date

    init(
        id: String = "local",
        email: String,
        displayName: String,
        photoURL: String? = nil,
        lastSyncAt: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.lastSyncAt = lastSyncAt
        self.createdAt = createdAt
    }
}

struct ClassroomCourseInfo: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var section: String?
    var lastSyncedAt: Date

    init(id: String, name: String, section: String? = nil, lastSyncedAt: Date = .now) {
        self.id = id
        self.name = name
        self.section = section
        self.lastSyncedAt = lastSyncedAt
    }
}
