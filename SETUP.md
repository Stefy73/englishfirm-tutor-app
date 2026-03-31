# EnglishFirm Tutor App — Xcode Setup Guide

## Prerequisites
- Xcode 15+
- iOS 17+ deployment target
- A Google account for Calendar access
- A Firebase account (free tier is fine)

---

## Step 1: Add Swift Package Dependencies

In Xcode: **File → Add Package Dependencies**

Add these two packages:

| Package | URL |
|---|---|
| GoogleSignIn-iOS | `https://github.com/google/GoogleSignIn-iOS` |
| Firebase iOS SDK | `https://github.com/firebase/firebase-ios-sdk` |

**From Firebase SDK, add these products:**
- FirebaseAuth
- FirebaseFirestore

---

## Step 2: Google Cloud Console Setup

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Create a new project (e.g. "EnglishFirm Tutor App")
3. Go to **APIs & Services → Library**
4. Enable: **Google Calendar API**
5. Go to **APIs & Services → Credentials**
6. Click **Create Credentials → OAuth 2.0 Client ID**
7. Application type: **iOS**
8. Enter your app's Bundle ID (e.g. `com.englishfirm.tutorapp`)
9. Download the config file (it downloads as `GoogleService-Info.plist`)

---

## Step 3: Firebase Setup

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Create a new project (can reuse the same Google Cloud project)
3. Click **Add App → iOS**
4. Enter your Bundle ID
5. Download `GoogleService-Info.plist` (this replaces/merges with the one from Step 2)
6. Enable **Authentication → Sign-in method → Google**
7. Enable **Firestore Database** (start in test mode for development)

---

## Step 4: Add GoogleService-Info.plist to Xcode

1. Drag `GoogleService-Info.plist` into your Xcode project
2. Make sure "Copy items if needed" is checked
3. Add to target: EnglishFirmTutorApp ✓

---

## Step 5: Configure Info.plist

Add the following to your `Info.plist`:

```xml
<!-- Google Sign-In URL scheme (from GoogleService-Info.plist REVERSED_CLIENT_ID) -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>YOUR_REVERSED_CLIENT_ID_HERE</string>
    </array>
  </dict>
</array>

<!-- Notification permission description -->
<key>NSUserNotificationsUsageDescription</key>
<string>EnglishFirm uses notifications to remind you about upcoming sessions.</string>
```

The `REVERSED_CLIENT_ID` is found inside `GoogleService-Info.plist`.

---

## Step 6: Implement Real Google Sign-In in LoginView.swift

Replace the stub in `handleGoogleSignIn()` inside `LoginView.swift` with:

```swift
import GoogleSignIn
import FirebaseAuth

private func handleGoogleSignIn() {
    authVM.isLoading = true
    guard let rootVC = UIApplication.shared.connectedScenes
        .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController })
        .first else { return }

    GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, error in
        if let error = error {
            authVM.errorMessage = error.localizedDescription
            authVM.isLoading = false
            return
        }
        guard let user = result?.user,
              let idToken = user.idToken?.tokenString else { return }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: user.accessToken.tokenString
        )
        Auth.auth().signIn(with: credential) { authResult, error in
            DispatchQueue.main.async {
                authVM.isLoading = false
                if let user = authResult?.user {
                    authVM.signIn(
                        tutorId: user.uid,
                        name: user.displayName ?? "",
                        email: user.email ?? "",
                        accessToken: result?.user.accessToken.tokenString ?? ""
                    )
                } else {
                    authVM.errorMessage = error?.localizedDescription
                }
            }
        }
    }
}
```

---

## Step 7: Add New Files to Xcode Project

The Swift source files have been created in the project folder. You need to add them to the Xcode target:

1. In Xcode's Project Navigator, right-click the `EnglishFirmTutorApp` group
2. Select **Add Files to "EnglishFirmTutorApp"**
3. Select all the new folders: `Models/`, `Services/`, `ViewModels/`, `Views/`
4. Make sure "Add to target: EnglishFirmTutorApp" is checked
5. Click Add

---

## File Structure Created

```
EnglishFirmTutorApp/
├── Models/
│   ├── Session.swift          ← Session data model + title parser
│   ├── Student.swift          ← Student profile
│   ├── Tutor.swift            ← Tutor / auth user
│   └── TimesheetEntry.swift   ← Timesheet row + monthly summary
├── Services/
│   ├── GoogleCalendarService.swift  ← Calendar API calls
│   ├── ReminderService.swift        ← SMS/iMessage composition
│   ├── NotificationService.swift   ← Local push notifications
│   └── TimesheetService.swift      ← PDF/CSV export
├── ViewModels/
│   ├── AuthViewModel.swift         ← Sign-in state
│   ├── SessionViewModel.swift      ← Session + student management
│   └── TimesheetViewModel.swift    ← Timesheet generation
├── Views/
│   ├── LoginView.swift             ← Google Sign-In screen
│   ├── DashboardView.swift         ← Home screen with today's sessions
│   ├── Sessions/
│   │   ├── SessionListView.swift   ← All sessions with filter
│   │   └── SessionDetailView.swift ← Attendance + reminder screen
│   ├── Students/
│   │   ├── StudentListView.swift   ← Student list + add student
│   │   └── StudentDetailView.swift ← Student profile + history
│   └── Timesheet/
│       └── TimesheetView.swift     ← Monthly timesheet + export
├── ContentView.swift               ← Root: Login or TabView
└── EnglishFirmTutorAppApp.swift    ← App entry point
```

---

## Notes on Calendar Parsing

The app automatically parses Google Calendar event titles in the format:
- `"Simmi 9 of 12"` → studentName: "Simmi", sessionNumber: 9, totalSessions: 12
- `"Yash 7 of 8"` → studentName: "Yash", sessionNumber: 7, totalSessions: 8
- `"Writing group"` → treated as a group session (no progress tracking)
- `"Saidul 5 – 6pm"` → falls back to using full title as student name

You don't need to change anything in Google Calendar — the app reads your existing events as-is.

---

## Questions?

Contact stefy@englishfirm.com or check the spec document: `EnglishFirm-TutorApp-Specification.docx`
