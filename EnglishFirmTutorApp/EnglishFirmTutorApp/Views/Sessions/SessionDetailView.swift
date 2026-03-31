import SwiftUI
import MessageUI

struct SessionDetailView: View {

    let session: Session

    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var sessionVM: SessionViewModel
    @State private var currentSession: Session
    @State private var notes: String = ""
    @State private var showingMessageCompose = false
    @State private var messageRecipients: [String] = []
    @State private var messageBody: String = ""
    @State private var showingCancelConfirm = false

    init(session: Session) {
        self.session = session
        _currentSession = State(initialValue: session)
        _notes = State(initialValue: session.notes)
    }

    var student: Student? {
        sessionVM.student(for: currentSession)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Progress Header
                progressHeader

                // Session Info Card
                infoCard

                // Attendance Section
                attendanceSection

                // Reminder Section
                if let student = student, !student.phone.isEmpty {
                    reminderSection(student: student)
                }

                // Notes Section
                notesSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(currentSession.studentName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingMessageCompose) {
            MessageComposeView(
                recipients: messageRecipients,
                body: messageBody,
                isPresented: $showingMessageCompose
            )
        }
        .confirmationDialog("Cancel Session?", isPresented: $showingCancelConfirm, titleVisibility: .visible) {
            Button("Mark as Cancelled", role: .destructive) {
                updateStatus(.cancelled)
            }
            Button("Mark as No-show", role: .destructive) {
                updateStatus(.noShow)
            }
            Button("Cancel", role: .cancel) {}
        }
        .onDisappear {
            if notes != currentSession.notes {
                sessionVM.updateNotes(session: currentSession, notes: notes)
            }
        }
    }

    // MARK: - Progress Header
    private var progressHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.15), lineWidth: 8)
                    .frame(width: 100, height: 100)
                Circle()
                    .trim(from: 0, to: currentSession.progressFraction)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 100, height: 100)
                VStack(spacing: 2) {
                    Text("\(currentSession.sessionNumber)")
                        .font(.title.bold())
                        .foregroundColor(.blue)
                    Text("of \(currentSession.totalSessions)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Text("Session \(currentSession.progressLabel)")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - Info Card
    private var infoCard: some View {
        VStack(spacing: 0) {
            infoRow(icon: "calendar", label: "Date", value: currentSession.formattedDate)
            Divider().padding(.leading, 44)
            infoRow(icon: "clock", label: "Time", value: currentSession.formattedTime)
            Divider().padding(.leading, 44)
            infoRow(icon: "hourglass", label: "Duration", value: String(format: "%.0f min", currentSession.durationHours * 60))
            if let phone = student?.phone, !phone.isEmpty {
                Divider().padding(.leading, 44)
                infoRow(icon: "phone", label: "Phone", value: phone)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
                .padding(.leading, 16)
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(.primary)
                .padding(.trailing, 16)
        }
        .padding(.vertical, 12)
    }

    // MARK: - Attendance Section
    private var attendanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Attendance")
                .font(.headline)
                .padding(.horizontal, 4)

            HStack(spacing: 10) {
                AttendanceButton(title: "Attended", icon: "checkmark.circle.fill", color: .green,
                                 isSelected: currentSession.status == .attended) {
                    updateStatus(.attended)
                }
                Button {
                    showingCancelConfirm = true
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Cancelled")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        (currentSession.status == .cancelled || currentSession.status == .noShow)
                        ? Color.red : Color(.secondarySystemGroupedBackground)
                    )
                    .foregroundColor(
                        (currentSession.status == .cancelled || currentSession.status == .noShow)
                        ? .white : .secondary
                    )
                    .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Reminder Section
    private func reminderSection(student: Student) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reminders")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 10) {
                Button {
                    sendReminder(to: student, isOneHour: false)
                } label: {
                    Label("Send 24h Reminder", systemImage: "message.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button {
                    sendReminder(to: student, isOneHour: true)
                } label: {
                    Label("Send 1h Reminder", systemImage: "bell.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.secondarySystemGroupedBackground))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                }

                if currentSession.reminderSent {
                    Label("Reminder sent", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
    }

    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
                .padding(.horizontal, 4)
            TextEditor(text: $notes)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
        }
    }

    // MARK: - Actions
    private func updateStatus(_ status: SessionStatus) {
        sessionVM.markAttendance(session: currentSession, status: status)
        currentSession.status = status
    }

    private func sendReminder(to student: Student, isOneHour: Bool) {
        let tutorName = authVM.currentTutor?.firstName ?? "your tutor"
        let firstName = student.name.components(separatedBy: " ").first ?? student.name
        messageRecipients = [student.phone]
        messageBody = ReminderService.shared.reminderMessage(
            studentFirstName: firstName,
            tutorName: tutorName,
            time: currentSession.formattedTime,
            isOneHour: isOneHour
        )
        showingMessageCompose = true
        sessionVM.markReminderSent(session: currentSession)
        currentSession.reminderSent = true
    }
}

// MARK: - Attendance Button
struct AttendanceButton: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? color : Color(.secondarySystemGroupedBackground))
            .foregroundColor(isSelected ? .white : .secondary)
            .cornerRadius(12)
        }
    }
}
