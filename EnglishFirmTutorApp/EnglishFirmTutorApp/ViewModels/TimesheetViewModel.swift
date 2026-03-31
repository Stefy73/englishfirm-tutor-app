import Foundation
import SwiftUI

@MainActor
final class TimesheetViewModel: ObservableObject {

    @Published var currentTimesheet: MonthlyTimesheet? = nil
    @Published var isLoading: Bool = false
    @Published var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @Published var selectedYear: Int  = Calendar.current.component(.year, from: Date())
    @Published var exportURL: URL? = nil
    @Published var showShareSheet: Bool = false

    private let timesheetService = TimesheetService.shared

    // MARK: - Generate Timesheet
    func generateTimesheet(sessions: [Session], tutorName: String) {
        isLoading = true
        let sheet = timesheetService.buildTimesheet(
            from: sessions,
            month: selectedMonth,
            year: selectedYear,
            tutorName: tutorName
        )
        currentTimesheet = sheet
        isLoading = false
    }

    // MARK: - Generate from Remote (fetches month from Calendar)
    func generateFromCalendar(viewModel: SessionViewModel, accessToken: String, tutorId: String, tutorName: String) async {
        isLoading = true
        let sessions = await viewModel.fetchMonth(accessToken: accessToken, tutorId: tutorId, month: selectedMonth, year: selectedYear)
        let sheet = timesheetService.buildTimesheet(from: sessions, month: selectedMonth, year: selectedYear, tutorName: tutorName)
        currentTimesheet = sheet
        isLoading = false
    }

    // MARK: - Export CSV
    func exportCSV() {
        guard let sheet = currentTimesheet else { return }
        if let url = timesheetService.exportCSV(timesheet: sheet) {
            exportURL = url
            showShareSheet = true
        }
    }

    // MARK: - Export PDF
    func exportPDF() {
        guard let sheet = currentTimesheet else { return }
        if let url = timesheetService.exportPDF(timesheet: sheet) {
            exportURL = url
            showShareSheet = true
        }
    }

    // MARK: - Month Navigation
    func goToPreviousMonth() {
        if selectedMonth == 1 {
            selectedMonth = 12
            selectedYear -= 1
        } else {
            selectedMonth -= 1
        }
    }

    func goToNextMonth() {
        if selectedMonth == 12 {
            selectedMonth = 1
            selectedYear += 1
        } else {
            selectedMonth += 1
        }
    }

    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        var components = DateComponents()
        components.month = selectedMonth
        components.year = selectedYear
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }
}
