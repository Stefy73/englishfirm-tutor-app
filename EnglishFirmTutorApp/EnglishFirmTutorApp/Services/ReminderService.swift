import Foundation
import MessageUI

// MARK: - Reminder Service
// Handles composing and sending SMS/iMessage reminders to students.
// Uses iOS MessageUI framework — no third-party dependencies required.
//
// Usage: Call ReminderService.shared.composeReminder(for:session:in:)
// from within a UIViewController context.

final class ReminderService: NSObject, ObservableObject {

    static let shared = ReminderService()

    @Published var canSendMessages: Bool = MFMessageComposeViewController.canSendText()

    // MARK: - Message Templates
    func reminderMessage(studentFirstName: String, tutorName: String, time: String, isOneHour: Bool) -> String {
        if isOneHour {
            return "Hi \(studentFirstName)! Your English session with \(tutorName) starts in 1 hour at \(time). See you soon! 😊"
        } else {
            return "Hi \(studentFirstName)! Just a reminder that you have an English session with \(tutorName) tomorrow at \(time). See you then! 😊"
        }
    }

    func cancellationMessage(studentFirstName: String, tutorName: String, dateTime: String) -> String {
        return "Hi \(studentFirstName), unfortunately your session with \(tutorName) scheduled for \(dateTime) has been cancelled. We'll be in touch to reschedule."
    }

    // MARK: - Compose Reminder
    // Returns a configured MFMessageComposeViewController ready to present.
    func composeReminder(
        for student: Student,
        session: Session,
        tutorName: String,
        isOneHour: Bool = false
    ) -> MFMessageComposeViewController? {
        guard MFMessageComposeViewController.canSendText() else { return nil }
        guard !student.phone.isEmpty else { return nil }

        let firstName = student.name.components(separatedBy: " ").first ?? student.name
        let message = reminderMessage(
            studentFirstName: firstName,
            tutorName: tutorName,
            time: session.formattedTime,
            isOneHour: isOneHour
        )

        let vc = MFMessageComposeViewController()
        vc.recipients = [student.phone]
        vc.body = message
        vc.messageComposeDelegate = self
        return vc
    }

    // MARK: - Compose Cancellation
    func composeCancellation(
        for student: Student,
        session: Session,
        tutorName: String
    ) -> MFMessageComposeViewController? {
        guard MFMessageComposeViewController.canSendText() else { return nil }
        guard !student.phone.isEmpty else { return nil }

        let firstName = student.name.components(separatedBy: " ").first ?? student.name
        let dateTime = "\(session.formattedDate) at \(session.formattedTime)"
        let message = cancellationMessage(studentFirstName: firstName, tutorName: tutorName, dateTime: dateTime)

        let vc = MFMessageComposeViewController()
        vc.recipients = [student.phone]
        vc.body = message
        vc.messageComposeDelegate = self
        return vc
    }
}

// MARK: - MFMessageComposeViewControllerDelegate
extension ReminderService: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(
        _ controller: MFMessageComposeViewController,
        didFinishWith result: MessageComposeResult
    ) {
        controller.dismiss(animated: true)
    }
}

// MARK: - SwiftUI MessageSheet Wrapper
// Use this in SwiftUI views to present the message composer.
import SwiftUI
import UIKit

struct MessageComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let body: String
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let vc = MFMessageComposeViewController()
        vc.recipients = recipients
        vc.body = body
        vc.messageComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(isPresented: $isPresented) }

    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        @Binding var isPresented: Bool
        init(isPresented: Binding<Bool>) { _isPresented = isPresented }

        func messageComposeViewController(
            _ controller: MFMessageComposeViewController,
            didFinishWith result: MessageComposeResult
        ) {
            isPresented = false
        }
    }
}
