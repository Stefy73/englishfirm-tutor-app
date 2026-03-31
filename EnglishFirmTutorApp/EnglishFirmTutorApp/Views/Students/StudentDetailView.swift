import SwiftUI

struct StudentDetailView: View {

    let student: Student

    @EnvironmentObject var sessionVM: SessionViewModel
    @State private var showingEdit = false

    var studentSessions: [Session] {
        sessionVM.sessions(for: student)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Avatar + Progress
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 80, height: 80)
                        Text(student.initials)
                            .font(.title.bold())
                            .foregroundColor(.blue)
                    }
                    Text(student.name)
                        .font(.title2.bold())
                    Text(student.progressLabel)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue.opacity(0.15))
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue)
                                .frame(width: geo.size.width * student.progressFraction, height: 8)
                        }
                    }
                    .frame(height: 8)
                    .padding(.horizontal, 40)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)

                // Contact Info
                VStack(spacing: 0) {
                    if !student.phone.isEmpty {
                        contactRow(icon: "phone.fill", value: student.phone)
                        Divider().padding(.leading, 44)
                    }
                    if !student.email.isEmpty {
                        contactRow(icon: "envelope.fill", value: student.email)
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)

                // Session History
                if !studentSessions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Session History")
                            .font(.headline)
                            .padding(.horizontal, 4)
                        ForEach(studentSessions) { session in
                            NavigationLink(destination: SessionDetailView(session: session)) {
                                SessionRowView(session: session)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(student.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditStudentView(student: student)
        }
    }

    private func contactRow(icon: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
                .padding(.leading, 16)
            Text(value)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Edit Student View
struct EditStudentView: View {

    let student: Student

    @EnvironmentObject var sessionVM: SessionViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name: String
    @State private var phone: String
    @State private var email: String
    @State private var packageSize: Int
    @State private var notes: String
    @State private var showDeleteConfirm = false

    init(student: Student) {
        self.student = student
        _name = State(initialValue: student.name)
        _phone = State(initialValue: student.phone)
        _email = State(initialValue: student.email)
        _packageSize = State(initialValue: student.packageSize)
        _notes = State(initialValue: student.notes)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Student Details") {
                    TextField("Full Name", text: $name)
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email (optional)", text: $email)
                        .keyboardType(.emailAddress)
                }
                Section("Package") {
                    Stepper("Package Size: \(packageSize) sessions", value: $packageSize, in: 1...100)
                }
                Section("Notes") {
                    TextEditor(text: $notes).frame(minHeight: 80)
                }
                Section {
                    Button("Delete Student", role: .destructive) { showDeleteConfirm = true }
                }
            }
            .navigationTitle("Edit Student")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) { Button("Save") { save() }.disabled(name.isEmpty) }
            }
            .confirmationDialog("Delete \(student.name)?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    sessionVM.deleteStudent(student)
                    dismiss()
                }
            }
        }
    }

    private func save() {
        var updated = student
        updated.name = name
        updated.phone = phone
        updated.email = email
        updated.packageSize = packageSize
        updated.notes = notes
        sessionVM.updateStudent(updated)
        dismiss()
    }
}
