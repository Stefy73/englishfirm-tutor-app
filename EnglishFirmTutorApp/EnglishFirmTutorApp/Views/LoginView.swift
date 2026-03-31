import SwiftUI

struct LoginView: View {

    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "1A3C6E"), Color(hex: "2E6DB4")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Logo / Branding
                VStack(spacing: 12) {
                    Image(systemName: "person.2.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.9))

                    Text("EnglishFirm")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)

                    Text("Tutor Management")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.75))
                }

                Spacer()

                // Sign In Button
                VStack(spacing: 16) {
                    // Replace this button's action with real GIDSignIn call
                    // See SETUP.md for integration instructions
                    Button(action: handleGoogleSignIn) {
                        HStack(spacing: 12) {
                            Image(systemName: "globe")
                                .font(.title3)
                            Text("Sign in with Google")
                                .font(.headline)
                        }
                        .foregroundColor(Color(hex: "1A3C6E"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 40)

                    if authVM.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }

                    if let error = authVM.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }

                Spacer()

                Text("For EnglishFirm tutors only")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 30)
            }
        }
    }

    // MARK: - Google Sign In
    // TODO: Replace stub with real GIDSignIn integration.
    // See SETUP.md → Step 3 for full implementation.
    private func handleGoogleSignIn() {
        authVM.isLoading = true

        // STUB — replace with:
        // GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
        //     guard let user = result?.user, let token = user.accessToken.tokenString else { return }
        //     authVM.signIn(tutorId: user.userID ?? "", name: user.profile?.name ?? "",
        //                   email: user.profile?.email ?? "", accessToken: token)
        // }

        // Demo login for development:
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            authVM.signIn(
                tutorId: "demo_tutor_1",
                name: "Stefy Thomas",
                email: "stefy@englishfirm.com",
                accessToken: "REPLACE_WITH_REAL_TOKEN"
            )
            authVM.isLoading = false
        }
    }
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    LoginView().environmentObject(AuthViewModel())
}
