//
//  MediaStatus.swift
//  Molyseerr
//
//  Created by Claude on 24/12/2025.
//

import Foundation

/// Media availability status
/// Source: server/constants/media.ts & TVOS_ARCH_SPEC.md Section 2.1
enum MediaStatus: Int, Codable, Hashable {
    case unknown = 1
    case pending = 2
    case processing = 3
    case partiallyAvailable = 4
    case available = 5
    case blacklisted = 6
    case deleted = 7
}

/// Media type (Movie or TV Show)
enum MediaType: String, Codable {
    case movie = "movie"
    case tv = "tv"
}

/// Request status
/// Source: server/constants/media.ts MediaRequestStatus
enum RequestStatus: Int, Codable, Hashable {
    case pending = 1
    case approved = 2
    case declined = 3
    case failed = 4
    case completed = 5
}
