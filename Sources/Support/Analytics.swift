import Foundation

enum AttendanceAnalytics {
    static func percentage(for subject: Subject, records: [AttendanceRecord]) -> Double {
        let subjectRecords = records.filter { $0.subjectID == subject.id }
        let counted = subjectRecords.filter { $0.status == .present || $0.status == .absent }
        guard !counted.isEmpty else { return 0 }
        let present = counted.filter { $0.status == .present }.count
        return Double(present) / Double(counted.count)
    }

    static func summary(for subject: Subject, records: [AttendanceRecord]) -> (present: Int, absent: Int, cancelled: Int, holiday: Int) {
        let subjectRecords = records.filter { $0.subjectID == subject.id }
        return (
            subjectRecords.filter { $0.status == .present }.count,
            subjectRecords.filter { $0.status == .absent }.count,
            subjectRecords.filter { $0.status == .cancelled }.count,
            subjectRecords.filter { $0.status == .holiday }.count
        )
    }
}
