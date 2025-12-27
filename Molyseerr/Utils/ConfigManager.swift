//
//  ConfigManager.swift
//  Molyseerr
//
//  Created by Claude on 25/12/2025.
//

import Foundation
import SwiftUI
import Combine

/// Manages app configuration including server URL and authentication state
/// Following Seerr's security model: session validated via /user/me, not stored booleans
/// URLSession automatically manages HTTP-only secure cookies (like web browsers)
final class ConfigManager: ObservableObject {

    // MARK: - UserDefaults Keys
    private enum Keys {
        static let baseURL = "seerr_base_url"
        // NOTE: Removed isAuthenticated key - we verify session instead
    }

    // MARK: - Published Properties
    @Published var baseURL: String = ""
    @Published var isConfigured: Bool = false
    @Published var isBackdropsReady: Bool = false  // Backdrops loaded and ready for display
    @Published var isAuthenticated: Bool = false  // Computed from session validation
    @Published var currentUser: User? = nil  // Current authenticated user
    @Published var backdrops: [String] = []  // TMDB backdrop images for login page

    // MARK: - Initialization
    init() {
        // Load persisted configuration
        loadFromUserDefaults()

        print("ℹ️ ConfigManager initialized")
        print("   📡 Server: \(baseURL.isEmpty ? "Not configured" : baseURL)")
        print("   🔐 Authenticated: \(isAuthenticated)")

        // Pre-load backdrops if server is already configured
        if isConfigured {
            Task {
                await loadBackdrops()
            }
        }
    }

    // MARK: - Persistence

    private func loadFromUserDefaults() {
        // Load server URL (only thing we persist)
        if let savedURL = UserDefaults.standard.string(forKey: Keys.baseURL), !savedURL.isEmpty {
            self.baseURL = savedURL
            self.isConfigured = true
            SeerrService.shared.setBaseURL(savedURL)
        }

        // Authentication state is NOT loaded from UserDefaults
        // It will be validated via validateSession() after initialization
    }

    private func saveToUserDefaults() {
        // Only save server URL - authentication is managed by session cookies
        UserDefaults.standard.set(baseURL, forKey: Keys.baseURL)
    }

    // MARK: - Configuration Methods

    /// Update configuration with server URL
    func configure(baseURL: String) {
        self.baseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isConfigured = !self.baseURL.isEmpty

        // Update the service
        SeerrService.shared.setBaseURL(self.baseURL)

        // Save to persistence
        saveToUserDefaults()

        print("✅ Server configured: \(self.baseURL)")
    }

    /// Validate current session by calling /user/me
    /// This is how Seerr web app checks authentication (same approach)
    /// URLSession automatically includes session cookies in the request
    func validateSession() async {
        guard isConfigured else {
            print("⚠️ Server not configured, skipping session validation")
            self.isAuthenticated = false
            self.currentUser = nil
            return
        }

        do {
            // Call /user/me to verify session (like Seerr web app does)
            let user = try await SeerrService.shared.getCurrentUser()

            // Session is valid - update state
            self.currentUser = user
            self.isAuthenticated = true

            print("✅ Session validated - User: \(user.displayName)")
        } catch {
            // Session is invalid or expired
            self.currentUser = nil
            self.isAuthenticated = false

            print("⚠️ Session validation failed: \(error)")
        }
    }

    /// Logout and clear session
    func logout() async {
        do {
            // Call server logout endpoint to destroy session
            try await SeerrService.shared.logout()
            print("✅ Logged out successfully")
        } catch {
            print("⚠️ Logout request failed: \(error)")
        }

        // Clear local state regardless of server response
        self.currentUser = nil
        self.isAuthenticated = false
    }

    /// Verify if current configuration is valid by testing API connection
    /// Uses the public /status endpoint which doesn't require authentication
    func verifyConfiguration() async -> Bool {
        guard isConfigured else { return false }

        do {
            // Try to get server status (public endpoint, no auth required)
            let status = try await SeerrService.shared.getStatus()
            print("✅ Server verified - Seerr version: \(status.version)")
            return true
        } catch {
            print("❌ Configuration verification failed: \(error)")
            return false
        }
    }

    /// Load TMDB backdrops for login page
    /// Called after server verification to pre-load images
    func loadBackdrops() async {
        guard isConfigured else {
            print("⚠️ Server not configured, skipping backdrop loading")
            self.isBackdropsReady = false
            return
        }

        // Mark as not ready while loading
        self.isBackdropsReady = false

        do {
            let fetchedBackdrops = try await SeerrService.shared.getBackdrops()
            self.backdrops = fetchedBackdrops
            print("✅ Loaded \(fetchedBackdrops.count) backdrops")

            // Mark as ready after successful load
            self.isBackdropsReady = true
        } catch {
            print("❌ Failed to load backdrops: \(error)")
            self.backdrops = []
            // Even on error, mark as ready to avoid blocking the UI
            self.isBackdropsReady = true
        }
    }

    /// Reset all configuration (full app reset)
    func reset() async {
        // Logout first if authenticated
        if isAuthenticated {
            await logout()
        }

        // Clear server configuration
        self.baseURL = ""
        self.isConfigured = false
        self.isBackdropsReady = false
        self.isAuthenticated = false
        self.currentUser = nil
        self.backdrops = []
        saveToUserDefaults()
        print("🔄 Configuration reset")
    }
}
