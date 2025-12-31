//
//  SettingsView.swift
//  Molyseerr
//
//  Created by Claude on 31/12/2025.
//

import SwiftUI

/// Enhanced Settings view with user preferences
/// Follows tvOS design guidelines with organized sections
struct SettingsView: View {
    @EnvironmentObject var configManager: ConfigManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()

    @State private var isLoggingOut: Bool = false
    @State private var showLogoutConfirmation: Bool = false
    @State private var showRemoveServerConfirmation: Bool = false
    @State private var isRemovingServer: Bool = false
    @State private var serverStatus: ServerStatus?
    @State private var isLoadingStatus: Bool = false

    // Picker sheet states
    @State private var showLocalePicker: Bool = false
    @State private var showDiscoverRegionPicker: Bool = false
    @State private var showStreamingRegionPicker: Bool = false
    @State private var showOriginalLanguagePicker: Bool = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.Seerr.background,
                    Color(red: 0.3, green: 0.1, blue: 0.4)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 50) {
                    // Header
                    header

                    // User Profile Card
                    if let user = configManager.currentUser {
                        userProfileCard(user: user)
                    }

                    // Settings Sections
                    if !viewModel.isLoading {
                        settingsSections
                    } else {
                        loadingView
                    }

                    // Server Management Section
                    serverManagementSection

                    // Save Button (if there are unsaved changes)
                    if viewModel.hasUnsavedChanges {
                        saveButton
                    }

                    // Logout Button
                    logoutButton

                    // Success/Error Messages
                    if let successMessage = viewModel.successMessage {
                        messageView(message: successMessage, isError: false)
                    }
                    if let errorMessage = viewModel.errorMessage {
                        messageView(message: errorMessage, isError: true)
                    }
                }
                .padding(.bottom, 80)
            }
        }
        .task {
            await loadServerStatus()
            if let user = configManager.currentUser {
                await viewModel.loadSettings(userId: user.id)
            }
        }
        // Picker sheets
        .sheet(isPresented: $showLocalePicker) {
            pickerSheet(
                title: "Display Language",
                items: viewModel.availableLocales,
                selection: $viewModel.locale
            )
        }
        .sheet(isPresented: $showDiscoverRegionPicker) {
            pickerSheet(
                title: "Discover Region",
                items: viewModel.availableRegions,
                selection: $viewModel.discoverRegion
            )
        }
        .sheet(isPresented: $showStreamingRegionPicker) {
            pickerSheet(
                title: "Streaming Region",
                items: viewModel.availableRegions,
                selection: $viewModel.streamingRegion
            )
        }
        .sheet(isPresented: $showOriginalLanguagePicker) {
            pickerSheet(
                title: "Original Language",
                items: viewModel.availableLanguages,
                selection: $viewModel.originalLanguage
            )
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 80))
                .foregroundColor(.white)

            Text("Settings")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.top, 80)
    }

    // MARK: - User Profile Card

    private func userProfileCard(user: User) -> some View {
        VStack(spacing: 20) {
            // User avatar
            Image(systemName: "person.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.blue)

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

            // Email (if available)
            if let email = user.email {
                Text(email)
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .background(.ultraThinMaterial)
        )
        .frame(width: 700)
    }

    // MARK: - Settings Sections

    @ViewBuilder
    private var settingsSections: some View {
        // Display Preferences Section
        SettingsSection(title: "Display Preferences", icon: "display") {
            SettingsPickerRow(
                title: "Display Language",
                description: "Language for the app interface",
                currentValue: viewModel.localeName(for: viewModel.locale),
                icon: "globe",
                action: { showLocalePicker = true }
            )

            SettingsPickerRow(
                title: "Discover Region",
                description: "Filter content by regional availability",
                currentValue: viewModel.regionName(for: viewModel.discoverRegion),
                icon: "map",
                action: { showDiscoverRegionPicker = true }
            )

            SettingsPickerRow(
                title: "Streaming Region",
                description: "Show streaming sites by region",
                currentValue: viewModel.regionName(for: viewModel.streamingRegion),
                icon: "play.rectangle",
                action: { showStreamingRegionPicker = true }
            )

            SettingsPickerRow(
                title: "Original Language",
                description: "Filter by original language",
                currentValue: viewModel.languageName(for: viewModel.originalLanguage),
                icon: "text.bubble",
                action: { showOriginalLanguagePicker = true }
            )
        }

        // Auto-Request Section
        SettingsSection(title: "Watchlist Auto-Request", icon: "arrow.down.circle") {
            SettingsToggleRow(
                title: "Auto-Request Movies",
                description: "Automatically request movies added to watchlist",
                isOn: $viewModel.autoRequestMovies,
                icon: "film"
            )

            SettingsToggleRow(
                title: "Auto-Request TV Shows",
                description: "Automatically request TV shows added to watchlist",
                isOn: $viewModel.autoRequestTV,
                icon: "tv"
            )
        }

        // Notifications Section (Read-only)
        if viewModel.hasNotificationsConfigured {
            SettingsSection(title: "Notifications", icon: "bell") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Configured Methods")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)

                    ForEach(viewModel.notificationMethods, id: \.self) { method in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(method)
                                .font(.system(size: 18))
                                .foregroundColor(.secondary)
                        }
                    }

                    Text("Configure notification settings on the web interface")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .background(.ultraThinMaterial)
                )
            }
        }

        // About Section
        SettingsSection(title: "About", icon: "info.circle") {
            VStack(alignment: .leading, spacing: 16) {
                if let status = serverStatus {
                    aboutRow(title: "Server Version", value: status.version)
                }
                aboutRow(title: "App Version", value: "1.0.0")
                aboutRow(title: "Open Source", value: "MIT License")
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .background(.ultraThinMaterial)
            )
        }
    }

    private func aboutRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 20))
                .foregroundColor(.white)
            Spacer()
            Text(value)
                .font(.system(size: 20))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Server Management Section

    private var serverManagementSection: some View {
        VStack(spacing: 30) {
            Text("Server Management")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 50)

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
                    }
                }

                Divider()
                    .background(Color.white.opacity(0.3))

                Button(action: { showRemoveServerConfirmation = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "trash.fill")
                        Text("Remove Server")
                            .font(.system(size: 24, weight: .semibold))
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .disabled(isRemovingServer)
                .alert("Remove Server", isPresented: $showRemoveServerConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Remove", role: .destructive) {
                        Task { await handleRemoveServer() }
                    }
                } message: {
                    Text("This will logout and remove the server configuration.")
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
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button(action: {
            guard let user = configManager.currentUser else { return }
            Task {
                await viewModel.saveSettings(userId: user.id)
            }
        }) {
            if viewModel.isSaving {
                ProgressView()
                    .tint(.white)
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark")
                    Text("Save Changes")
                        .font(.system(size: 32, weight: .semibold))
                }
            }
        }
        .foregroundColor(.white)
        .frame(width: 600, height: 70)
        .background(Color.green)
        .cornerRadius(10)
        .disabled(viewModel.isSaving)
    }

    // MARK: - Logout Button

    private var logoutButton: some View {
        Button(action: { showLogoutConfirmation = true }) {
            if isLoggingOut {
                ProgressView()
                    .tint(.white)
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Logout")
                        .font(.system(size: 32, weight: .semibold))
                }
            }
        }
        .foregroundColor(.white)
        .frame(width: 600, height: 70)
        .background(Color.red)
        .cornerRadius(10)
        .disabled(isLoggingOut)
        .alert("Confirm Logout", isPresented: $showLogoutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                Task { await handleLogout() }
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        ProgressView("Loading settings...")
            .progressViewStyle(.circular)
            .tint(.white)
            .scaleEffect(1.2)
            .padding(.vertical, 40)
    }

    // MARK: - Message View

    private func messageView(message: String, isError: Bool) -> some View {
        Text(message)
            .font(.system(size: 20))
            .foregroundColor(.white)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isError ? Color.red.opacity(0.8) : Color.green.opacity(0.8))
            )
    }

    // MARK: - Picker Sheet

    private func pickerSheet(
        title: String,
        items: [(String, String)],
        selection: Binding<String>
    ) -> some View {
        NavigationStack {
            List {
                ForEach(items, id: \.0) { code, name in
                    Button(action: {
                        selection.wrappedValue = code
                    }) {
                        HStack {
                            Text(name)
                                .foregroundColor(.white)
                            Spacer()
                            if selection.wrappedValue == code {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.Seerr.primary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
        }
    }

    // MARK: - Actions

    private func loadServerStatus() async {
        isLoadingStatus = true
        do {
            serverStatus = try await SeerrService.shared.getStatus()
        } catch {
            print("❌ Failed to load server status: \(error)")
        }
        isLoadingStatus = false
    }

    private func handleLogout() async {
        isLoggingOut = true
        await configManager.logout()
        dismiss()
        isLoggingOut = false
    }

    private func handleRemoveServer() async {
        isRemovingServer = true
        await configManager.logout()
        await configManager.reset()
        dismiss()
        isRemovingServer = false
    }
}

#Preview {
    SettingsView()
        .environmentObject(ConfigManager())
}
