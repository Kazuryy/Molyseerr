//
//  User.swift
//  Molyseerr
//
//  Created by Claude on 24/12/2025.
//

import Foundation

/// User settings model
/// Source: seerr-api.yml UserSettings schema
struct UserSettings: Codable, Hashable {
    let locale: String?
    let region: String?
    let originalLanguage: String?
    let discoverRegion: String?
    let streamingRegion: String?
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
}
