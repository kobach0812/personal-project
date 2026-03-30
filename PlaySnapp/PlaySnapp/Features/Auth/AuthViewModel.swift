import Combine
import Foundation

enum AuthMethod: String, CaseIterable, Identifiable {
    case email = "Email"
    case phone = "Phone"

    var id: Self { self }
}

enum EmailAuthMode: String, CaseIterable, Identifiable {
    case signIn = "Sign In"
    case register = "Register"

    var id: Self { self }
}

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var authMethod: AuthMethod = .email {
        didSet {
            guard authMethod != oldValue else {
                return
            }

            errorMessage = nil
            pendingPhoneVerificationID = nil
            verificationDestination = nil
            verificationCode = ""
        }
    }
    @Published var emailAuthMode: EmailAuthMode = .signIn {
        didSet {
            guard emailAuthMode != oldValue else {
                return
            }

            errorMessage = nil
        }
    }
    @Published var email = ""
    @Published var password = ""
    @Published var phoneNumber = ""
    @Published var verificationCode = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var pendingPhoneVerificationID: String?
    @Published private(set) var verificationDestination: String?

    var isAwaitingPhoneCode: Bool {
        pendingPhoneVerificationID != nil
    }

    var primaryButtonTitle: String {
        switch authMethod {
        case .email:
            switch emailAuthMode {
            case .signIn:
                return isLoading ? "Signing In..." : "Sign In"
            case .register:
                return isLoading ? "Creating Account..." : "Create Account"
            }
        case .phone:
            if isAwaitingPhoneCode {
                return isLoading ? "Verifying Code..." : "Verify Code"
            }

            return isLoading ? "Sending Code..." : "Send Code"
        }
    }

    func submit(
        authService: AuthServicing,
        router: AppRouter
    ) async {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            switch authMethod {
            case .email:
                let session = try await submitEmail(authService: authService)
                router.handleSessionUpdate(session)
            case .phone:
                if let session = try await submitPhone(authService: authService) {
                    router.handleSessionUpdate(session)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetPhoneVerification() {
        pendingPhoneVerificationID = nil
        verificationDestination = nil
        verificationCode = ""
        errorMessage = nil
    }
}

private extension AuthViewModel {
    func submitEmail(authService: AuthServicing) async throws -> AppSession {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty else {
            throw AuthFormError.missingEmail
        }

        guard !trimmedPassword.isEmpty else {
            throw AuthFormError.missingPassword
        }

        switch emailAuthMode {
        case .signIn:
            return try await authService.signIn(email: trimmedEmail, password: trimmedPassword)
        case .register:
            return try await authService.register(email: trimmedEmail, password: trimmedPassword)
        }
    }

    func submitPhone(authService: AuthServicing) async throws -> AppSession? {
        if let pendingPhoneVerificationID {
            let trimmedCode = verificationCode.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedCode.isEmpty else {
                throw AuthFormError.missingVerificationCode
            }

            return try await authService.verifyPhoneNumber(
                code: trimmedCode,
                verificationID: pendingPhoneVerificationID
            )
        }

        let trimmedPhoneNumber = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPhoneNumber.isEmpty else {
            throw AuthFormError.missingPhoneNumber
        }

        pendingPhoneVerificationID = try await authService.sendPhoneVerificationCode(
            to: trimmedPhoneNumber
        )
        verificationDestination = trimmedPhoneNumber
        verificationCode = ""
        return nil
    }
}

private enum AuthFormError: LocalizedError {
    case missingEmail
    case missingPassword
    case missingPhoneNumber
    case missingVerificationCode

    var errorDescription: String? {
        switch self {
        case .missingEmail:
            return "Enter your email to continue."
        case .missingPassword:
            return "Enter your password to continue."
        case .missingPhoneNumber:
            return "Enter your phone number to receive a verification code."
        case .missingVerificationCode:
            return "Enter the verification code that was sent to your phone."
        }
    }
}
