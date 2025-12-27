//
//  ServerConfigView.swift
//  Molyseerr
//
//  Created by Claude on 25/12/2025.
//

import SwiftUI

/// Initial server configuration view - Following Swiftfin design patterns
/// Shown when user first launches the app to configure server URL
struct ServerConfigView: View {

    @EnvironmentObject var configManager: ConfigManager
    @State private var serverURL: String = ""
    @State private var isVerifying: Bool = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case serverURL
    }

    var body: some View {
        List {
            Section {
                // Logo and Title Header
                VStack(spacing: 16) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 80, weight: .thin))
                        .foregroundColor(Color.Seerr.purple)

                    Text("Molyseerr")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("Connect to your Seerr server")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .listRowBackground(Color.clear)
            }

            Section("Server Configuration") {
                TextField("Server URL", text: $serverURL)
                    .font(.body)
                    .baselineOffset(5)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .focused($focusedField, equals: .serverURL)
            }

            if isVerifying {
                Button("Cancel", role: .cancel) {
                    // Cancel connection
                }
                .buttonStyle(.primary)
                .frame(maxHeight: 75)
            } else {
                Button("Connect") {
                    focusedField = nil
                    Task {
                        await verifyAndConnect()
                    }
                }
                .buttonStyle(.primary)
                .frame(maxHeight: 75)
                .disabled(serverURL.isEmpty)
                .opacity(serverURL.isEmpty ? 0.5 : 1)
            }

            if let error = errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.callout)
                }
            }

            Section {
                VStack(spacing: 8) {
                    Text("Example: http://192.168.1.100:5055")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Seerr for Apple TV")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .listRowBackground(Color.clear)
            }
        }
        .frame(maxWidth: 800)
        .frame(maxWidth: .infinity)
        .preferredColorScheme(.dark)
        .onAppear {
            // Auto-focus server URL field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                focusedField = .serverURL
            }
        }
    }

    // MARK: - Private Methods

    private func verifyAndConnect() async {
        // Clear previous error
        errorMessage = nil
        isVerifying = true

        print("🔌 Verifying server: \(serverURL)")

        // Temporarily configure the server
        configManager.configure(baseURL: serverURL)

        // Verify that the server is reachable and is a valid Seerr instance
        let isValid = await configManager.verifyConfiguration()

        if isValid {
            print("✅ Server verified successfully")

            // Pre-load backdrops before showing login page
            print("🎬 Loading backdrops...")
            await configManager.loadBackdrops()
            print("✅ Backdrops loaded, ready for login")

            // Configuration is ready, LoginView will appear
        } else {
            print("❌ Server verification failed")
            errorMessage = "Unable to connect to server. Please check the URL and try again."

            // Reset configuration
            configManager.configure(baseURL: "")
        }

        isVerifying = false
    }
}

// MARK: - Preview

#Preview {
    ServerConfigView()
        .environmentObject(ConfigManager())
}
