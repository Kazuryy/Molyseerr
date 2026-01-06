//
//  SettingsView.swift
//  Molyseerr
//
//  Created by Claude on 31/12/2025.
//

import SwiftUI

/// Enhanced Settings view with user preferences
/// Follows Swiftfin tvOS design patterns
struct SettingsView: View {
    @EnvironmentObject var configManager: ConfigManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()
    @StateObject private var featureFlags = FeatureFlagsManager.shared

    @State private var isLoggingOut: Bool = false
    @State private var showLogoutConfirmation: Bool = false
    @State private var showRemoveServerConfirmation: Bool = false
    @State private var isRemovingServer: Bool = false
    @State private var serverStatus: ServerStatus?
    @State private var isLoadingStatus: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            // Left side - Settings Icon
            VStack(spacing: 30) {
                Image(systemName: "gearshape.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .foregroundColor(.Seerr.primary)

                Text("Settings")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                // Server status
                if let status = serverStatus {
                    VStack(spacing: 12) {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Color.Seerr.statusAvailable)
                                .frame(width: 12, height: 12)
                            Text("Server Online")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.Seerr.statusAvailable)
                        }
                        Text("v\(status.version)")
                            .font(.system(size: 18))
                            .foregroundColor(.Seerr.secondaryText)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 60)

            // Right side - Settings Form
            Form {
                if viewModel.isLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView("Loading settings...")
                                .progressViewStyle(.circular)
                                .tint(.Seerr.primary)
                                .scaleEffect(1.5)
                            Spacer()
                        }
                        .padding(.vertical, 60)
                    }
                } else {
                    settingsContent
                }
            }
            .padding(.top)
            .scrollClipDisabled()
        }
        .background(Color.Seerr.background)
        .navigationTitle("Settings")
        .task {
            await loadServerStatus()
            if let user = configManager.currentUser {
                await viewModel.loadSettings(userId: user.id)
            }
        }
    }

    @ViewBuilder
    private var settingsContent: some View {
        // TopShelf Settings Section
        Section {
            TopShelfNavigationRow()
        } header: {
            Text("TopShelf (Home Screen)")
        } footer: {
            Text("Configure what sliders appear on your tvOS home screen when Molyseerr is focused")
                .foregroundColor(.Seerr.secondaryText)
        }

        // Docker Features Section
        Section {
            FeatureFlagToggle(
                "Calendar & Today's Releases",
                description: "Show calendar slider with today's releases",
                isOn: $featureFlags.flags.calendarEnabled
            )

            FeatureFlagToggle(
                "Available Movies & Series",
                description: "Show sliders for media already in your library",
                isOn: $featureFlags.flags.availableMediaEnabled
            )

            FeatureFlagToggle(
                "Deletion Requests & Voting",
                description: "Enable voting system and deletion requests features",
                isOn: $featureFlags.flags.deletionRequestsEnabled
            )
        } header: {
            Text("Docker Features")
        } footer: {
            Text("These features require a custom Seerr Docker image. Disable them if your server doesn't support these endpoints.")
                .foregroundColor(.Seerr.secondaryText)
        }

        // Display Preferences Section
        Section {
            SettingsMenuRow(
                "Display Language",
                selection: $viewModel.locale,
                options: viewModel.availableLocales
            )

            SettingsMenuRow(
                "Discover Region",
                selection: $viewModel.discoverRegion,
                options: viewModel.availableRegions
            )

            SettingsMenuRow(
                "Streaming Region",
                selection: $viewModel.streamingRegion,
                options: viewModel.availableRegions
            )

            SettingsMenuRow(
                "Original Language",
                selection: $viewModel.originalLanguage,
                options: viewModel.availableLanguages
            )
        } header: {
            Text("Display Preferences")
        }

        // Notifications Section (Read-only)
        if viewModel.hasNotificationsConfigured {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(viewModel.notificationMethods, id: \.self) { method in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.Seerr.statusAvailable)
                                .font(.system(size: 24))
                            Text(method)
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Notifications")
            } footer: {
                Text("Configure notification settings on the web interface")
                    .foregroundColor(.Seerr.secondaryText)
            }
        }

        // About Section
        Section {
            if let status = serverStatus {
                aboutRow(title: "Server Version", value: status.version)
            }
            aboutRow(title: "App Version", value: "1.0.0")
            aboutRow(title: "Open Source", value: "MIT License")
        } header: {
            Text("About")
        }

        // Save Button (if there are unsaved changes)
        if viewModel.hasUnsavedChanges {
            Section {
                Button("Save Changes") {
                    guard let user = configManager.currentUser else { return }
                    Task {
                        await viewModel.saveSettings(userId: user.id)
                    }
                }
                .buttonStyle(.primary)
                .frame(maxHeight: 75)
                .disabled(viewModel.isSaving)
            }
        }

        // Server Management Section
        Section {
            VStack(alignment: .leading, spacing: 20) {
                Text("Current Server")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)

                Text(configManager.baseURL)
                    .font(.system(size: 18))
                    .foregroundColor(.Seerr.secondaryText)
                    .padding(.bottom, 8)

                Button("Remove Server & Logout") {
                    showRemoveServerConfirmation = true
                }
                .buttonStyle(.primary)
                .frame(maxHeight: 75)
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
            .padding(.vertical, 8)
        } header: {
            Text("Server")
        }

        // Logout Button
        Section {
            Button("Logout") {
                showLogoutConfirmation = true
            }
            .buttonStyle(.primary)
            .frame(maxHeight: 75)
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

        // Success/Error Messages
        if let successMessage = viewModel.successMessage {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.Seerr.statusAvailable)
                    Text(successMessage)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            }
            .listRowBackground(Color.Seerr.statusAvailable.opacity(0.2))
        }
        if let errorMessage = viewModel.errorMessage {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.Seerr.statusError)
                    Text(errorMessage)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            }
            .listRowBackground(Color.Seerr.statusError.opacity(0.2))
        }
    }

    // MARK: - About Row

    private func aboutRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 20))
                .foregroundColor(.white)
            Spacer()
            Text(value)
                .font(.system(size: 20))
                .foregroundColor(.Seerr.secondaryText)
        }
    }
}

