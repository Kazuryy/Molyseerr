//
//  MediaRequest.swift
//  Molyseerr
//
//  Created by Claude on 24/12/2025.
//

import Foundation

/// Media request entity
/// Source: seerr-api.yml MediaRequest schema
struct MediaRequest: Codable, Identifiable {
    let id: Int
    let status: RequestStatus
    let media: MediaInfo?
    let createdAt: String
    let updatedAt: String
    let requestedBy: User?
    let modifiedBy: User?
    let is4k: Bool
    let serverId: Int?
    let profileId: Int?
    let rootFolder: String?
}

/// Request body for creating a new media request
/// Source: seerr-api.yml & TVOS_ARCH_SPEC.md Section 3.2
struct MediaRequestBody: Codable {
    let mediaType: MediaType
    let mediaId: Int  // TMDB ID
    let seasons: [Int]?  // For TV shows only
    let is4k: Bool?
    let serverId: Int?
    let profileId: Int?
    let rootFolder: String?
}
