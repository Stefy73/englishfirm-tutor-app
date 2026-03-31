import Foundation
import SwiftUI

// MARK: - Auth View Model
// Manages Google Sign-In state.
// Replace the stub implementations below with real GoogleSignIn SDK calls
// after adding the package: https://github.com/google/GoogleSignIn-iOS
//
// See SETUP.md for full configuration instructions.

@MainActor
final class AuthViewModel: ObservableObject {

    @Published var currentTutor: Tutor? = nil
    @Published var isSignedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    // Persisted access token for Google Calendar API calls
    @Published var accessToken: String = ""

    // MARK: - Sign In with Google
    // Wire this up to GIDSignIn.sharedInstance.signIn(withPresenting:) in your app
    func signIn(tutorId: String, name: String, email: String, accessToken: String) {
        self.accessToken = accessToken
        let tutor = Tutor(id: tutorId, name: name, email: email, calendarId: "primary")
        self.currentTutor = tutor
        self.isSignedIn = true
        // Persist tutor info locally
        saveTutor(tutor)
    }

    // MARK: - Sign Out
    func signOut() {
        currentTutor = nil
        isSignedIn = false
        accessToken = ""
        UserDefaults.standard.removeObject(forKey: "savedTutor")
    }

    // MARK: - Restore Session on Launch
    func restoreSession() {
        if let data = UserDefaults.standard.data(forKey: "savedTutor"),
           let tutor = try? JSONDecoder().decode(Tutor.self, from: data) {
            currentTutor = tutor
            isSignedIn = true
            // Note: access token must be refreshed via GoogleSignIn on each launch
        }
    }

    // MARK: - Private
    private func saveTutor(_ tutor: Tutor) {
        if let data = try? JSONEncoder().encode(tutor) {
            UserDefaults.standard.set(data, forKey: "savedTutor")
        }
    }
}
