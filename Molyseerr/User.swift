//
//  User.swift
//  Molyseerr
//
//  Created by Assistant on 27/12/2025.
//

import Foundation

/// User model from Seerr API
/// Source: seerr-api.yml User schema
struct User: Codable, Identifiable {
    let id: Int
    let email: String
    let username: String?
    let plexToken: String?
    let plexUsername: String?
    let userType: Int
    let permissions: Int?
    let avatar: String?
    let movieQuotaLimit: Int?
    let movieQuotaDays: Int?
    let tvQuotaLimit: Int?
    let tvQuotaDays: Int?
    let createdAt: String?
    let updatedAt: String?
    let requestCount: Int?
    
    /// Display name (username or email)
    var displayName: String {
        username ?? plexUsername ?? email
    }
    
    /// Check if user is admin
    var isAdmin: Bool {
        return userType == 1 || (permissions ?? 0) & 2 != 0
    }
}

/// Login request body
struct LoginRequest: Codable {
    let email: String
    let password: String
}

/// Login response
struct LoginResponse: Codable {
    let email: String
    let id: Int
    let plexUsername: String?
}

/// Server status response
struct ServerStatus: Codable {
    let version: String
    let commitTag: String?
    let updateAvailable: Bool?
    let commitsBehind: Int?
}