// MARK: - Settings Components

/// Feature flag toggle row
struct FeatureFlagToggle: View {
    let title: String
    let description: String
    @Binding var isOn: Bool

    @FocusState private var isFocused: Bool

    init(_ title: String, description: String, isOn: Binding<Bool>) {
        self.title = title
        self.description = description
        self._isOn = isOn
    }

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(isFocused ? .black : .white)

                Text(description)
                    .font(.system(size: 18))
                    .foregroundColor(isFocused ? .black.opacity(0.7) : .Seerr.secondaryText)
            }
            .padding(.vertical, 8)
        }
        .toggleStyle(.switch)
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.125), value: isFocused)
    }
}

/// Navigation row for TopShelf settings
struct TopShelfNavigationRow: View {
    @State private var displayMode: TopShelfDisplayMode = TopShelfSettings.shared.displayMode

    var body: some View {
        NavigationLink {
            TopShelfConfigView()
        } label: {
            HStack {
                Text("TopShelf Sliders")

                Spacer()

                Text(displayMode.displayName)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            displayMode = TopShelfSettings.shared.displayMode
        }
    }
}

/// Menu row for settings with dropdown selection (Swiftfin style)
struct SettingsMenuRow: View {
    let title: String
    @Binding var selection: String
    let options: [(String, String)]

    @FocusState private var isFocused: Bool

    init(_ title: String, selection: Binding<String>, options: [(String, String)]) {
        self.title = title
        self._selection = selection
        self.options = options
    }

    var body: some View {
        Menu {
            Picker(title, selection: $selection) {
                ForEach(options, id: \.0) { code, name in
                    Text(name).tag(code)
                }
            }
        } label: {
            HStack {
                Text(title)
                    .foregroundStyle(isFocused ? .black : .white)
                    .padding(.leading, 4)

                Spacer()

                Text(selectedName)
                    .foregroundStyle(isFocused ? .black : .secondary)
                    .brightness(isFocused ? 0.4 : 0)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.body.weight(.regular))
                    .foregroundStyle(isFocused ? .black : .secondary)
                    .brightness(isFocused ? 0.4 : 0)
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isFocused ? Color.white : Color.clear)
            )
            .scaleEffect(isFocused ? 1.04 : 1.0)
            .animation(.easeInOut(duration: 0.125), value: isFocused)
        }
        .menuStyle(.borderlessButton)
        .listRowInsets(EdgeInsets())
        .focused($isFocused)
    }

    private var selectedName: String {
        options.first { $0.0 == selection }?.1 ?? selection
    }
}

/// TopShelf settings row (generic for both DisplayMode and ContentSource)
struct SettingsTopShelfRow<T: RawRepresentable & Hashable>: View where T.RawValue == String {
    let title: String
    @Binding var selection: T
    let options: [(String, String)]

    @FocusState private var isFocused: Bool

    init(_ title: String, selection: Binding<T>, options: [(String, String)]) {
        self.title = title
        self._selection = selection
        self.options = options
    }

    var body: some View {
        Menu {
            Picker(title, selection: Binding(
                get: { selection.rawValue },
                set: { newValue in
                    if let newSelection = T(rawValue: newValue) {
                        selection = newSelection
                    }
                }
            )) {
                ForEach(options, id: \.0) { code, name in
                    Text(name).tag(code)
                }
            }
        } label: {
            HStack {
                Text(title)
                    .foregroundStyle(isFocused ? .black : .white)
                    .padding(.leading, 4)

                Spacer()

                Text(selectedName)
                    .foregroundStyle(isFocused ? .black : .secondary)
                    .brightness(isFocused ? 0.4 : 0)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.body.weight(.regular))
                    .foregroundStyle(isFocused ? .black : .secondary)
                    .brightness(isFocused ? 0.4 : 0)
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isFocused ? Color.white : Color.clear)
            )
            .scaleEffect(isFocused ? 1.04 : 1.0)
            .animation(.easeInOut(duration: 0.125), value: isFocused)
        }
        .menuStyle(.borderlessButton)
        .listRowInsets(EdgeInsets())
        .focused($isFocused)
    }

    private var selectedName: String {
        options.first { $0.0 == selection.rawValue }?.1 ?? selection.rawValue
    }
}

// MARK: - SettingsView Actions Extension

extension SettingsView {
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
