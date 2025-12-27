//
//  SettingsView.swift
//  Molyseerr
//
//  Created by Claude on 25/12/2025.
//

import SwiftUI

/// Settings view with logout functionality
/// Follows Seerr's security model for proper session termination
struct SettingsView: View {

    @EnvironmentObject var configManager: ConfigManager
    @Environment(\.dismiss) private var dismiss
    @State private var isLoggingOut: Bool = false
    @State private var showLogoutConfirmation: Bool = false
    @State private var showRemoveServerConfirmation: Bool = false
    @State private var isRemovingServer: Bool = false
    @State private var serverStatus: ServerStatus?
    @State private var isLoadingStatus: Bool = false

    // MARK: - Constants (tvOS specs)
    private let buttonWidth: CGFloat = 600
    private let buttonHeight: CGFloat = 70

    var body: some View {
        ZStack {
            // Background gradient (matching login/server config)
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.3, green: 0.1, blue: 0.4)  // Dark purple
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 50) {
                    // Header
                    VStack(spacing: 10) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)

                        Text("Settings")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 80)

                // User info card
                if let user = configManager.currentUser {
                    VStack(spacing: 20) {
                        // User avatar or icon
                        if let avatarPath = user.avatar, !avatarPath.isEmpty {
                            // TODO: Load actual avatar image
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 100))
                                .foregroundColor(.blue)
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 100))
                                .foregroundColor(.blue)
                        }

                        Text(user.displayName)
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundColor(.white)

                        // Auth type badge
                        HStack(spacing: 8) {
                            Image(systemName: user.jellyfinUsername != nil ? "play.tv.fill" : "envelope.fill")
                                .font(.system(size: 16))

                            Text(user.jellyfinUsername != nil ? "Jellyfin Account" : "Seerr Account")
                                .font(.system(size: 18))
                        }
                        .foregroundColor(.secondary)
                    }
                    .padding(40)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.1))
                            .background(.ultraThinMaterial)
                    )
                    .frame(width: 700)
                }

                // Server management section
                VStack(spacing: 30) {
                    // Section title
                    Text("Server Management")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 50)

                    // Server info card
                    VStack(spacing: 20) {
                        HStack {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Server URL")
                                    .font(.system(size: 18))
                                    .foregroundColor(.secondary)

                                Text(configManager.baseURL)
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundColor(.white)
                            }

                            Spacer()

                            // Server status indicator
                            if isLoadingStatus {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            } else if let status = serverStatus {
                                VStack(alignment: .trailing, spacing: 5) {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 12, height: 12)
                                        Text("Online")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.green)
                                    }

                                    Text("v\(status.version)")
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                VStack(alignment: .trailing, spacing: 5) {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 12, height: 12)
                                        Text("Offline")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }

                        Divider()
                            .background(Color.white.opacity(0.3))

                        // Remove server button
                        Button(action: {
                            showRemoveServerConfirmation = true
                        }) {
                            if isRemovingServer {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            } else {
                                HStack(spacing: 12) {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 20))
                                    Text("Remove Server")
                                        .font(.system(size: 24, weight: .semibold))
                                }
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                            }
                        }
                        .disabled(isRemovingServer)
                        .alert("Remove Server", isPresented: $showRemoveServerConfirmation) {
                            Button("Cancel", role: .cancel) { }
                            Button("Remove", role: .destructive) {
                                Task {
                                    await handleRemoveServer()
                                }
                            }
                        } message: {
                            Text("This will logout and remove the server configuration. You will need to reconfigure the server to use the app again.")
                        }
                    }
                    .padding(30)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.1))
                            .background(.ultraThinMaterial)
                    )
                    .frame(width: 700)
                }

                // Logout button
                Button(action: {
                    showLogoutConfirmation = true
                }) {
                    if isLoggingOut {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .frame(width: buttonWidth, height: buttonHeight)
                            .background(Color.red.opacity(0.6))
                            .cornerRadius(10)
                    } else {
                        HStack(spacing: 12) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 24))
                            Text("Logout")
                                .font(.system(size: 32, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(width: buttonWidth, height: buttonHeight)
                        .background(Color.red)
                        .cornerRadius(10)
                    }
                }
                .disabled(isLoggingOut)
                .alert("Confirm Logout", isPresented: $showLogoutConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Logout", role: .destructive) {
                        Task {
                            await handleLogout()
                        }
                    }
                } message: {
                    Text("Are you sure you want to logout?")
                }
                .padding(.bottom, 80)
                }
            }
        }
        .task {
            // Load server status when view appears
            await loadServerStatus()
        }
    }

    // MARK: - Private Methods

    private func loadServerStatus() async {
        isLoadingStatus = true

        do {
            // Try to get server status
            let status = try await SeerrService.shared.getStatus()
            serverStatus = status
            print("✅ Server status loaded: v\(status.version)")
        } catch {
            print("❌ Failed to load server status: \(error)")
            serverStatus = nil
        }

        isLoadingStatus = false
    }

    private func handleLogout() async {
        isLoggingOut = true

        // Call server logout and clear session
        await configManager.logout()

        // Dismiss settings view
        dismiss()

        // Note: ConfigManager.isAuthenticated is now false,
        // so RootView will automatically show LoginView

        isLoggingOut = false
    }

    private func handleRemoveServer() async {
        isRemovingServer = true

        // First, logout and destroy session
        await configManager.logout()

        // Then, reset all configuration (clears server URL)
        await configManager.reset()

        // Dismiss settings view
        dismiss()

        // Note: ConfigManager.isConfigured is now false,
        // so RootView will automatically show ServerConfigView

        isRemovingServer = false
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(ConfigManager())
}
