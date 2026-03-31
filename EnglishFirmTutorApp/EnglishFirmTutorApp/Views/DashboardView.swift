import SwiftUI

struct DashboardView: View {

    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var sessionVM: SessionViewModel

    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Greeting Header
                    headerSection

                    // Stats Row
                    statsRow

                    // Today's Sessions
                    if !sessionVM.todaysSessions.isEmpty {
                        sectionHeader("Today's Sessions")
                        ForEach(sessionVM.todaysSessions) { session in
                            NavigationLink(destination: SessionDetailView(session: session)) {
                                SessionCard(session: session)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    } else {
                        emptyTodayCard
                    }

                    // Upcoming Sessions
                    if !sessionVM.upcomingSessions.isEmpty {
                        sectionHeader("Upcoming")
                        ForEach(sessionVM.upcomingSessions.prefix(5)) { session in
                            NavigationLink(destination: SessionDetailView(session: session)) {
                                SessionCard(session: session)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gear")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { Task { await syncCalendar() } }) {
                        Label("Sync", systemImage: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) { SettingsView() }
            .task { await syncCalendar() }
        }
    }

    // MARK: - Subviews
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greetingText)
                .font(.title2.bold())
            Text(Date().formatted(date: .complete, time: .omitted))
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let synced = sessionVM.lastSynced {
                Text("Last synced \(synced.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 8)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(title: "Today", value: "\(sessionVM.todaysSessions.count)", icon: "calendar", color: .blue)
            StatCard(title: "This Week", value: "\(sessionVM.sessions.filter { isThisWeek($0.startTime) }.count)", icon: "calendar.badge.clock", color: .purple)
            StatCard(title: "Students", value: "\(sessionVM.students.count)", icon: "person.2.fill", color: .green)
        }
    }

    private var emptyTodayCard: some View {
        HStack {
            Image(systemName: "checkmark.circle")
                .foregroundColor(.green)
            Text("No sessions today")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.primary)
            .padding(.top, 4)
    }

    // MARK: - Helpers
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = authVM.currentTutor?.firstName ?? "Tutor"
        if hour < 12 { return "Good morning, \(name)" }
        if hour < 17 { return "Good afternoon, \(name)" }
        return "Good evening, \(name)"
    }

    private func isThisWeek(_ date: Date) -> Bool {
        Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
    }

    private func syncCalendar() async {
        guard let tutor = authVM.currentTutor else { return }
        await sessionVM.fetchSessions(accessToken: authVM.accessToken, tutorId: tutor.id)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.title.bold())
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Session Card
struct SessionCard: View {
    let session: Session

    var statusColor: Color {
        switch session.status {
        case .scheduled: return .blue
        case .attended:  return .green
        case .cancelled: return .orange
        case .noShow:    return .red
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Time column
            VStack(spacing: 2) {
                Text(session.formattedTime)
                    .font(.caption.bold())
                    .foregroundColor(.primary)
            }
            .frame(width: 56)

            // Progress ring
            ZStack {
                Circle()
                    .stroke(statusColor.opacity(0.2), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: session.progressFraction)
                    .stroke(statusColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(session.sessionNumber)")
                    .font(.caption2.bold())
                    .foregroundColor(statusColor)
            }
            .frame(width: 36, height: 36)

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(session.studentName)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                Text("Session \(session.progressLabel)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Status badge
            Text(session.status.rawValue)
                .font(.caption2.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.15))
                .foregroundColor(statusColor)
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Settings View (stub)
struct SettingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    LabeledContent("Name", value: authVM.currentTutor?.name ?? "")
                    LabeledContent("Email", value: authVM.currentTutor?.email ?? "")
                }
                Section {
                    Button("Sign Out", role: .destructive) {
                        authVM.signOut()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthViewModel())
        .environmentObject(SessionViewModel())
}
