import SwiftUI

struct SessionListView: View {

    @EnvironmentObject var sessionVM: SessionViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @State private var filter: SessionFilter = .upcoming

    enum SessionFilter: String, CaseIterable {
        case upcoming = "Upcoming"
        case past = "Past"
        case all = "All"
    }

    var filteredSessions: [Session] {
        switch filter {
        case .upcoming:
            return (sessionVM.todaysSessions + sessionVM.upcomingSessions)
        case .past:
            return sessionVM.pastSessions
        case .all:
            return sessionVM.sessions.sorted { $0.startTime < $1.startTime }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Picker
                Picker("Filter", selection: $filter) {
                    ForEach(SessionFilter.allCases, id: \.self) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                if sessionVM.isLoading {
                    Spacer()
                    ProgressView("Syncing calendar...")
                    Spacer()
                } else if filteredSessions.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No sessions found")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(groupedByDate.keys.sorted(), id: \.self) { dateKey in
                            Section(header: Text(dateKey).font(.subheadline)) {
                                ForEach(groupedByDate[dateKey] ?? []) { session in
                                    NavigationLink(destination: SessionDetailView(session: session)) {
                                        SessionRowView(session: session)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Sessions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { Task { await sync() } } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }

    private var groupedByDate: [String: [Session]] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMM"
        return Dictionary(grouping: filteredSessions) { session in
            formatter.string(from: session.startTime)
        }
    }

    private func sync() async {
        guard let tutor = authVM.currentTutor else { return }
        await sessionVM.fetchSessions(accessToken: authVM.accessToken, tutorId: tutor.id)
    }
}

struct SessionRowView: View {
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
        HStack(spacing: 12) {
            Image(systemName: session.status.systemImage)
                .foregroundColor(statusColor)
                .font(.title3)

            VStack(alignment: .leading, spacing: 3) {
                Text(session.studentName)
                    .font(.subheadline.bold())
                Text("Session \(session.progressLabel) · \(session.formattedTime)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if session.reminderSent {
                Image(systemName: "bell.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}
