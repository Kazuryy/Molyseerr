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
    let email: String
    let username: String?
    let plexUsername: String?
    let userType: Int
    let permissions: Int
    let avatar: String?
    let createdAt: String
    let updatedAt: String
    let requestCount: Int?
}
