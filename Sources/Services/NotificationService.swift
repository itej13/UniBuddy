import Combine
import Foundation
import UserNotifications

@MainActor
final class NotificationService: ObservableObject {
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var lastError: String?

    init() {
        Task { await refreshAuthorizationStatus() }
    }

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func requestAuthorization() async {
        do {
            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorizationStatus()
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func scheduleAssignmentReminders(assignments: [ClassroomAssignment]) async {
        guard authorizationStatus == .authorized || authorizationStatus == .provisional else { return }

        let center = UNUserNotificationCenter.current()
        let ids = assignments.map { "assignment-\($0.id)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)

        for assignment in assignments {
            guard !assignment.submissionState.isComplete,
                  let dueDate = assignment.dueDate,
                  dueDate > .now,
                  dueDate.timeIntervalSinceNow < 60 * 60 * 24 * 3
            else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Submission due soon"
            content.body = "\(assignment.title) is due \(UniBuddyFormatters.shortDay.string(from: dueDate))."
            content.sound = .default

            let reminderDate = max(Date.now.addingTimeInterval(60), dueDate.addingTimeInterval(-60 * 60 * 6))
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: "assignment-\(assignment.id)", content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    func scheduleAttendancePrompts(slots: [TimetableSlot], subjects: [Subject]) async {
        guard authorizationStatus == .authorized || authorizationStatus == .provisional else { return }

        let center = UNUserNotificationCenter.current()
        let ids = slots.map { "attendance-\($0.id)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)

        for slot in slots {
            guard let subject = subjects.first(where: { $0.id == slot.subjectID }) else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Mark attendance"
            content.body = "\(subject.name) starts around \(UniBuddyFormatters.minutesToTime(slot.startMinutes))."
            content.sound = .default

            var components = DateComponents()
            components.weekday = slot.weekday.rawValue
            components.hour = max(0, (slot.startMinutes - 10) / 60)
            components.minute = max(0, (slot.startMinutes - 10) % 60)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: "attendance-\(slot.id)", content: content, trigger: trigger)
            try? await center.add(request)
        }
    }
}
