import Foundation

// MARK: - Google Calendar Service
// Uses the Google Calendar REST API v3 via URLSession.
// Requires a valid OAuth2 access token from GoogleSignIn.
//
// Setup: Add GoogleSignIn-iOS via Swift Package Manager:
//   https://github.com/google/GoogleSignIn-iOS
// And enable the Google Calendar API in Google Cloud Console.

final class GoogleCalendarService: ObservableObject {

    static let shared = GoogleCalendarService()
    private let baseURL = "https://www.googleapis.com/calendar/v3"

    // MARK: - Fetch Sessions for a date range
    func fetchSessions(
        accessToken: String,
        calendarId: String = "primary",
        tutorId: String,
        from startDate: Date,
        to endDate: Date
    ) async throws -> [Session] {

        let formatter = ISO8601DateFormatter()
        let timeMin = formatter.string(from: startDate)
        let timeMax = formatter.string(from: endDate)

        var components = URLComponents(string: "\(baseURL)/calendars/\(calendarId)/events")!
        components.queryItems = [
            URLQueryItem(name: "timeMin", value: timeMin),
            URLQueryItem(name: "timeMax", value: timeMax),
            URLQueryItem(name: "singleEvents", value: "true"),
            URLQueryItem(name: "orderBy", value: "startTime"),
            URLQueryItem(name: "maxResults", value: "250"),
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw CalendarError.requestFailed
        }

        let decoded = try JSONDecoder().decode(CalendarEventListResponse.self, from: data)
        return decoded.items.compactMap { event -> Session? in
            guard let startStr = event.start?.dateTime ?? event.start?.date,
                  let endStr   = event.end?.dateTime   ?? event.end?.date else { return nil }

            let dateParser = ISO8601DateFormatter()
            dateParser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let dateFallback = DateFormatter()
            dateFallback.dateFormat = "yyyy-MM-dd"

            let start = dateParser.date(from: startStr) ?? dateFallback.date(from: startStr)
            let end   = dateParser.date(from: endStr)   ?? dateFallback.date(from: endStr)
            guard let startDate = start, let endDate = end else { return nil }

            return Session.parse(
                title: event.summary ?? "Session",
                eventId: event.id,
                startTime: startDate,
                endTime: endDate,
                tutorId: tutorId
            )
        }
    }

    // MARK: - Convenience: fetch this week
    func fetchThisWeekSessions(accessToken: String, tutorId: String) async throws -> [Session] {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
        return try await fetchSessions(accessToken: accessToken, tutorId: tutorId, from: weekStart, to: weekEnd)
    }

    // MARK: - Convenience: fetch a specific month
    func fetchMonth(accessToken: String, tutorId: String, month: Int, year: Int) async throws -> [Session] {
        var startComponents = DateComponents()
        startComponents.month = month
        startComponents.year = year
        startComponents.day = 1
        let start = Calendar.current.date(from: startComponents)!
        let end = Calendar.current.date(byAdding: .month, value: 1, to: start)!
        return try await fetchSessions(accessToken: accessToken, tutorId: tutorId, from: start, to: end)
    }
}

// MARK: - Errors
enum CalendarError: LocalizedError {
    case requestFailed
    case noToken

    var errorDescription: String? {
        switch self {
        case .requestFailed: return "Failed to fetch calendar events. Please check your connection."
        case .noToken:       return "Not signed in. Please log in again."
        }
    }
}

// MARK: - Codable Response Models
private struct CalendarEventListResponse: Decodable {
    let items: [CalendarEvent]
}

private struct CalendarEvent: Decodable {
    let id: String
    let summary: String?
    let start: EventDateTime?
    let end: EventDateTime?
}

private struct EventDateTime: Decodable {
    let dateTime: String?
    let date: String?       // All-day events use "date" not "dateTime"
}
