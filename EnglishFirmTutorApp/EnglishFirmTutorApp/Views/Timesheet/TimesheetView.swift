import SwiftUI

struct TimesheetView: View {

    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var sessionVM: SessionViewModel
    @StateObject private var timesheetVM = TimesheetViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // Month Selector
                monthSelector

                if timesheetVM.isLoading {
                    Spacer()
                    ProgressView("Generating timesheet...")
                    Spacer()
                } else if let sheet = timesheetVM.currentTimesheet {
                    timesheetContent(sheet: sheet)
                } else {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("Tap to generate your timesheet")
                            .foregroundColor(.secondary)
                        Button("Generate") { generate() }
                            .buttonStyle(.borderedProminent)
                    }
                    Spacer()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Timesheet")
            .toolbar {
                if timesheetVM.currentTimesheet != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button { timesheetVM.exportPDF() } label: {
                                Label("Export PDF", systemImage: "doc.fill")
                            }
                            Button { timesheetVM.exportCSV() } label: {
                                Label("Export CSV", systemImage: "tablecells")
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .sheet(isPresented: $timesheetVM.showShareSheet) {
                if let url = timesheetVM.exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .onChange(of: timesheetVM.selectedMonth) { _ in generate() }
            .onChange(of: timesheetVM.selectedYear)  { _ in generate() }
            .onAppear { generate() }
        }
    }

    // MARK: - Month Selector
    private var monthSelector: some View {
        HStack {
            Button { timesheetVM.goToPreviousMonth() } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .padding(8)
            }

            Spacer()

            Text(timesheetVM.monthTitle)
                .font(.title3.bold())

            Spacer()

            Button { timesheetVM.goToNextMonth() } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .padding(8)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
    }

    // MARK: - Timesheet Content
    private func timesheetContent(sheet: MonthlyTimesheet) -> some View {
        ScrollView {
            VStack(spacing: 16) {

                // Summary Card
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Hours")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(sheet.totalHoursDisplay)
                            .font(.largeTitle.bold())
                            .foregroundColor(.blue)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Sessions")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(sheet.entries.filter { $0.status == .attended }.count)")
                            .font(.largeTitle.bold())
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .padding(.horizontal)

                // Table Header
                HStack {
                    Text("Date").font(.caption.bold()).foregroundColor(.secondary).frame(width: 60, alignment: .leading)
                    Text("Student / Activity").font(.caption.bold()).foregroundColor(.secondary)
                    Spacer()
                    Text("Hrs").font(.caption.bold()).foregroundColor(.secondary).frame(width: 36, alignment: .trailing)
                }
                .padding(.horizontal)
                .padding(.top, 4)

                Divider().padding(.horizontal)

                // Entries
                VStack(spacing: 0) {
                    ForEach(sheet.entries) { entry in
                        if entry.status == .attended {
                            TimesheetRowView(entry: entry)
                            Divider().padding(.leading)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .padding(.horizontal)

                // Total Row
                HStack {
                    Spacer()
                    Text("TOTAL")
                        .font(.subheadline.bold())
                    Text(sheet.totalHoursDisplay)
                        .font(.subheadline.bold())
                        .foregroundColor(.blue)
                        .frame(width: 36, alignment: .trailing)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .padding(.vertical)
        }
    }

    // MARK: - Generate
    private func generate() {
        if let tutor = authVM.currentTutor {
            timesheetVM.generateTimesheet(sessions: sessionVM.sessions, tutorName: tutor.name)
        }
    }
}

// MARK: - Timesheet Row
struct TimesheetRowView: View {
    let entry: TimesheetEntry

    var body: some View {
        HStack {
            Text(entry.formattedDate)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            Text(entry.sessionLabel)
                .font(.subheadline)
                .lineLimit(1)
            Spacer()
            Text(entry.hoursDisplay)
                .font(.subheadline.bold())
                .frame(width: 36, alignment: .trailing)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
