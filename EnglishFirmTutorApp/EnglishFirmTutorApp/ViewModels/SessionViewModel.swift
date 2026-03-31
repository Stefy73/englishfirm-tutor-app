import Foundation
import SwiftUI

@MainActor
final class SessionViewModel: ObservableObject {

    // MARK: - Published State
    @Published var sessions: [Session] = []
    @Published var students: [Student] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var lastSynced: Date? = nil

    private let calendarService = GoogleCalendarService.shared
    private let notificationService = NotificationService.shared

    // MARK: - Computed Views
    var todaysSessions: [Session] {
        sessions.filter { $0.isToday }.sorted { $0.startTime < $1.startTime }
    }

    var upcomingSessions: [Session] {
        let now = Date()
        return sessions
            .filter { $0.startTime > now && !$0.isToday }
            .sorted { $0.startTime < $1.startTime }
    }

    var pastSessions: [Session] {
        sessions
            .filter { $0.startTime < Date() && $0.status != .scheduled }
            .sorted { $0.startTime > $1.startTime }
    }

    // MARK: - Fetch from Google Calendar
    func fetchSessions(accessToken: String, tutorId: String) async {
        guard !accessToken.isEmpty else {
            errorMessage = "Not signed in."
            return
        }
        isLoading = true
        errorMessage = nil

        do {
            // Fetch 4 weeks: 1 past + 3 future
            let start = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date())!
            let end   = Calendar.current.date(byAdding: .weekOfYear, value: 3, to: Date())!
            let fetched = try await calendarService.fetchSessions(
                accessToken: accessToken,
                tutorId: tutorId,
                from: start,
                to: end
            )
            // Merge with local attendance data
            sessions = mergeWithLocalData(fetched)
            lastSynced = Date()

            // Schedule reminders for upcoming sessions
            notificationService.scheduleReminders(for: upcomingSessions + todaysSessions, students: students)

            // Recalculate student progress
            updateStudentSessionCounts()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Fetch a Specific Month (for Timesheet)
    func fetchMonth(accessToken: String, tutorId: String, month: Int, year: Int) async -> [Session] {
        do {
            let fetched = try await calendarService.fetchMonth(
                accessToken: accessToken,
                tutorId: tutorId,
                month: month,
                year: year
            )
            return mergeWithLocalData(fetched)
        } catch {
            errorMessage = error.localizedDescription
            return []
        }
    }

    // MARK: - Update Attendance
    func markAttendance(session: Session, status: SessionStatus) {
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        sessions[index].status = status
        saveLocalData()

        if status == .cancelled {
            notificationService.cancelReminders(for: session.id)
        }
        updateStudentSessionCounts()
    }

    func updateNotes(session: Session, notes: String) {
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        sessions[index].notes = notes
        saveLocalData()
    }

    func markReminderSent(session: Session) {
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        sessions[index].reminderSent = true
        saveLocalData()
    }

    // MARK: - Student Management
    func addStudent(_ student: Student) {
        students.append(student)
        saveStudents()
    }

    func updateStudent(_ student: Student) {
        if let index = students.firstIndex(where: { $0.id == student.id }) {
            students[index] = student
            saveStudents()
        }
    }

    func deleteStudent(_ student: Student) {
        students.removeAll { $0.id == student.id }
        saveStudents()
    }

    func student(for session: Session) -> Student? {
        students.first { $0.name.lowercased() == session.studentName.lowercased() }
    }

    func sessions(for student: Student) -> [Session] {
        sessions.filter { $0.studentName.lowercased() == student.name.lowercased() }
            .sorted { $0.startTime < $1.startTime }
    }

    // MARK: - Load Persisted Data
    func loadLocalData(tutorId: String) {
        if let data = UserDefaults.standard.data(forKey: "sessions_\(tutorId)"),
           let saved = try? JSONDecoder().decode([Session].self, from: data) {
            sessions = saved
        }
        if let data = UserDefaults.standard.data(forKey: "students_\(tutorId)"),
           let saved = try? JSONDecoder().decode([Student].self, from: data) {
            students = saved
        }
        updateStudentSessionCounts()
    }

    // MARK: - Private Helpers
    private func mergeWithLocalData(_ fetched: [Session]) -> [Session] {
        // Preserve locally-saved attendance statuses and notes
        return fetched.map { remote in
            if let local = sessions.first(where: { $0.id == remote.id }) {
                var merged = remote
                merged.status = local.status
                merged.notes = local.notes
                merged.reminderSent = local.reminderSent
                return merged
            }
            return remote
        }
    }

    private func updateStudentSessionCounts() {
        for i in students.indices {
            students[i].completedSessions = sessions.filter {
                $0.studentName.lowercased() == students[i].name.lowercased() &&
                $0.status == .attended
            }.count
        }
    }

    private func saveLocalData() {
        guard let tutorId = sessions.first?.tutorId else { return }
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: "sessions_\(tutorId)")
        }
    }

    private func saveStudents() {
        guard let tutorId = students.first?.tutorId else { return }
        if let data = try? JSONEncoder().encode(students) {
            UserDefaults.standard.set(data, forKey: "students_\(tutorId)")
        }
    }
}
