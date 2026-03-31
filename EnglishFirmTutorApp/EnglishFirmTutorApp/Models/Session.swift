import Foundation

// MARK: - Session Status
enum SessionStatus: String, Codable, CaseIterable {
    case scheduled = "Scheduled"
    case attended  = "Attended"
    case cancelled = "Cancelled"
    case noShow    = "No Show"

    var color: String {
        switch self {
        case .scheduled: return "blue"
        case .attended:  return "green"
        case .cancelled: return "orange"
        case .noShow:    return "red"
        }
    }

    var systemImage: String {
        switch self {
        case .scheduled: return "calendar.circle"
        case .attended:  return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        case .noShow:    return "exclamationmark.circle.fill"
        }
    }
}

// MARK: - Session Model
struct Session: Identifiable, Codable, Hashable {
    var id: String                        // Google Calendar event ID
    var studentName: String
    var sessionNumber: Int                // e.g. 9 in "Simmi 9 of 12"
    var totalSessions: Int                // e.g. 12
    var startTime: Date
    var endTime: Date
    var tutorId: String
    var status: SessionStatus
    var reminderSent: Bool
    var notes: String

    // Computed
    var durationHours: Double {
        endTime.timeIntervalSince(startTime) / 3600
    }

    var progressLabel: String {
        "\(sessionNumber) of \(totalSessions)"
    }

    var progressFraction: Double {
        guard totalSessions > 0 else { return 0 }
        return Double(sessionNumber) / Double(totalSessions)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(startTime)
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: startTime)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: startTime)
    }

    // MARK: - Parsing Helper
    /// Parses a Google Calendar event title like "Simmi 9 of 12" or "Writing group"
    static func parse(title: String, eventId: String, startTime: Date, endTime: Date, tutorId: String) -> Session {
        // Try to match "[Name] [N] of [M]" pattern
        let pattern = #"^(.+?)\s+(\d+)\s+(?:and\s+\d+\s+)?of\s+(\d+)$"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: title, range: NSRange(title.startIndex..., in: title)) {
            let nameRange   = Range(match.range(at: 1), in: title)
            let numRange    = Range(match.range(at: 2), in: title)
            let totalRange  = Range(match.range(at: 3), in: title)

            let name  = nameRange.map  { String(title[$0]) } ?? title
            let num   = numRange.flatMap   { Int(title[$0]) } ?? 1
            let total = totalRange.flatMap { Int(title[$0]) } ?? 1

            return Session(id: eventId, studentName: name.trimmingCharacters(in: .whitespaces),
                           sessionNumber: num, totalSessions: total,
                           startTime: startTime, endTime: endTime,
                           tutorId: tutorId, status: .scheduled,
                           reminderSent: false, notes: "")
        }
        // Fallback for group sessions or unparseable titles
        return Session(id: eventId, studentName: title,
                       sessionNumber: 1, totalSessions: 1,
                       startTime: startTime, endTime: endTime,
                       tutorId: tutorId, status: .scheduled,
                       reminderSent: false, notes: "")
    }
}
