import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("PlaySnap")
                        .font(.system(size: 40, weight: .bold, design: .rounded))

                    Text("Share real plays with your squad instantly.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                Picker("Authentication Method", selection: $viewModel.authMethod) {
                    ForEach(AuthMethod.allCases) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                .pickerStyle(.segmented)

                if viewModel.authMethod == .email {
                    emailForm
                } else {
                    phoneForm
                }

                Button {
                    Task {
                        await viewModel.submit(
                            authService: environment.authService,
                            router: router
                        )
                    }
                } label: {
                    Text(viewModel.primaryButtonTitle)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.isLoading)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Text("Traditional sign-in is active for now. Email/password is ready, phone verification can be used when the Firebase Phone provider is configured, and Sign in with Apple can be added back later.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private extension AuthView {
    var emailForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Account Mode", selection: $viewModel.emailAuthMode) {
                ForEach(EmailAuthMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            VStack(spacing: 12) {
                TextField("Email", text: $viewModel.email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .textContentType(.username)

                SecureField("Password", text: $viewModel.password)
                    .textContentType(.password)
            }
            .textFieldStyle(.roundedBorder)
        }
    }

    var phoneForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField("Phone number", text: $viewModel.phoneNumber)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
                .textFieldStyle(.roundedBorder)

            if viewModel.isAwaitingPhoneCode {
                SecureField("Verification code", text: $viewModel.verificationCode)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .textFieldStyle(.roundedBorder)

                if let verificationDestination = viewModel.verificationDestination {
                    Text("Code sent to \(verificationDestination).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Button("Use a different number") {
                    viewModel.resetPhoneVerification()
                }
                .buttonStyle(.bordered)
            } else {
                Text("Use your number in international format, for example +447700900123.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
