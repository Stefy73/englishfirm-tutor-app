import Foundation

struct Student: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var phone: String
    var email: String
    var packageSize: Int        // Total sessions in their package
    var tutorId: String
    var notes: String

    // Computed from sessions — populated by SessionViewModel
    var completedSessions: Int = 0

    var remainingSessions: Int {
        max(0, packageSize - completedSessions)
    }

    var progressFraction: Double {
        guard packageSize > 0 else { return 0 }
        return Double(completedSessions) / Double(packageSize)
    }

    var progressLabel: String {
        "\(completedSessions)/\(packageSize) sessions"
    }

    var initials: String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }

    // For MessageUI pre-fill
    var reminderMessage: String {
        "Hi \(name.components(separatedBy: " ").first ?? name)! Just a reminder that you have an English session coming up. See you soon! 😊"
    }
}
