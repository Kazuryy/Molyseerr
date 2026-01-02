//
//  User.swift
//  Molyseerr
//
//  Created by Claude on 24/12/2025.
//

import Foundation

/// User settings model
/// Source: seerr-api.yml UserSettings schema & Seerr webapp entity/UserSettings.ts
struct UserSettings: Codable, Hashable {
    // Display preferences
    let locale: String?
    let region: String?
    let originalLanguage: String?
    let discoverRegion: String?
    let streamingRegion: String?

    // Auto-request settings
    let watchlistSyncMovies: Bool?
    let watchlistSyncTv: Bool?

    // Notification settings (read-only on tvOS)
    let pgpKey: String?
    let discordId: String?
    let pushbulletAccessToken: String?
    let pushoverApplicationToken: String?
    let pushoverUserKey: String?
    let pushoverSound: String?
    let telegramChatId: String?
    let telegramSendSilently: Bool?

    // Request quotas (read-only on tvOS, admin-managed)
    let movieQuotaLimit: Int?
    let movieQuotaDays: Int?
    let tvQuotaLimit: Int?
    let tvQuotaDays: Int?
}

/// User settings update request
/// Only includes fields that can be updated on tvOS
struct UserSettingsUpdate: Codable {
    var locale: String?
    var discoverRegion: String?
    var streamingRegion: String?
    var originalLanguage: String?
    var watchlistSyncMovies: Bool?
    var watchlistSyncTv: Bool?
}

/// User model
/// Source: seerr-api.yml User schema
struct User: Codable, Identifiable, Hashable {
    let id: Int
    let email: String?  // Optional - not always present (e.g., Jellyfin users)
    let username: String?
    let jellyfinUsername: String?
    let userType: Int
    let permissions: Int
    let avatar: String?
    let createdAt: String
    let updatedAt: String
    let requestCount: Int?
    let settings: UserSettings?

    /// Display name computed property - uses username, jellyfinUsername, or email as fallback
    var displayName: String {
        username ?? jellyfinUsername ?? email ?? "User \(id)"
    }

    /// Get user's preferred locale, defaults to "en"
    var preferredLocale: String {
        settings?.locale ?? "en"
    }

    /// Formatted join date
    var joinDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: createdAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .long
            return displayFormatter.string(from: date)
        }
        return createdAt
    }
}

/// Quota status for movie or TV requests
/// Source: Seerr webapp QuotaStatus interface
struct QuotaStatus: Codable, Hashable {
    let days: Int?
    let limit: Int?
    let used: Int
    let remaining: Int?
    let restricted: Bool

    var isUnlimited: Bool {
        limit == nil || limit == 0
    }

    var quotaText: String {
        if isUnlimited {
            return "Unlimited"
        }
        guard let limit = limit, let remaining = remaining else {
            return "N/A"
        }
        return "\(remaining) of \(limit)"
    }
}

/// User quota response
/// Source: Seerr API /user/:id/quota endpoint
struct UserQuotaResponse: Codable, Hashable {
    let movie: QuotaStatus
    let tv: QuotaStatus
}
