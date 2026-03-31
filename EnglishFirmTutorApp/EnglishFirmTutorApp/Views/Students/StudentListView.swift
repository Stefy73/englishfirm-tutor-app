import SwiftUI

struct StudentListView: View {

    @EnvironmentObject var sessionVM: SessionViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showingAddStudent = false
    @State private var searchText = ""

    var filteredStudents: [Student] {
        if searchText.isEmpty { return sessionVM.students }
        return sessionVM.students.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sessionVM.students.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No students yet")
                            .foregroundColor(.secondary)
                        Button("Add Student") { showingAddStudent = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List(filteredStudents) { student in
                        NavigationLink(destination: StudentDetailView(student: student)) {
                            StudentRowView(student: student)
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search students")
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Students")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddStudent = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddStudent) {
                AddStudentView()
            }
        }
    }
}

// MARK: - Student Row
struct StudentRowView: View {
    let student: Student

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 44, height: 44)
                Text(student.initials)
                    .font(.headline)
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(student.name)
                    .font(.subheadline.bold())
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.blue.opacity(0.15))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.blue)
                            .frame(width: geo.size.width * student.progressFraction, height: 4)
                    }
                }
                .frame(height: 4)

                Text(student.progressLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Student View
struct AddStudentView: View {

    @EnvironmentObject var sessionVM: SessionViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var packageSize = 10
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Student Details") {
                    TextField("Full Name", text: $name)
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email (optional)", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                Section("Package") {
                    Stepper("Package Size: \(packageSize) sessions", value: $packageSize, in: 1...100)
                }
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Add Student")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .disabled(name.isEmpty)
                }
            }
        }
    }

    private func save() {
        let student = Student(
            id: UUID().uuidString,
            name: name,
            phone: phone,
            email: email,
            packageSize: packageSize,
            tutorId: authVM.currentTutor?.id ?? "",
            notes: notes
        )
        sessionVM.addStudent(student)
        dismiss()
    }
}
