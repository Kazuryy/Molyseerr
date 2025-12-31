//
//  SettingsViewModel.swift
//  Molyseerr
//
//  Created by Claude on 31/12/2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var userSettings: UserSettings?
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    // Editable settings (local state before saving)
    @Published var locale: String = "en"
    @Published var discoverRegion: String = ""
    @Published var streamingRegion: String = ""
    @Published var originalLanguage: String = ""
    @Published var autoRequestMovies: Bool = false
    @Published var autoRequestTV: Bool = false

    // Read-only info
    @Published var hasNotificationsConfigured: Bool = false
    @Published var notificationMethods: [String] = []

    // MARK: - Constants

    // Available locales (from Seerr)
    let availableLocales = [
        ("en", "English"),
        ("fr", "Français"),
        ("de", "Deutsch"),
        ("es", "Español"),
        ("it", "Italiano"),
        ("ja", "日本語"),
        ("ko", "한국어"),
        ("pt", "Português"),
        ("ru", "Русский"),
        ("zh", "中文")
    ]

    // Available regions (ISO 3166-1 alpha-2)
    let availableRegions = [
        ("", "Auto"),
        ("US", "United States"),
        ("GB", "United Kingdom"),
        ("CA", "Canada"),
        ("FR", "France"),
        ("DE", "Germany"),
        ("ES", "Spain"),
        ("IT", "Italy"),
        ("JP", "Japan"),
        ("KR", "South Korea"),
        ("BR", "Brazil"),
        ("AU", "Australia")
    ]

    // Available languages (ISO 639-1)
    let availableLanguages = [
        ("", "All Languages"),
        ("en", "English"),
        ("fr", "French"),
        ("de", "German"),
        ("es", "Spanish"),
        ("it", "Italian"),
        ("ja", "Japanese"),
        ("ko", "Korean"),
        ("pt", "Portuguese"),
        ("ru", "Russian"),
        ("zh", "Chinese")
    ]

    // MARK: - Initialization

    init() {
        // Initialization will load settings in loadSettings()
    }

    // MARK: - Load Settings

    func loadSettings(userId: Int) async {
        isLoading = true
        errorMessage = nil

        do {
            let settings = try await SeerrService.shared.getUserSettings(userId: userId)
            userSettings = settings

            // Update local editable state
            locale = settings.locale ?? "en"
            discoverRegion = settings.discoverRegion ?? ""
            streamingRegion = settings.streamingRegion ?? ""
            originalLanguage = settings.originalLanguage ?? ""
            autoRequestMovies = settings.watchlistSyncMovies ?? false
            autoRequestTV = settings.watchlistSyncTv ?? false

            // Check notification configuration
            checkNotificationConfiguration(settings)

            isLoading = false
        } catch {
            errorMessage = "Failed to load settings: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Save Settings

    func saveSettings(userId: Int) async -> Bool {
        isSaving = true
        errorMessage = nil
        successMessage = nil

        do {
            let update = UserSettingsUpdate(
                locale: locale,
                discoverRegion: discoverRegion.isEmpty ? nil : discoverRegion,
                streamingRegion: streamingRegion.isEmpty ? nil : streamingRegion,
                originalLanguage: originalLanguage.isEmpty ? nil : originalLanguage,
                watchlistSyncMovies: autoRequestMovies,
                watchlistSyncTv: autoRequestTV
            )

            let updatedSettings = try await SeerrService.shared.updateUserSettings(
                userId: userId,
                settings: update
            )

            userSettings = updatedSettings
            successMessage = "Settings saved successfully"
            isSaving = false

            // Clear success message after 3 seconds
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                successMessage = nil
            }

            return true
        } catch {
            errorMessage = "Failed to save settings: \(error.localizedDescription)"
            isSaving = false
            return false
        }
    }

    // MARK: - Reset to Defaults

    func resetToDefaults() {
        locale = "en"
        discoverRegion = ""
        streamingRegion = ""
        originalLanguage = ""
        autoRequestMovies = false
        autoRequestTV = false
    }

    // MARK: - Helper Methods

    private func checkNotificationConfiguration(_ settings: UserSettings) {
        var methods: [String] = []

        if settings.discordId != nil && !(settings.discordId?.isEmpty ?? true) {
            methods.append("Discord")
        }
        if settings.pushbulletAccessToken != nil && !(settings.pushbulletAccessToken?.isEmpty ?? true) {
            methods.append("Pushbullet")
        }
        if settings.pushoverUserKey != nil && !(settings.pushoverUserKey?.isEmpty ?? true) {
            methods.append("Pushover")
        }
        if settings.telegramChatId != nil && !(settings.telegramChatId?.isEmpty ?? true) {
            methods.append("Telegram")
        }

        notificationMethods = methods
        hasNotificationsConfigured = !methods.isEmpty
    }

    // MARK: - Localized Display Names

    func localeName(for code: String) -> String {
        availableLocales.first { $0.0 == code }?.1 ?? code
    }

    func regionName(for code: String) -> String {
        if code.isEmpty {
            return "Auto"
        }
        return availableRegions.first { $0.0 == code }?.1 ?? code
    }

    func languageName(for code: String) -> String {
        if code.isEmpty {
            return "All Languages"
        }
        return availableLanguages.first { $0.0 == code }?.1 ?? code
    }

    // MARK: - Validation

    var hasUnsavedChanges: Bool {
        guard let settings = userSettings else { return false }

        return locale != (settings.locale ?? "en") ||
               discoverRegion != (settings.discoverRegion ?? "") ||
               streamingRegion != (settings.streamingRegion ?? "") ||
               originalLanguage != (settings.originalLanguage ?? "") ||
               autoRequestMovies != (settings.watchlistSyncMovies ?? false) ||
               autoRequestTV != (settings.watchlistSyncTv ?? false)
    }
}
