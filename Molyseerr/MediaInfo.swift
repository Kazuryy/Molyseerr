//
//  MediaInfo.swift
//  Molyseerr
//
//  Created by Assistant on 27/12/2025.
//

import Foundation

/// Media info contains availability status and request information
/// Source: seerr-api.yml MediaInfo schema
struct MediaInfo: Codable {
    let tmdbId: Int?
    let tvdbId: Int?
    let status: MediaStatus?
    let requests: [MediaRequest]?
    
    // Additional fields from API
    let createdAt: String?
    let updatedAt: String?
    let mediaType: String?
}

/// Media request information
struct MediaRequest: Codable, Identifiable {
    let id: Int
    let status: Int
    let createdAt: String
    let updatedAt: String
    let type: String
    let is4k: Bool?
    let serverId: Int?
    let profileId: Int?
    let rootFolder: String?
    
    /// Computed property for request status
    var requestStatus: MediaStatus {
        switch status {
        case 1:
            return .pending
        case 2:
            return .approved
        case 3:
            return .declined
        default:
            return .unknown
        }
    }
}

// Request status extension
extension MediaStatus {
    static let approved = MediaStatus.available
    static let declined = MediaStatus.unknown
}
