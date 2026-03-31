import Foundation
import UIKit

// MARK: - Timesheet Service
// Generates monthly timesheets from session data and exports as PDF or CSV.

final class TimesheetService {

    static let shared = TimesheetService()

    // MARK: - Build Monthly Timesheet
    func buildTimesheet(from sessions: [Session], month: Int, year: Int, tutorName: String) -> MonthlyTimesheet {
        let filtered = sessions.filter { session in
            let components = Calendar.current.dateComponents([.month, .year], from: session.startTime)
            return components.month == month && components.year == year
        }

        let entries = filtered.map { session -> TimesheetEntry in
            // Build a label like "Simmi 9 of 12" or "Writing group"
            let label: String
            if session.totalSessions > 1 && !session.studentName.contains("group") {
                label = "\(session.studentName) \(session.sessionNumber) of \(session.totalSessions)"
            } else {
                label = session.studentName
            }

            return TimesheetEntry(
                id: session.id,
                date: session.startTime,
                studentName: session.studentName,
                sessionLabel: label,
                hours: session.durationHours,
                status: session.status
            )
        }.sorted { $0.date < $1.date }

        return MonthlyTimesheet(month: month, year: year, entries: entries, tutorName: tutorName)
    }

    // MARK: - Export as CSV
    func exportCSV(timesheet: MonthlyTimesheet) -> URL? {
        let filename = "Timesheet-\(timesheet.title.replacingOccurrences(of: " ", with: "-")).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try timesheet.csvString.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("TimesheetService: CSV export failed: \(error)")
            return nil
        }
    }

    // MARK: - Export as PDF
    func exportPDF(timesheet: MonthlyTimesheet) -> URL? {
        let filename = "Timesheet-\(timesheet.title.replacingOccurrences(of: " ", with: "-")).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842)) // A4

        do {
            try renderer.writePDF(to: url) { context in
                context.beginPage()
                self.drawTimesheetPage(timesheet: timesheet, in: context.cgContext)
            }
            return url
        } catch {
            print("TimesheetService: PDF export failed: \(error)")
            return nil
        }
    }

    // MARK: - PDF Drawing
    private func drawTimesheetPage(timesheet: MonthlyTimesheet, in ctx: CGContext) {
        let margin: CGFloat = 50
        var y: CGFloat = 50

        // Title
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 20),
            .foregroundColor: UIColor.black
        ]
        let title = "EnglishFirm — Timesheet: \(timesheet.title)"
        title.draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
        y += 35

        // Tutor name
        let subtitleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.darkGray
        ]
        "Tutor: \(timesheet.tutorName)".draw(at: CGPoint(x: margin, y: y), withAttributes: subtitleAttrs)
        y += 30

        // Header row
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 11),
            .foregroundColor: UIColor.white
        ]
        ctx.setFillColor(UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1).cgColor)
        ctx.fill(CGRect(x: margin, y: y, width: 495, height: 22))

        "Date".draw(at: CGPoint(x: margin + 5, y: y + 4), withAttributes: headerAttrs)
        "Student / Activity".draw(at: CGPoint(x: margin + 80, y: y + 4), withAttributes: headerAttrs)
        "Hours".draw(at: CGPoint(x: margin + 440, y: y + 4), withAttributes: headerAttrs)
        y += 25

        // Rows
        let rowAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.black
        ]
        for (i, entry) in timesheet.entries.enumerated() {
            if entry.status == .cancelled || entry.status == .noShow { continue }

            let bg = i % 2 == 0 ? UIColor(white: 0.97, alpha: 1) : UIColor.white
            ctx.setFillColor(bg.cgColor)
            ctx.fill(CGRect(x: margin, y: y, width: 495, height: 20))

            entry.formattedDate.draw(at: CGPoint(x: margin + 5, y: y + 3), withAttributes: rowAttrs)
            entry.sessionLabel.draw(at: CGPoint(x: margin + 80, y: y + 3), withAttributes: rowAttrs)
            entry.hoursDisplay.draw(at: CGPoint(x: margin + 440, y: y + 3), withAttributes: rowAttrs)
            y += 22
        }

        // Total row
        y += 10
        let totalAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]
        "TOTAL HOURS:".draw(at: CGPoint(x: margin + 320, y: y), withAttributes: totalAttrs)
        timesheet.totalHoursDisplay.draw(at: CGPoint(x: margin + 440, y: y), withAttributes: totalAttrs)
    }
}
