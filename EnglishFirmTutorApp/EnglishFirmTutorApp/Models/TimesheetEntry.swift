import Foundation

struct TimesheetEntry: Identifiable, Codable {
    var id: String
    var date: Date
    var studentName: String
    var sessionLabel: String    // e.g. "Simmi 9 of 12" or "Writing group"
    var hours: Double
    var status: SessionStatus

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d.M.yy"
        return formatter.string(from: date)
    }

    var hoursDisplay: String {
        // Show whole number if no fractional part
        hours.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(hours))
            : String(hours)
    }
}

// MARK: - Timesheet Month Summary
struct MonthlyTimesheet {
    var month: Int
    var year: Int
    var entries: [TimesheetEntry]
    var tutorName: String

    var totalHours: Double {
        entries.filter { $0.status == .attended }.reduce(0) { $0 + $1.hours }
    }

    var title: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        var components = DateComponents()
        components.month = month
        components.year = year
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }

    var csvString: String {
        var lines = ["Date,Student / Activity,Hours"]
        for entry in entries {
            lines.append("\(entry.formattedDate),\(entry.sessionLabel),\(entry.hoursDisplay)")
        }
        lines.append(",TOTAL,\(totalHoursDisplay)")
        return lines.joined(separator: "\n")
    }

    var totalHoursDisplay: String {
        totalHours.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(totalHours))
            : String(totalHours)
    }
}
