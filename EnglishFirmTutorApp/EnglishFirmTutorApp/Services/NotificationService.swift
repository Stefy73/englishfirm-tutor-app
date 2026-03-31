import Foundation
import UserNotifications

// MARK: - Notification Service
// Schedules local push notifications to remind tutors to send session reminders.
// When tutor taps the notification, the app opens to that session.

final class NotificationService: ObservableObject {

    static let shared = NotificationService()

    // MARK: - Request Permission
    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // MARK: - Schedule Reminders for a Session
    func scheduleReminders(for session: Session, studentName: String) {
        let center = UNUserNotificationCenter.current()

        // 24-hour reminder
        let oneDayBefore = session.startTime.addingTimeInterval(-86400)
        if oneDayBefore > Date() {
            scheduleNotification(
                id: "\(session.id)-24h",
                title: "Session Reminder",
                body: "\(studentName) has a session tomorrow at \(session.formattedTime). Send them a reminder!",
                date: oneDayBefore,
                userInfo: ["sessionId": session.id],
                center: center
            )
        }

        // 1-hour reminder
        let oneHourBefore = session.startTime.addingTimeInterval(-3600)
        if oneHourBefore > Date() {
            scheduleNotification(
                id: "\(session.id)-1h",
                title: "Session in 1 Hour",
                body: "\(studentName)'s session starts in 1 hour at \(session.formattedTime).",
                date: oneHourBefore,
                userInfo: ["sessionId": session.id],
                center: center
            )
        }
    }

    // MARK: - Cancel Reminders
    func cancelReminders(for sessionId: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["\(sessionId)-24h", "\(sessionId)-1h"])
    }

    // MARK: - Cancel All
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Schedule Batch (for week's sessions)
    func scheduleReminders(for sessions: [Session], students: [Student]) {
        for session in sessions {
            if let student = students.first(where: {
                $0.name.lowercased() == session.studentName.lowercased()
            }) {
                scheduleReminders(for: session, studentName: student.name)
            } else {
                scheduleReminders(for: session, studentName: session.studentName)
            }
        }
    }

    // MARK: - Private Helper
    private func scheduleNotification(
        id: String,
        title: String,
        body: String,
        date: Date,
        userInfo: [AnyHashable: Any],
        center: UNUserNotificationCenter
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("NotificationService: Failed to schedule \(id): \(error.localizedDescription)")
            }
        }
    }
}
