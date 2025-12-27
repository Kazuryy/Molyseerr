//
//  User.swift
//  Molyseerr
//
//  Created by Claude on 24/12/2025.
//

import Foundation

/// User model
/// Source: seerr-api.yml User schema
struct User: Codable, Identifiable {
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

    /// Display name computed property - uses username, jellyfinUsername, or email as fallback
    var displayName: String {
        username ?? jellyfinUsername ?? email ?? "User \(id)"
    }
}
