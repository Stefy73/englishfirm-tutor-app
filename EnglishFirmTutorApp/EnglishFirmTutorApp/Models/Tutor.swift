import Foundation

struct Tutor: Identifiable, Codable {
    var id: String              // Firebase UID
    var name: String
    var email: String
    var calendarId: String      // Google Calendar ID (usually "primary")
    var avatarURL: String?

    var firstName: String {
        name.components(separatedBy: " ").first ?? name
    }

    var initials: String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }
}
