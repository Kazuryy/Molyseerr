//
//  FeatureFlags.swift
//  Molyseerr
//
//  Created by Claude on 06/01/2026.
//

import Foundation
import SwiftUI
import Combine

/// Feature flags for Docker-specific features
/// These features are only available when using a custom Seerr Docker image
struct FeatureFlags: Codable {
    /// Enable calendar/today's releases slider
    var calendarEnabled: Bool

    /// Enable available movies/series sliders
    var availableMediaEnabled: Bool

    /// Enable deletion requests and voting system
    var deletionRequestsEnabled: Bool

    /// Default configuration (all features disabled by default)
    static let `default` = FeatureFlags(
        calendarEnabled: false,
        availableMediaEnabled: false,
        deletionRequestsEnabled: false
    )

    /// Check if all custom features are disabled
    var allDisabled: Bool {
        !calendarEnabled && !availableMediaEnabled && !deletionRequestsEnabled
    }

    /// Check if any custom feature is enabled
    var anyEnabled: Bool {
        calendarEnabled || availableMediaEnabled || deletionRequestsEnabled
    }
}

/// Manager for Docker-specific feature flags
/// Persists settings in UserDefaults
@MainActor
final class FeatureFlagsManager: ObservableObject {

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let featureFlags = "docker_feature_flags"
    }

    // MARK: - Published Properties

    @Published var flags: FeatureFlags {
        didSet {
            save()
        }
    }

    // MARK: - Singleton

    static let shared = FeatureFlagsManager()

    // MARK: - Initialization

    private init() {
        self.flags = Self.load()
    }

    // MARK: - Persistence

    private static func load() -> FeatureFlags {
        guard let data = UserDefaults.standard.data(forKey: Keys.featureFlags),
              let flags = try? JSONDecoder().decode(FeatureFlags.self, from: data) else {
            return .default
        }
        return flags
    }

    private func save() {
        if let data = try? JSONEncoder().encode(flags) {
            UserDefaults.standard.set(data, forKey: Keys.featureFlags)
        }
    }

    // MARK: - Convenience Accessors

    var calendarEnabled: Bool {
        flags.calendarEnabled
    }

    var availableMediaEnabled: Bool {
        flags.availableMediaEnabled
    }

    var deletionRequestsEnabled: Bool {
        flags.deletionRequestsEnabled
    }

    // MARK: - Update Methods

    func setCalendar(enabled: Bool) {
        flags.calendarEnabled = enabled
    }

    func setAvailableMedia(enabled: Bool) {
        flags.availableMediaEnabled = enabled
    }

    func setDeletionRequests(enabled: Bool) {
        flags.deletionRequestsEnabled = enabled
    }

    func resetToDefaults() {
        flags = .default
    }

    func enableAll() {
        flags = FeatureFlags(
            calendarEnabled: true,
            availableMediaEnabled: true,
            deletionRequestsEnabled: true
        )
    }
}
