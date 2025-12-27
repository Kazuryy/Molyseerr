//
//  LoginView.swift
//  Molyseerr
//
//  Created by Claude on 25/12/2025.
//

import SwiftUI

/// Login view following Swiftfin design patterns with Seerr animated backdrops
/// Uses List-based layout with centered content over animated TMDB backdrop images
struct LoginView: View {

    @EnvironmentObject var configManager: ConfigManager

    // Login form state
    @State private var authType: AuthType = .jellyfin
    @State private var usernameOrEmail: String = ""
    @State private var password: String = ""
    @State private var isAuthenticating: Bool = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: LoginField?

    enum AuthType: String {
        case jellyfin = "Jellyfin"
        case local = "Seerr"
    }

    enum LoginField: Hashable {
        case usernameOrEmail
        case password
    }

    var body: some View {
        ZStack {
            // Seerr animated backdrop background (pre-loaded by ServerConfigView)
            AnimatedBackgroundView(
                images: configManager.backdrops,
                rotationSpeed: 12.0
            )

            // Login form (Swiftfin-style List)
            List {
                // Header Section
                Section {
                    VStack(spacing: 16) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)

                        Text("Seerr")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .listRowBackground(Color.clear)
                }

                // Auth Type Picker
                Section {
                    Picker("Authentication Type", selection: $authType) {
                        Text(AuthType.jellyfin.rawValue).tag(AuthType.jellyfin)
                        Text(AuthType.local.rawValue).tag(AuthType.local)
                    }
                    .pickerStyle(.segmented)
                }

                // Login Fields Section
                Section {
                    TextField(authType == .jellyfin ? "Username" : "Email", text: $usernameOrEmail)
                        .font(.body)
                        .baselineOffset(5)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(authType == .jellyfin ? .default : .emailAddress)
                        .textContentType(authType == .jellyfin ? .username : .emailAddress)
                        .focused($focusedField, equals: .usernameOrEmail)
                        .onSubmit {
                            focusedField = .password
                        }

                    SecureField("Password", text: $password)
                        .font(.body)
                        .baselineOffset(5)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                        .onSubmit {
                            Task {
                                await login()
                            }
                        }
                }

                // Sign In Button
                if isAuthenticating {
                    Button("Cancel", role: .cancel) {
                        // Cancel authentication
                        isAuthenticating = false
                    }
                    .buttonStyle(.primary)
                    .frame(maxHeight: 75)
                } else {
                    Button("Seerr") {
                        focusedField = nil
                        Task {
                            await login()
                        }
                    }
                    .buttonStyle(.primary)
                    .frame(maxHeight: 75)
                    .disabled(usernameOrEmail.isEmpty)
                    .opacity(usernameOrEmail.isEmpty ? 0.5 : 1)
                }

                // Error Section
                if let error = errorMessage {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.callout)
                    }
                }

                // Footer
                Section {
                    Text("Seerr for Apple TV")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .listRowBackground(Color.clear)
                }
            }
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Auto-focus username/email field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                focusedField = .usernameOrEmail
            }
        }
    }

    // MARK: - Private Methods

    private func login() async {
        guard !usernameOrEmail.isEmpty && !password.isEmpty else {
            print("⚠️ Username/email or password is empty")
            return
        }

        // Clear previous error
        errorMessage = nil
        isAuthenticating = true

        do {
            let user: User

            // Call appropriate API based on auth type
            switch authType {
            case .jellyfin:
                print("🔐 Attempting Jellyfin login with username: \(usernameOrEmail)")
                user = try await SeerrService.shared.loginJellyfin(username: usernameOrEmail, password: password)

            case .local:
                print("🔐 Attempting local login with email: \(usernameOrEmail)")
                user = try await SeerrService.shared.loginLocal(email: usernameOrEmail, password: password)
            }

            print("✅ Login successful - User: \(user.displayName)")

            // Validate session to update authentication state
            // URLSession has automatically stored the session cookie from login response
            await configManager.validateSession()

            // View will automatically navigate to HomeView because
            // configManager.isAuthenticated is now true (from validateSession)

        } catch {
            print("❌ Login failed: \(error)")
            errorMessage = authType == .jellyfin
                ? "Login failed. Please check your username and password."
                : "Login failed. Please check your email and password."
            isAuthenticating = false
        }

        // Note: Don't set isAuthenticating = false here on success
        // because the view will disappear anyway
    }
}

// MARK: - Preview

#Preview {
    LoginView()
        .environmentObject(ConfigManager())
}
